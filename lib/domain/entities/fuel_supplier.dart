class FuelSupplier {
  final String id;
  final String name;
  final bool isActive;

  const FuelSupplier({
    required this.id,
    required this.name,
    required this.isActive,
  });

  FuelSupplier copyWith({
    String? id,
    String? name,
    bool? isActive,
  }) {
    return FuelSupplier(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isActive': isActive,
    };
  }

  factory FuelSupplier.fromMap(Map<String, dynamic> map) {
    return FuelSupplier(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
    );
  }
}
