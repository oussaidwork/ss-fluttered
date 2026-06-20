import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import '../enums/sale_type.dart';

class Sale {
  final String id;
  final SaleType saleType;
  final double? volume;
  final double? unitPrice;
  final double totalPrice;
  final String? driverName;
  final String? vehiclePlate;
  final String? driverPhone;
  final String? notes;
  final DateTime timestamp;
  final String? shiftId;
  final String? clientId;
  final String? gasTypeId;
  final String? productId;
  final String? serviceId;
  final String? paymentTypeId;
  final String? workerId;
  final bool isDeleted;
  final DateTime createdAt;

  const Sale({
    required this.id,
    required this.saleType,
    this.volume,
    this.unitPrice,
    required this.totalPrice,
    this.driverName,
    this.vehiclePlate,
    this.driverPhone,
    this.notes,
    required this.timestamp,
    this.shiftId,
    this.clientId,
    this.gasTypeId,
    this.productId,
    this.serviceId,
    this.paymentTypeId,
    this.workerId,
    this.isDeleted = false,
    required this.createdAt,
  });

  Sale copyWith({
    String? id,
    SaleType? saleType,
    double? volume,
    double? unitPrice,
    double? totalPrice,
    String? driverName,
    String? vehiclePlate,
    String? driverPhone,
    String? notes,
    DateTime? timestamp,
    String? shiftId,
    String? clientId,
    String? gasTypeId,
    String? productId,
    String? serviceId,
    String? paymentTypeId,
    String? workerId,
    bool? isDeleted,
    DateTime? createdAt,
  }) {
    return Sale(
      id: id ?? this.id,
      saleType: saleType ?? this.saleType,
      volume: volume ?? this.volume,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      driverName: driverName ?? this.driverName,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      driverPhone: driverPhone ?? this.driverPhone,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
      shiftId: shiftId ?? this.shiftId,
      clientId: clientId ?? this.clientId,
      gasTypeId: gasTypeId ?? this.gasTypeId,
      productId: productId ?? this.productId,
      serviceId: serviceId ?? this.serviceId,
      paymentTypeId: paymentTypeId ?? this.paymentTypeId,
      workerId: workerId ?? this.workerId,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saleType': saleType.value,
      'volume': volume,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'driverName': driverName,
      'vehiclePlate': vehiclePlate,
      'driverPhone': driverPhone,
      'notes': notes,
      'timestamp': Timestamp.fromDate(timestamp),
      'shiftId': shiftId,
      'clientId': clientId,
      'gasTypeId': gasTypeId,
      'productId': productId,
      'serviceId': serviceId,
      'paymentTypeId': paymentTypeId,
      'workerId': workerId,
      'isDeleted': isDeleted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as String? ?? '',
      saleType: SaleType.fromString(map['saleType'] as String? ?? 'FUEL'),
      volume: (map['volume'] as num?)?.toDouble(),
      unitPrice: (map['unitPrice'] as num?)?.toDouble(),
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      driverName: map['driverName'] as String?,
      vehiclePlate: map['vehiclePlate'] as String?,
      driverPhone: map['driverPhone'] as String?,
      notes: map['notes'] as String?,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      shiftId: map['shiftId'] as String?,
      clientId: map['clientId'] as String?,
      gasTypeId: map['gasTypeId'] as String?,
      productId: map['productId'] as String?,
      serviceId: map['serviceId'] as String?,
      paymentTypeId: map['paymentTypeId'] as String?,
      workerId: map['workerId'] as String?,
      isDeleted: map['isDeleted'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
