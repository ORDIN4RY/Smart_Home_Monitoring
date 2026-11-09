enum EventSeverity { normal, warning, danger }

class EventLog {
  final String id;
  final String title;
  final String description;
  final String category; // 'gas', 'flame', 'door', 'motion', 'device'
  final EventSeverity severity;
  final DateTime timestamp;

  const EventLog({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    required this.timestamp,
  });

  factory EventLog.fromJson(Map<String, dynamic> json) {
    EventSeverity severity = EventSeverity.normal;
    final sevStr = (json['severity'] as String? ?? '').toLowerCase();
    if (sevStr == 'danger') {
      severity = EventSeverity.danger;
    } else if (sevStr == 'warning') {
      severity = EventSeverity.warning;
    }

    return EventLog(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Event',
      description: json['description'] ?? '',
      category: json['category'] ?? 'general',
      severity: severity,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'severity': severity.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
