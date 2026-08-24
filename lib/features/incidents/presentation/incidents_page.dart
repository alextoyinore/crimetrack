import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/map_preview.dart';
import '../../../core/widgets/page_title.dart';

class IncidentsPage extends StatelessWidget {
  const IncidentsPage({super.key});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle(
          title: 'Incident map',
          subtitle: 'Verified reports across Lagos Metro',
        ),
        const SizedBox(height: 22),
        const MapPreview(),
        const SizedBox(height: 24),
        const IncidentItem(
          type: 'Theft',
          location: 'Allen Avenue, Ikeja',
          time: '12 min ago',
          color: AppTheme.amber,
        ),
        const SizedBox(height: 10),
        const IncidentItem(
          type: 'Robbery',
          location: 'Ojuelegba, Surulere',
          time: '38 min ago',
          color: AppTheme.danger,
        ),
        const SizedBox(height: 10),
        const IncidentItem(
          type: 'Suspicious activity',
          location: 'Yaba, Lagos',
          time: '1 hr ago',
          color: AppTheme.amber,
        ),
      ],
    ),
  );
}

class IncidentItem extends StatelessWidget {
  const IncidentItem({
    super.key,
    required this.type,
    required this.location,
    required this.time,
    required this.color,
  });
  final String type, location, time;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(type, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                location,
                style: const TextStyle(color: AppTheme.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: const TextStyle(color: Color(0xFF7E898F), fontSize: 11),
        ),
      ],
    ),
  );
}
