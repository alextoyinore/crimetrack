import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/incident.dart';

class IncidentRepository {
  static const _storageKey = 'crimetrack.user_incidents';

  IncidentRepository({String? baseUrl, http.Client? client, String? adminToken})
    : baseUrl = baseUrl ?? _defaultBaseUrl,
      _client = client ?? http.Client(),
      adminToken =
          adminToken ?? const String.fromEnvironment('CRIMETRACK_ADMIN_TOKEN');

  static String get _defaultBaseUrl {
    if (kIsWeb) return 'http://127.0.0.1:5000';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:5000'
        : 'http://127.0.0.1:5000';
  }

  final String baseUrl;
  final http.Client _client;
  String adminToken;

  Future<bool> loginAdmin(String username, String password) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/api/admin/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 3));
      if (response.statusCode != 200) return false;
      final token =
          (jsonDecode(response.body) as Map<String, dynamic>)['token'];
      if (token is! String || token.isEmpty) return false;
      adminToken = token;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Incident>> loadUserIncidents() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getStringList(_storageKey) ?? const [];
    final local = stored
        .map((value) => Incident.fromJson(jsonDecode(value)))
        .toList();

    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/incidents'))
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

  Future<void> saveUserIncidents(List<Incident> incidents) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _storageKey,
      incidents.map((incident) => jsonEncode(incident.toJson())).toList(),
    );
  }

  Future<bool> submitIncident(Incident incident) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/api/incidents'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(incident.toJson()),
          )
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> moderateIncident(
    Incident incident, {
    required IncidentStatus status,
    required IncidentRisk risk,
  }) async {
    if (incident.id == null || adminToken.isEmpty) return false;
    try {
      final response = await _client
          .patch(
            Uri.parse('$baseUrl/api/admin/incidents/${incident.id}'),
            headers: {
              'Authorization': 'Bearer $adminToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'status': status.name, 'risk': risk.name}),
          )
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
