import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class LogEntry {
  final String id;
  final String action;
  final String? details;
  final DateTime timestamp;
  final String? userId;

  const LogEntry({
    required this.id,
    required this.action,
    this.details,
    required this.timestamp,
    this.userId,
  });

  LogEntry copyWith({
    String? id,
    String? action,
    String? details,
    DateTime? timestamp,
    String? userId,
  }) {
    return LogEntry(
      id: id ?? this.id,
      action: action ?? this.action,
      details: details ?? this.details,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'details': details,
      'timestamp': Timestamp.fromDate(timestamp),
      'userId': userId,
    };
  }

  factory LogEntry.fromMap(Map<String, dynamic> map) {
    return LogEntry(
      id: map['id'] as String? ?? '',
      action: map['action'] as String? ?? '',
      details: map['details'] as String?,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: map['userId'] as String?,
    );
  }
}
