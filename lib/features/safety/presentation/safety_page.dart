import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/page_title.dart';

class SafetyPage extends StatelessWidget {
  const SafetyPage({super.key});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle(
          title: 'Safety hub',
          subtitle: 'Quick access when it matters',
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 76,
          child: FilledButton.icon(
            onPressed: () => _callEmergency(context),
            icon: const Icon(Icons.phone_in_talk_rounded),
            label: const Text(
              'EMERGENCY SERVICES  112',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: .8),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'EMERGENCY CONTACTS',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        const ContactRow(
          name: 'Lagos State Emergency',
          number: '112',
          icon: Icons.local_police_outlined,
        ),
        const SizedBox(height: 10),
        const ContactRow(
          name: 'Nearest Police Station',
          number: 'Call',
          icon: Icons.shield_outlined,
        ),
      ],
    ),
  );

  Future<void> _callEmergency(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: '112');
    if (await launchUrl(uri)) return;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open the phone dialer')),
    );
  }
}

class ContactRow extends StatelessWidget {
  const ContactRow({
    super.key,
    required this.name,
    required this.number,
    required this.icon,
  });
  final String name, number;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppTheme.amber),
        const SizedBox(width: 13),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          number,
          style: const TextStyle(
            color: AppTheme.amber,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}
