import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/incident.dart';

class IncidentRepository {
  static const _storageKey = 'crimetrack.user_incidents';

  Future<List<Incident>> loadUserIncidents() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getStringList(_storageKey) ?? const [];
    return stored.map((value) => Incident.fromJson(jsonDecode(value))).toList();
  }

  Future<void> saveUserIncidents(List<Incident> incidents) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _storageKey,
      incidents.map((incident) => jsonEncode(incident.toJson())).toList(),
    );
  }
}
