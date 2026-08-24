import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/page_title.dart';
import '../../incidents/models/incident.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key, required this.incidents});
  final List<Incident> incidents;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle(
          title: 'My reports',
          subtitle: 'Track the incidents you have submitted',
        ),
        const SizedBox(height: 26),
        ...incidents.map(
          (incident) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ReportRow(
              title: '${incident.type} reported',
              place: incident.location,
              status: incident.statusLabel,
              color: incident.riskColor,
            ),
          ),
        ),
      ],
    ),
  );
}

class ReportRow extends StatelessWidget {
  const ReportRow({
    super.key,
    required this.title,
    required this.place,
    required this.status,
    required this.color,
  });
  final String title, place, status;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Row(
      children: [
        const Icon(Icons.description_outlined, color: Color(0xFF879198)),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text(
                place,
                style: const TextStyle(fontSize: 12, color: AppTheme.muted),
              ),
            ],
          ),
        ),
        Text(
          status,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
