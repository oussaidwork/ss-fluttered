import '../../core/utils/date_utils.dart';
import '../enums/shift_status.dart';

class WorkShift {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final ShiftStatus status;
  final double? actualCash;
  final double? expectedCash;
  final String workerId;
  final bool isDeleted;

  const WorkShift({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.actualCash,
    this.expectedCash,
    required this.workerId,
    this.isDeleted = false,
  });

  WorkShift copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    ShiftStatus? status,
    double? actualCash,
    double? expectedCash,
    String? workerId,
    bool? isDeleted,
  }) {
    return WorkShift(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      actualCash: actualCash ?? this.actualCash,
      expectedCash: expectedCash ?? this.expectedCash,
      workerId: workerId ?? this.workerId,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status.value,
      'actualCash': actualCash,
      'expectedCash': expectedCash,
      'workerId': workerId,
      'isDeleted': isDeleted,
    };
  }

  factory WorkShift.fromMap(Map<String, dynamic> map) {
    return WorkShift(
      id: map['id'] as String? ?? '',
      startTime: DateUtilsApp.parseFirestoreDateTime(map['startTime']),
      endTime: DateUtilsApp.parseFirestoreDateTime(map['endTime']),
      status: ShiftStatus.fromString(map['status'] as String? ?? 'CLOSED'),
      actualCash: (map['actualCash'] as num?)?.toDouble(),
      expectedCash: (map['expectedCash'] as num?)?.toDouble(),
      workerId: map['workerId'] as String? ?? '',
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }
}
