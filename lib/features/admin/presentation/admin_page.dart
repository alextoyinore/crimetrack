import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../incidents/models/incident.dart';

class AdminGate extends StatefulWidget {
  const AdminGate({
    super.key,
    required this.incidents,
    required this.onUpdate,
    required this.onLogin,
  });

  final List<Incident> incidents;
  final void Function(Incident, IncidentStatus, IncidentRisk) onUpdate;
  final Future<bool> Function(String, String) onLogin;

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  bool _authenticated = false;

  @override
  Widget build(BuildContext context) => _authenticated
      ? AdminPage(incidents: widget.incidents, onUpdate: widget.onUpdate)
      : Center(
          child: FilledButton.icon(
            onPressed: () async {
              final usernameController = TextEditingController();
              final passwordController = TextEditingController();
              final authenticated = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Admin sign in'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                        ),
                      ),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () async {
                        final success = await widget.onLogin(
                          usernameController.text.trim(),
                          passwordController.text,
                        );
                        if (context.mounted) Navigator.pop(context, success);
                      },
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
              );
              usernameController.dispose();
              passwordController.dispose();
              if (mounted && authenticated == true) {
                setState(() => _authenticated = true);
              }
            },
            icon: const Icon(Icons.login),
            label: const Text('SIGN IN TO ADMIN'),
          ),
        );
}

class AdminPage extends StatelessWidget {
  const AdminPage({super.key, required this.incidents, required this.onUpdate});

  final List<Incident> incidents;
  final void Function(
    Incident incident,
    IncidentStatus status,
    IncidentRisk risk,
  )
  onUpdate;

  @override
  Widget build(BuildContext context) {
    final pending = incidents
        .where((incident) => incident.status == IncidentStatus.pending)
        .toList();
    final verified = incidents
        .where((incident) => incident.status == IncidentStatus.verified)
        .length;
    final highRisk = incidents
        .where((incident) => incident.risk == IncidentRisk.high)
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin dashboard',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 7),
          const Text(
            'Review and classify community reports',
            style: TextStyle(color: AppTheme.muted),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _Summary(value: '${incidents.length}', label: 'Total'),
              const SizedBox(width: 8),
              _Summary(value: '${pending.length}', label: 'Pending'),
              const SizedBox(width: 8),
              _Summary(value: '$verified', label: 'Verified'),
              const SizedBox(width: 8),
              _Summary(value: '$highRisk', label: 'High risk'),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'PENDING REVIEW',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          if (pending.isEmpty)
            const Text(
              'No reports need review',
              style: TextStyle(color: AppTheme.muted),
            )
          else
            ...pending.map(
              (incident) => _ReviewCard(incident: incident, onUpdate: onUpdate),
            ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppTheme.muted),
          ),
        ],
      ),
    ),
  );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.incident, required this.onUpdate});
  final Incident incident;
  final void Function(
    Incident incident,
    IncidentStatus status,
    IncidentRisk risk,
  )
  onUpdate;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: const Color(0xFF30383D)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                incident.type,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              incident.relativeTime,
              style: const TextStyle(color: AppTheme.muted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          incident.location,
          style: const TextStyle(color: AppTheme.muted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Text(incident.description, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 14),
        DropdownButtonFormField<IncidentRisk>(
          initialValue: incident.risk,
          decoration: const InputDecoration(
            labelText: 'Risk level',
            isDense: true,
          ),
          items: IncidentRisk.values
              .map(
                (risk) => DropdownMenuItem(value: risk, child: Text(risk.name)),
              )
              .toList(),
          onChanged: (risk) {
            if (risk != null) onUpdate(incident, incident.status, risk);
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Action(
              label: 'Approve',
              status: IncidentStatus.verified,
              onUpdate: onUpdate,
              incident: incident,
            ),
            _Action(
              label: 'Flag',
              status: IncidentStatus.flagged,
              onUpdate: onUpdate,
              incident: incident,
            ),
            _Action(
              label: 'Reject',
              status: IncidentStatus.rejected,
              onUpdate: onUpdate,
              incident: incident,
            ),
          ],
        ),
      ],
    ),
  );
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.status,
    required this.onUpdate,
    required this.incident,
  });
  final String label;
  final IncidentStatus status;
  final void Function(
    Incident incident,
    IncidentStatus status,
    IncidentRisk risk,
  )
  onUpdate;
  final Incident incident;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: () => onUpdate(incident, status, incident.risk),
    child: Text(label),
  );
}
