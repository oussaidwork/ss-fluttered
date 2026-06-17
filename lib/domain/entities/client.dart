class Client {
  final String id;
  final String name;
  final String? phone;
  final String? plateNumber;
  final double? creditLimit;
  final double currentBalance;
  final String? address;
  final String? email;
  final bool isDeleted;

  const Client({
    required this.id,
    required this.name,
    this.phone,
    this.plateNumber,
    this.creditLimit,
    required this.currentBalance,
    this.address,
    this.email,
    required this.isDeleted,
  });

  Client copyWith({
    String? id,
    String? name,
    String? phone,
    String? plateNumber,
    double? creditLimit,
    double? currentBalance,
    String? address,
    String? email,
    bool? isDeleted,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      plateNumber: plateNumber ?? this.plateNumber,
      creditLimit: creditLimit ?? this.creditLimit,
      currentBalance: currentBalance ?? this.currentBalance,
      address: address ?? this.address,
      email: email ?? this.email,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'plateNumber': plateNumber,
      'creditLimit': creditLimit,
      'currentBalance': currentBalance,
      'address': address,
      'email': email,
      'isDeleted': isDeleted,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String?,
      plateNumber: map['plateNumber'] as String?,
      creditLimit: (map['creditLimit'] as num?)?.toDouble(),
      currentBalance: (map['currentBalance'] as num?)?.toDouble() ?? 0.0,
      address: map['address'] as String?,
      email: map['email'] as String?,
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }
}
