import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/incident.dart';
import '../../notifications/models/notification.dart';

class IncidentRepository {
  static const _storageKey = 'crimetrack.user_incidents';
  static const _deviceIdKey = 'crimetrack.device_id';

  IncidentRepository({String? baseUrl, http.Client? client})
    : baseUrl = baseUrl ?? _defaultBaseUrl,
      _client = client ?? http.Client();

  static String get _defaultBaseUrl {
    const configuredUrl = String.fromEnvironment('CRIMETRACK_API_BASE_URL');
    if (configuredUrl.isNotEmpty) return configuredUrl;
    if (kIsWeb) return 'http://127.0.0.1:5000';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:5000'
        : 'http://127.0.0.1:5000';
  }

  final String baseUrl;
  final http.Client _client;

  Future<String> _deviceId() async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = base64Url.encode(
      List<int>.generate(24, (_) => Random.secure().nextInt(256)),
    );
    await preferences.setString(_deviceIdKey, generated);
    return generated;
  }

  Future<List<Incident>> loadUserIncidents() async {
    final deviceId = await _deviceId();
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getStringList(_storageKey) ?? const [];
    final local = stored
        .map((value) => Incident.fromJson(jsonDecode(value)))
        .toList();

    try {
      final response = await _client
          .get(
            Uri.parse(
              '$baseUrl/api/incidents?deviceId=${Uri.encodeQueryComponent(deviceId)}',
            ),
          )
          .timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body) as List<dynamic>;
        final remote = payload
            .map((value) => Incident.fromJson(value as Map<String, dynamic>))
            .toList();
        if (remote.isNotEmpty) return remote;
      }
    } catch (_) {
      // The local cache keeps the app usable when the API is offline.
    }
    return local;
  }

  Future<List<Incident>> loadIncidents() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/incidents'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode != 200) return const [];
      final payload = jsonDecode(response.body) as List<dynamic>;
      return payload
          .map((value) => Incident.fromJson(value as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveUserIncidents(List<Incident> incidents) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _storageKey,
      incidents.map((incident) => jsonEncode(incident.toJson())).toList(),
    );
  }

  Future<bool> submitIncident(Incident incident) async {
    try {
      final deviceId = await _deviceId();
      final payload = incident.toJson()..['deviceId'] = deviceId;
      final response = await _client
          .post(
            Uri.parse('$baseUrl/api/incidents'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<List<AppNotification>> loadNotifications() async {
    try {
      final deviceId = await _deviceId();
      final response = await _client
          .get(
            Uri.parse(
              '$baseUrl/api/notifications?deviceId=${Uri.encodeQueryComponent(deviceId)}',
            ),
          )
          .timeout(const Duration(seconds: 3));
      if (response.statusCode != 200) return const [];
      final payload = jsonDecode(response.body) as List<dynamic>;
      return payload
          .map(
            (value) => AppNotification.fromJson(value as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> markNotificationsRead() async {
    try {
      final deviceId = await _deviceId();
      await _client.post(
        Uri.parse('$baseUrl/api/notifications/read'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'deviceId': deviceId}),
      );
    } catch (_) {}
  }
}
