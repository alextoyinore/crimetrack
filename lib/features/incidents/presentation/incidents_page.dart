import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/map_preview.dart';
import '../../../core/widgets/page_title.dart';
import '../models/incident.dart';

class IncidentsPage extends StatefulWidget {
  const IncidentsPage({super.key, required this.incidents});
  final List<Incident> incidents;

  @override
  State<IncidentsPage> createState() => _IncidentsPageState();
}

class _IncidentsPageState extends State<IncidentsPage> {
  String _typeFilter = 'All types';
  String _statusFilter = 'All statuses';
  String _riskFilter = 'All risks';

  List<Incident> get _filteredIncidents => widget.incidents.where((incident) {
    final matchesType =
        _typeFilter == 'All types' || incident.type == _typeFilter;
    final matchesStatus =
        _statusFilter == 'All statuses' ||
        incident.statusLabel == _statusFilter;
    final matchesRisk =
        _riskFilter == 'All risks' || incident.riskLabel == _riskFilter;
    return matchesType && matchesStatus && matchesRisk;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final incidents = _filteredIncidents;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageTitle(
            title: 'Incident map',
            subtitle: 'Verified reports across Lagos Metro',
          ),
          const SizedBox(height: 18),
          _Filters(
            types: widget.incidents.map((incident) => incident.type).toSet(),
            type: _typeFilter,
            status: _statusFilter,
            risk: _riskFilter,
            onTypeChanged: (value) => setState(() => _typeFilter = value),
            onStatusChanged: (value) => setState(() => _statusFilter = value),
            onRiskChanged: (value) => setState(() => _riskFilter = value),
          ),
          const SizedBox(height: 18),
          MapPreview(incidents: incidents),
          const SizedBox(height: 18),
          if (incidents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 26),
              child: Center(
                child: Text(
                  'No incidents match these filters',
                  style: TextStyle(color: AppTheme.muted),
                ),
              ),
            )
          else
            ...incidents.map(
              (incident) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: IncidentItem(
                  type: incident.type,
                  location: incident.location,
                  time: incident.relativeTime,
                  color: incident.riskColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.types,
    required this.type,
    required this.status,
    required this.risk,
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.onRiskChanged,
  });

  final Set<String> types;
  final String type;
  final String status;
  final String risk;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onRiskChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: _FilterDropdown(
              value: type,
              label: 'Type',
              values: ['All types', ...types],
              onChanged: onTypeChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FilterDropdown(
              value: status,
              label: 'Status',
              values: const [
                'All statuses',
                'Under review',
                'Verified',
                'Resolved',
              ],
              onChanged: onStatusChanged,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      _FilterDropdown(
        value: risk,
        label: 'Risk',
        values: const ['All risks', 'High', 'Medium', 'Low'],
        onChanged: onRiskChanged,
      ),
    ],
  );
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.value,
    required this.label,
    required this.values,
    required this.onChanged,
  });

  final String value;
  final String label;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppTheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        isDense: true,
        items: values
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
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
