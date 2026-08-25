import 'package:flutter/material.dart';

import '../../../core/widgets/page_title.dart';
import '../../incidents/models/incident.dart';
import '../../incidents/presentation/incident_detail_page.dart';

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
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => IncidentDetailPage(incident: incident),
                ),
              ),
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
    required this.onTap,
  });
  final String title, place, status;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(11),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Icon(
            Icons.description_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Text(
                  place,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
    ),
  );
}
