class RefillPayment {
  final String id;
  final double amount;
  final String? transferReference;
  final String? bankName;
  final String? accountNumber;
  final DateTime? paymentDate;
  final String refillId;
  final String? paymentTypeId;

  const RefillPayment({
    required this.id,
    required this.amount,
    this.transferReference,
    this.bankName,
    this.accountNumber,
    this.paymentDate,
    required this.refillId,
    this.paymentTypeId,
  });

  RefillPayment copyWith({
    String? id,
    double? amount,
    String? transferReference,
    String? bankName,
    String? accountNumber,
    DateTime? paymentDate,
    String? refillId,
    String? paymentTypeId,
  }) {
    return RefillPayment(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      transferReference: transferReference ?? this.transferReference,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      paymentDate: paymentDate ?? this.paymentDate,
      refillId: refillId ?? this.refillId,
      paymentTypeId: paymentTypeId ?? this.paymentTypeId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'transferReference': transferReference,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'paymentDate': paymentDate?.toIso8601String(),
      'refillId': refillId,
      'paymentTypeId': paymentTypeId,
    };
  }

  factory RefillPayment.fromMap(Map<String, dynamic> map) {
    return RefillPayment(
      id: map['id'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      transferReference: map['transferReference'] as String?,
      bankName: map['bankName'] as String?,
      accountNumber: map['accountNumber'] as String?,
      paymentDate: DateTime.tryParse(map['paymentDate'] as String? ?? ''),
      refillId: map['refillId'] as String? ?? '',
      paymentTypeId: map['paymentTypeId'] as String?,
    );
  }
}
