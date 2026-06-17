class Product {
  final String id;
  final String name;
  final double price;
  final double? priceIn;
  final double? priceOut;
  final String? unit;
  final double stockQuantity;
  final String? category;
  final bool isActive;
  final bool isDeleted;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.priceIn,
    this.priceOut,
    this.unit,
    required this.stockQuantity,
    this.category,
    required this.isActive,
    required this.isDeleted,
  });

  Product copyWith({
    String? id,
    String? name,
    double? price,
    double? priceIn,
    double? priceOut,
    String? unit,
    double? stockQuantity,
    String? category,
    bool? isActive,
    bool? isDeleted,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      priceIn: priceIn ?? this.priceIn,
      priceOut: priceOut ?? this.priceOut,
      unit: unit ?? this.unit,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'priceIn': priceIn,
      'priceOut': priceOut,
      'unit': unit,
      'stockQuantity': stockQuantity,
      'category': category,
      'isActive': isActive,
      'isDeleted': isDeleted,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      priceIn: (map['priceIn'] as num?)?.toDouble(),
      priceOut: (map['priceOut'] as num?)?.toDouble(),
      unit: map['unit'] as String?,
      stockQuantity: (map['stockQuantity'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }
}
