class GasType {
  final String id;
  final String name;
  final double priceIn;
  final double priceOut;
  final String? color;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GasType({
    required this.id,
    required this.name,
    required this.priceIn,
    required this.priceOut,
    this.color,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  GasType copyWith({
    String? id,
    String? name,
    double? priceIn,
    double? priceOut,
    String? color,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GasType(
      id: id ?? this.id,
      name: name ?? this.name,
      priceIn: priceIn ?? this.priceIn,
      priceOut: priceOut ?? this.priceOut,
      color: color ?? this.color,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'priceIn': priceIn,
      'priceOut': priceOut,
      'color': color,
      'isDeleted': isDeleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory GasType.fromMap(Map<String, dynamic> map) {
    return GasType(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      priceIn: (map['priceIn'] as num?)?.toDouble() ?? 0.0,
      priceOut: (map['priceOut'] as num?)?.toDouble() ?? 0.0,
      color: map['color'] as String?,
      isDeleted: map['isDeleted'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
