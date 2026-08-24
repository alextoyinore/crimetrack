import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../home/presentation/home_page.dart';
import '../../incidents/presentation/incidents_page.dart';
import '../../incidents/models/incident.dart';
import '../../incidents/data/incident_repository.dart';
import '../../reports/presentation/reports_page.dart';
import '../../safety/presentation/safety_page.dart';
import '../../report/presentation/report_sheet.dart';
import '../../notifications/models/notification.dart';

class Shell extends StatefulWidget {
  const Shell({
    super.key,
    required this.onThemeModeChanged,
    required this.themeMode,
  });

  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ThemeMode themeMode;
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;
  final _repository = IncidentRepository();
  final List<Incident> _userIncidents = [];
  final List<AppNotification> _notifications = [];
  Timer? _notificationTimer;
  final List<Incident> _incidents = [];

  @override
  void initState() {
    super.initState();
    _restoreUserIncidents();
    _restoreIncidents();
    _restoreNotifications();
    _notificationTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _restoreNotifications(),
    );
  }

  Future<void> _restoreIncidents() async {
    final incidents = await _repository.loadIncidents();
    if (!mounted) return;
    setState(() {
      _incidents
        ..clear()
        ..addAll(incidents);
    });
  }

  Future<void> _restoreNotifications() async {
    final saved = await _repository.loadNotifications();
    if (!mounted) return;
    setState(() {
      _notifications
        ..clear()
        ..addAll(saved);
    });
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
    if (synced) await _restoreNotifications();
    if (!synced && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report saved locally; server sync failed'),
        ),
      );
    }
  }

  Future<void> _showNotifications() async {
    await _restoreNotifications();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: 420,
          child: _notifications.isEmpty
              ? const Center(child: Text('No notifications yet'))
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _notifications.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return ListTile(
                      leading: Icon(
                        notification.read
                            ? Icons.notifications_none
                            : Icons.notifications_active,
                        color: notification.read ? Colors.grey : AppTheme.amber,
                      ),
                      title: Text(notification.title),
                      subtitle: Text(notification.message),
                    );
                  },
                ),
        ),
      ),
    );
    await _repository.markNotificationsRead();
    if (!mounted) return;
    final readNotifications = _notifications
        .map(
          (item) => AppNotification(
            id: item.id,
            title: item.title,
            message: item.message,
            createdAt: item.createdAt,
            read: true,
            incidentId: item.incidentId,
          ),
        )
        .toList();
    setState(() {
      _notifications
        ..clear()
        ..addAll(readNotifications);
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  void _showReport() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => ReportSheet(onSubmit: _addIncident),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: IndexedStack(
        index: _tab,
        children: [
          HomePage(
            onReport: _showReport,
            incidents: _incidents,
            onNotifications: _showNotifications,
            unreadNotifications: _notifications
                .where((item) => !item.read)
                .length,
            onThemeModeChanged: widget.onThemeModeChanged,
            themeMode: widget.themeMode,
          ),
          IncidentsPage(incidents: _incidents),
          ReportsPage(incidents: _incidents),
          const SafetyPage(),
        ],
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (value) => setState(() => _tab = value),
      backgroundColor: Theme.of(context).colorScheme.surface,
      indicatorColor: Theme.of(context).colorScheme.secondaryContainer,
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
