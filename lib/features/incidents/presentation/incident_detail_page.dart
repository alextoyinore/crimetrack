import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../models/incident.dart';

class IncidentDetailPage extends StatelessWidget {
  const IncidentDetailPage({super.key, required this.incident});

  final Incident incident;

  bool get _isVideo {
    final path = incident.evidencePath?.toLowerCase() ?? '';
    return path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.avi') ||
        path.endsWith('.mkv') ||
        path.endsWith('.webm');
  }

  Future<void> _openVideo(BuildContext context) async {
    final path = incident.evidencePath;
    if (path == null) return;
    final launched = await launchUrl(
      path.startsWith('http') ? Uri.parse(path) : Uri.file(path),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this video')),
      );
    }
  }

  Widget _evidence(BuildContext context) {
    final path = incident.evidencePath;
    if (path == null || path.isEmpty) {
      return const Text('No evidence attached');
    }
    if (_isVideo) {
      return FilledButton.icon(
        onPressed: () => _openVideo(context),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Open video'),
      );
    }
    final image = path.startsWith('http')
        ? Image.network(path, fit: BoxFit.cover)
        : Image.file(File(path), fit: BoxFit.cover);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 320),
        child: SizedBox(width: double.infinity, child: image),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Report details')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(incident.type, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          incident.statusLabel,
          style: TextStyle(
            color: incident.riskColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),
        _DetailLine(label: 'Location', value: incident.location),
        _DetailLine(
          label: 'Reported',
          value: incident.reportedAt.toLocal().toString(),
        ),
        _DetailLine(label: 'Risk', value: incident.riskLabel),
        const SizedBox(height: 16),
        Text('Description', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(incident.description),
        const SizedBox(height: 24),
        Text('Evidence', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        _evidence(context),
      ],
    ),
  );
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(label, style: const TextStyle(color: AppTheme.muted)),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
