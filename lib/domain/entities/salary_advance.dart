import '../../core/utils/date_utils.dart';
import '../enums/advance_status.dart';

class SalaryAdvance {
  final String id;
  final double amount;
  final AdvanceStatus status;
  final DateTime requestDate;
  final DateTime? resolutionDate;
  final String workerId;
  final String? resolvedBy;

  const SalaryAdvance({
    required this.id,
    required this.amount,
    required this.status,
    required this.requestDate,
    this.resolutionDate,
    required this.workerId,
    this.resolvedBy,
  });

  SalaryAdvance copyWith({
    String? id,
    double? amount,
    AdvanceStatus? status,
    DateTime? requestDate,
    DateTime? resolutionDate,
    String? workerId,
    String? resolvedBy,
  }) {
    return SalaryAdvance(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      requestDate: requestDate ?? this.requestDate,
      resolutionDate: resolutionDate ?? this.resolutionDate,
      workerId: workerId ?? this.workerId,
      resolvedBy: resolvedBy ?? this.resolvedBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'status': status.value,
      'requestDate': requestDate.toIso8601String(),
      'resolutionDate': resolutionDate?.toIso8601String(),
      'workerId': workerId,
      'resolvedBy': resolvedBy,
    };
  }

  factory SalaryAdvance.fromMap(Map<String, dynamic> map) {
    return SalaryAdvance(
      id: map['id'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      status: AdvanceStatus.fromString(map['status'] as String? ?? 'PENDING'),
      requestDate: DateUtilsApp.parseFirestoreDateTime(map['requestDate']),
      resolutionDate: DateUtilsApp.parseFirestoreDateTime(map['resolutionDate'], fallback: null),
      workerId: map['workerId'] as String? ?? '',
      resolvedBy: map['resolvedBy'] as String?,
    );
  }
}
