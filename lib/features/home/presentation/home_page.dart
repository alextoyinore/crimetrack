import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/map_preview.dart';
import '../../../core/widgets/metric.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onReport});
  final VoidCallback onReport;

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
            const Column(
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
                  'LAGOS METRO',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF879198),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Stack(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                Positioned(
                  right: 10,
                  top: 9,
                  child: Container(
                    width: 7,
                    height: 7,
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
        const Text(
          'Your community watch, in real time.',
          style: TextStyle(color: AppTheme.muted, fontSize: 14),
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
        const MapPreview(),
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
        const Row(
          children: [
            Metric(value: '24', label: 'Verified', color: AppTheme.danger),
            SizedBox(width: 10),
            Metric(value: '08', label: 'Pending', color: AppTheme.amber),
            SizedBox(width: 10),
            Metric(value: '03', label: 'Resolved', color: AppTheme.success),
          ],
        ),
      ],
    ),
  );
}
