import 'package:flutter/material.dart';

import '../../home/presentation/home_page.dart';
import '../../incidents/presentation/incidents_page.dart';
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

  void _showReport() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1A2025),
    builder: (_) => const ReportSheet(),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: IndexedStack(
        index: _tab,
        children: [
          HomePage(onReport: _showReport),
          const IncidentsPage(),
          const ReportsPage(),
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
