import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import '../enums/shift_status.dart';

class WorkShift {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final ShiftStatus status;
  final double? actualCash;
  final String workerId;

  const WorkShift({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.actualCash,
    required this.workerId,
  });

  WorkShift copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    ShiftStatus? status,
    double? actualCash,
    String? workerId,
  }) {
    return WorkShift(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      actualCash: actualCash ?? this.actualCash,
      workerId: workerId ?? this.workerId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': status.value,
      'actualCash': actualCash,
      'workerId': workerId,
    };
  }

  factory WorkShift.fromMap(Map<String, dynamic> map) {
    return WorkShift(
      id: map['id'] as String? ?? '',
      startTime: (map['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (map['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: ShiftStatus.fromString(map['status'] as String? ?? 'CLOSED'),
      actualCash: (map['actualCash'] as num?)?.toDouble(),
      workerId: map['workerId'] as String? ?? '',
    );
  }
}
