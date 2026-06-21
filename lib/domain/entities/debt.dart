class Debt {
  final String id;
  final double amount;
  final DateTime? dueDate;
  final String clientId;
  final String? driverName;
  final String? vehiclePlate;
  final bool isDeleted;
  final DateTime created;

  const Debt({
    required this.id,
    required this.amount,
    this.dueDate,
    required this.clientId,
    this.driverName,
    this.vehiclePlate,
    required this.isDeleted,
    required this.created,
  });

  Debt copyWith({
    String? id,
    double? amount,
    DateTime? dueDate,
    String? clientId,
    String? driverName,
    String? vehiclePlate,
    bool? isDeleted,
    DateTime? created,
  }) {
    return Debt(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      clientId: clientId ?? this.clientId,
      driverName: driverName ?? this.driverName,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      isDeleted: isDeleted ?? this.isDeleted,
      created: created ?? this.created,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'dueDate': dueDate?.toIso8601String(),
      'clientId': clientId,
      'driverName': driverName,
      'vehiclePlate': vehiclePlate,
      'isDeleted': isDeleted,
      'created': created.toIso8601String(),
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: DateTime.tryParse(map['dueDate'] as String? ?? ''),
      clientId: map['clientId'] as String? ?? '',
      driverName: map['driverName'] as String?,
      vehiclePlate: map['vehiclePlate'] as String?,
      isDeleted: map['isDeleted'] as bool? ?? false,
      created: DateTime.tryParse(map['created'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
