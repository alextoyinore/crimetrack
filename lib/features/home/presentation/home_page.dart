import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/map_preview.dart';
import '../../../core/widgets/metric.dart';
import '../../incidents/models/incident.dart';
import '../../help/presentation/help_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.onReport,
    required this.incidents,
    required this.onNotifications,
    required this.unreadNotifications,
    required this.onThemeModeChanged,
    required this.themeMode,
  });
  final VoidCallback onReport;
  final VoidCallback onNotifications;
  final int unreadNotifications;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ThemeMode themeMode;

  void _showThemePreferences(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...ThemeMode.values.map(
              (mode) => ListTile(
                title: Text(
                  mode.name[0].toUpperCase() + mode.name.substring(1),
                ),
                trailing: mode == themeMode
                    ? const Icon(Icons.check, color: AppTheme.amber)
                    : null,
                onTap: () {
                  onThemeModeChanged(mode);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help and safety information'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  final List<Incident> incidents;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.amber,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.radar, color: AppTheme.navigation),
            ),
            const SizedBox(width: 11),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CRIMETRACK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'NIGERIA',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _showThemePreferences(context),
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Theme preferences',
            ),
            Stack(
              children: [
                IconButton(
                  onPressed: onNotifications,
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                if (unreadNotifications > 0)
                  Positioned(
                    right: 10,
                    top: 9,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          'Stay aware.',
          style: TextStyle(
            fontSize: 31,
            fontWeight: FontWeight.w700,
            height: 1.05,
          ),
        ),
        const Text(
          'Stay safe.',
          style: TextStyle(
            fontSize: 31,
            fontWeight: FontWeight.w700,
            color: AppTheme.amber,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Your community watch, in real time.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 58,
          child: FilledButton.icon(
            onPressed: onReport,
            icon: const Icon(Icons.add_alert_rounded),
            label: const Text(
              'REPORT AN INCIDENT',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.1),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.amber,
              foregroundColor: AppTheme.navigation,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'LIVE INCIDENT MAP',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 1.3,
              ),
            ),
            Text(
              'Updated 2 min ago',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 12),
        MapPreview(incidents: incidents),
        const SizedBox(height: 24),
        const Text(
          'TODAY IN YOUR AREA',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Metric(
              value:
                  '${incidents.where((item) => item.status == IncidentStatus.verified).length}',
              label: 'Verified',
              color: AppTheme.danger,
            ),
            const SizedBox(width: 10),
            Metric(
              value:
                  '${incidents.where((item) => item.status == IncidentStatus.pending).length}',
              label: 'Pending',
              color: AppTheme.amber,
            ),
            const SizedBox(width: 10),
            Metric(
              value:
                  '${incidents.where((item) => item.status == IncidentStatus.resolved).length}',
              label: 'Resolved',
              color: AppTheme.success,
            ),
            const SizedBox(width: 10),
            Metric(
              value:
                  '${incidents.where((item) => item.status == IncidentStatus.rejected).length}',
              label: 'Rejected',
              color: AppTheme.danger,
            ),
          ],
        ),
      ],
    ),
  );
}
