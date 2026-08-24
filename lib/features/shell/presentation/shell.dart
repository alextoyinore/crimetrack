import 'dart:async';

import 'package:flutter/material.dart';

import '../../home/presentation/home_page.dart';
import '../../incidents/presentation/incidents_page.dart';
import '../../incidents/models/incident.dart';
import '../../incidents/data/incident_repository.dart';
import '../../reports/presentation/reports_page.dart';
import '../../safety/presentation/safety_page.dart';
import '../../report/presentation/report_sheet.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;
  final _repository = IncidentRepository();
  final List<Incident> _userIncidents = [];
  final List<Incident> _incidents = [
    Incident(
      type: 'Theft',
      description: 'Reported theft incident.',
      location: 'Allen Avenue, Ikeja',
      reportedAt: DateTime.now().subtract(const Duration(minutes: 12)),
      status: IncidentStatus.verified,
      risk: IncidentRisk.medium,
      latitude: 6.6194,
      longitude: 3.3488,
    ),
    Incident(
      type: 'Robbery',
      description: 'Reported robbery incident.',
      location: 'Ojuelegba, Surulere',
      reportedAt: DateTime.now().subtract(const Duration(minutes: 38)),
      status: IncidentStatus.verified,
      risk: IncidentRisk.high,
      latitude: 6.5158,
      longitude: 3.3447,
    ),
    Incident(
      type: 'Suspicious activity',
      description: 'Reported suspicious activity.',
      location: 'Yaba, Lagos',
      reportedAt: DateTime.now().subtract(const Duration(hours: 1)),
      status: IncidentStatus.pending,
      risk: IncidentRisk.medium,
      latitude: 6.5244,
      longitude: 3.3792,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _restoreUserIncidents();
  }

  Future<void> _restoreUserIncidents() async {
    final saved = await _repository.loadUserIncidents();
    if (!mounted) return;
    setState(() {
      _userIncidents
        ..clear()
        ..addAll(saved);
      _incidents.insertAll(0, saved);
    });
  }

  Future<void> _addIncident(Incident incident) async {
    setState(() {
      _userIncidents.insert(0, incident);
      _incidents.insert(0, incident);
    });
    await _repository.saveUserIncidents(_userIncidents);
    final synced = await _repository.submitIncident(incident);
    if (!synced && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report saved locally; server sync failed'),
        ),
      );
    }
  }

  void _showReport() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1A2025),
    builder: (_) => ReportSheet(onSubmit: _addIncident),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: IndexedStack(
        index: _tab,
        children: [
          HomePage(onReport: _showReport, incidents: _incidents),
          IncidentsPage(incidents: _incidents),
          ReportsPage(incidents: _incidents),
          const SafetyPage(),
        ],
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (value) => setState(() => _tab = value),
      backgroundColor: const Color(0xFF171C20),
      indicatorColor: const Color(0xFF3A3426),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.grid_view_rounded),
          label: 'Overview',
        ),
        NavigationDestination(
          icon: Icon(Icons.map_outlined),
          label: 'Incidents',
        ),
        NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          label: 'My reports',
        ),
        NavigationDestination(
          icon: Icon(Icons.shield_outlined),
          label: 'Safety',
        ),
      ],
    ),
  );
}
