import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import '../enums/payment_status.dart';

class Payment {
  final String id;
  final double amount;
  final PaymentStatus status;
  final String? checkBankName;
  final String? checkNumber;
  final DateTime? dueDate;
  final DateTime? clearedAt;
  final String? notes;
  final String? clientId;
  final String? saleId;
  final String? paymentTypeId;
  final String? recordedBy;
  final bool isDeleted;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.amount,
    required this.status,
    this.checkBankName,
    this.checkNumber,
    this.dueDate,
    this.clearedAt,
    this.notes,
    this.clientId,
    this.saleId,
    this.paymentTypeId,
    this.recordedBy,
    required this.isDeleted,
    required this.createdAt,
  });

  Payment copyWith({
    String? id,
    double? amount,
    PaymentStatus? status,
    String? checkBankName,
    String? checkNumber,
    DateTime? dueDate,
    DateTime? clearedAt,
    String? notes,
    String? clientId,
    String? saleId,
    String? paymentTypeId,
    String? recordedBy,
    bool? isDeleted,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      checkBankName: checkBankName ?? this.checkBankName,
      checkNumber: checkNumber ?? this.checkNumber,
      dueDate: dueDate ?? this.dueDate,
      clearedAt: clearedAt ?? this.clearedAt,
      notes: notes ?? this.notes,
      clientId: clientId ?? this.clientId,
      saleId: saleId ?? this.saleId,
      paymentTypeId: paymentTypeId ?? this.paymentTypeId,
      recordedBy: recordedBy ?? this.recordedBy,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'status': status.value,
      'checkBankName': checkBankName,
      'checkNumber': checkNumber,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'clearedAt': clearedAt != null ? Timestamp.fromDate(clearedAt!) : null,
      'notes': notes,
      'clientId': clientId,
      'saleId': saleId,
      'paymentTypeId': paymentTypeId,
      'recordedBy': recordedBy,
      'isDeleted': isDeleted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      status: PaymentStatus.fromString(map['status'] as String? ?? 'PENDING'),
      checkBankName: map['checkBankName'] as String?,
      checkNumber: map['checkNumber'] as String?,
      dueDate: (map['dueDate'] as Timestamp?)?.toDate(),
      clearedAt: (map['clearedAt'] as Timestamp?)?.toDate(),
      notes: map['notes'] as String?,
      clientId: map['clientId'] as String?,
      saleId: map['saleId'] as String?,
      paymentTypeId: map['paymentTypeId'] as String?,
      recordedBy: map['recordedBy'] as String?,
      isDeleted: map['isDeleted'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
