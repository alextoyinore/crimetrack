import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Help and safety')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        _HelpSection(
          title: 'Reporting an incident',
          body:
              'Choose the incident type, describe what happened, and add the location. You can attach evidence and use GPS when it is available.',
        ),
        _HelpSection(
          title: 'Report status',
          body:
              'Reports start as pending. You will receive an in-app notification when an operator changes the status.',
        ),
        _HelpSection(
          title: 'Emergency help',
          body:
              'For an immediate emergency, use the Safety hub to call 112 or your nearest available emergency contact. CrimeTrack does not replace emergency services.',
        ),
        _HelpSection(
          title: 'Location and privacy',
          body:
              'Location is used only when you choose GPS features. Your reports are associated with a private installation ID so status updates can return to this device.',
        ),
      ],
    ),
  );
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          body,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const Divider(height: 24, color: AppTheme.amber),
      ],
    ),
  );
}
