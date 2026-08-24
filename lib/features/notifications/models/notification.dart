class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.read,
    this.incidentId,
  });

  final int id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool read;
  final int? incidentId;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? 'CrimeTrack update',
        message: json['message'] as String? ?? '',
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        read: json['read'] == true || json['read'] == 1,
        incidentId: (json['incident_id'] as num?)?.toInt(),
      );
}
