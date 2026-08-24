import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum IncidentStatus { pending, verified, resolved, rejected, flagged }

enum IncidentRisk { high, medium, low }

class Incident {
  const Incident({
    this.id,
    required this.type,
    required this.description,
    required this.location,
    required this.reportedAt,
    required this.status,
    required this.risk,
    this.evidencePath,
    this.latitude,
    this.longitude,
  });

  final int? id;
  final String type;
  final String description;
  final String location;
  final DateTime reportedAt;
  final IncidentStatus status;
  final IncidentRisk risk;
  final String? evidencePath;
  final double? latitude;
  final double? longitude;

  Incident copyWith({IncidentStatus? status, IncidentRisk? risk}) => Incident(
    id: id,
    type: type,
    description: description,
    location: location,
    reportedAt: reportedAt,
    status: status ?? this.status,
    risk: risk ?? this.risk,
    evidencePath: evidencePath,
    latitude: latitude,
    longitude: longitude,
  );

  Map<String, Object?> toJson() => {
    if (id != null) 'id': id,
    'type': type,
    'description': description,
    'location': location,
    'reportedAt': reportedAt.toIso8601String(),
    'status': status.name,
    'risk': risk.name,
    'evidencePath': evidencePath,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory Incident.fromJson(Map<String, dynamic> json) => Incident(
    id: (json['id'] as num?)?.toInt(),
    type: json['type'] as String? ?? 'Other',
    description: json['description'] as String? ?? '',
    location: json['location'] as String? ?? 'Unknown location',
    reportedAt:
        DateTime.tryParse(
          (json['reportedAt'] ?? json['reported_at']) as String? ?? '',
        ) ??
        DateTime.now(),
    status: IncidentStatus.values.byName(
      json['status'] as String? ?? IncidentStatus.pending.name,
    ),
    risk: IncidentRisk.values.byName(
      json['risk'] as String? ?? IncidentRisk.medium.name,
    ),
    evidencePath: (json['evidencePath'] ?? json['evidence_path']) as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );

  String get statusLabel => switch (status) {
    IncidentStatus.pending => 'Under review',
    IncidentStatus.verified => 'Verified',
    IncidentStatus.resolved => 'Resolved',
    IncidentStatus.rejected => 'Rejected',
    IncidentStatus.flagged => 'Flagged',
  };

  String get riskLabel => switch (risk) {
    IncidentRisk.high => 'High',
    IncidentRisk.medium => 'Medium',
    IncidentRisk.low => 'Low',
  };

  Color get riskColor => switch (risk) {
    IncidentRisk.high => AppTheme.danger,
    IncidentRisk.medium => AppTheme.amber,
    IncidentRisk.low => AppTheme.success,
  };

  String get relativeTime {
    final difference = DateTime.now().difference(reportedAt);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) return '${difference.inHours} hr ago';
    return '${difference.inDays} days ago';
  }
}
