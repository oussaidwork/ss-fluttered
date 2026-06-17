class PaymentType {
  final String id;
  final String name;
  final String code;
  final String? icon;

  const PaymentType({
    required this.id,
    required this.name,
    required this.code,
    this.icon,
  });

  PaymentType copyWith({
    String? id,
    String? name,
    String? code,
    String? icon,
  }) {
    return PaymentType(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      icon: icon ?? this.icon,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'icon': icon,
    };
  }

  factory PaymentType.fromMap(Map<String, dynamic> map) {
    return PaymentType(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      code: map['code'] as String? ?? '',
      icon: map['icon'] as String?,
    );
  }
}
