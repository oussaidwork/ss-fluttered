import '../enums/sale_type.dart';

class SaleItem {
  final String id;
  final String saleId;
  final SaleType saleType;
  final String? gasTypeId;
  final String? productId;
  final double? volume;
  final double unitPrice;
  final double lineTotal;
  final double quantity;
  final String? driverName;
  final String? vehiclePlate;
  final String? notes;
  final DateTime timestamp;

  const SaleItem({
    required this.id,
    required this.saleId,
    required this.saleType,
    this.gasTypeId,
    this.productId,
    this.volume,
    required this.unitPrice,
    required this.lineTotal,
    this.quantity = 1.0,
    this.driverName,
    this.vehiclePlate,
    this.notes,
    required this.timestamp,
  });

  SaleItem copyWith({
    String? id,
    String? saleId,
    SaleType? saleType,
    String? gasTypeId,
    String? productId,
    double? volume,
    double? unitPrice,
    double? lineTotal,
    double? quantity,
    String? driverName,
    String? vehiclePlate,
    String? notes,
    DateTime? timestamp,
  }) {
    return SaleItem(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      saleType: saleType ?? this.saleType,
      gasTypeId: gasTypeId ?? this.gasTypeId,
      productId: productId ?? this.productId,
      volume: volume ?? this.volume,
      unitPrice: unitPrice ?? this.unitPrice,
      lineTotal: lineTotal ?? this.lineTotal,
      quantity: quantity ?? this.quantity,
      driverName: driverName ?? this.driverName,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saleId': saleId,
      'saleType': saleType.value,
      'gasTypeId': gasTypeId,
      'productId': productId,
      'volume': volume,
      'unitPrice': unitPrice,
      'lineTotal': lineTotal,
      'quantity': quantity,
      'driverName': driverName,
      'vehiclePlate': vehiclePlate,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'] as String? ?? '',
      saleId: map['saleId'] as String? ?? '',
      saleType: SaleType.fromString(map['saleType'] as String? ?? 'FUEL'),
      gasTypeId: map['gasTypeId'] as String?,
      productId: map['productId'] as String?,
      volume: (map['volume'] as num?)?.toDouble(),
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      lineTotal: (map['lineTotal'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      driverName: map['driverName'] as String?,
      vehiclePlate: map['vehiclePlate'] as String?,
      notes: map['notes'] as String?,
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
