import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class Sale {
  final String id;
  final String? shiftId;
  final String? clientId;
  final String? workerId;
  final String? paymentTypeId;
  final double totalAmount;
  final String? notes;
  final DateTime timestamp;
  final bool isDeleted;
  final DateTime createdAt;

  const Sale({
    required this.id,
    this.shiftId,
    this.clientId,
    this.workerId,
    this.paymentTypeId,
    required this.totalAmount,
    this.notes,
    required this.timestamp,
    required this.isDeleted,
    required this.createdAt,
  });

  Sale copyWith({
    String? id,
    String? shiftId,
    String? clientId,
    String? workerId,
    String? paymentTypeId,
    double? totalAmount,
    String? notes,
    DateTime? timestamp,
    bool? isDeleted,
    DateTime? createdAt,
  }) {
    return Sale(
      id: id ?? this.id,
      shiftId: shiftId ?? this.shiftId,
      clientId: clientId ?? this.clientId,
      workerId: workerId ?? this.workerId,
      paymentTypeId: paymentTypeId ?? this.paymentTypeId,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shiftId': shiftId,
      'clientId': clientId,
      'workerId': workerId,
      'paymentTypeId': paymentTypeId,
      'totalAmount': totalAmount,
      'notes': notes,
      'timestamp': Timestamp.fromDate(timestamp),
      'isDeleted': isDeleted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as String? ?? '',
      shiftId: map['shiftId'] as String?,
      clientId: map['clientId'] as String?,
      workerId: map['workerId'] as String?,
      paymentTypeId: map['paymentTypeId'] as String?,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String?,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDeleted: map['isDeleted'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
