class Service {
  final String id;
  final String name;
  final double? priceIn;
  final double priceOut;
  final String? unit;
  final bool isDeleted;

  const Service({
    required this.id,
    required this.name,
    this.priceIn,
    required this.priceOut,
    this.unit,
    required this.isDeleted,
  });

  Service copyWith({
    String? id,
    String? name,
    double? priceIn,
    double? priceOut,
    String? unit,
    bool? isDeleted,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      priceIn: priceIn ?? this.priceIn,
      priceOut: priceOut ?? this.priceOut,
      unit: unit ?? this.unit,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'priceIn': priceIn,
      'priceOut': priceOut,
      'unit': unit,
      'isDeleted': isDeleted,
    };
  }

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      priceIn: (map['priceIn'] as num?)?.toDouble(),
      priceOut: (map['priceOut'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String?,
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }
}
