import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class PitRefill {
  final String id;
  final double volume;
  final double? costPerLiter;
  final double? totalCost;
  final double? profitMargin;
  final DateTime timestamp;
  final String pitId;
  final String? recordedBy;
  final String? supplierId;
  final String? fleetTruckId;
  final String? fleetDriverName;
  final String? fleetVehiclePlate;
  final String? truckDriver;
  final String? depotNum;
  final String? bchNum;
  final String? vehPlate;
  final String? tankId;

  const PitRefill({
    required this.id,
    required this.volume,
    this.costPerLiter,
    this.totalCost,
    this.profitMargin,
    required this.timestamp,
    required this.pitId,
    this.recordedBy,
    this.supplierId,
    this.fleetTruckId,
    this.fleetDriverName,
    this.fleetVehiclePlate,
    this.truckDriver,
    this.depotNum,
    this.bchNum,
    this.vehPlate,
    this.tankId,
  });

  PitRefill copyWith({
    String? id,
    double? volume,
    double? costPerLiter,
    double? totalCost,
    double? profitMargin,
    DateTime? timestamp,
    String? pitId,
    String? recordedBy,
    String? supplierId,
    String? fleetTruckId,
    String? fleetDriverName,
    String? fleetVehiclePlate,
    String? truckDriver,
    String? depotNum,
    String? bchNum,
    String? vehPlate,
    String? tankId,
  }) {
    return PitRefill(
      id: id ?? this.id,
      volume: volume ?? this.volume,
      costPerLiter: costPerLiter ?? this.costPerLiter,
      totalCost: totalCost ?? this.totalCost,
      profitMargin: profitMargin ?? this.profitMargin,
      timestamp: timestamp ?? this.timestamp,
      pitId: pitId ?? this.pitId,
      recordedBy: recordedBy ?? this.recordedBy,
      supplierId: supplierId ?? this.supplierId,
      fleetTruckId: fleetTruckId ?? this.fleetTruckId,
      fleetDriverName: fleetDriverName ?? this.fleetDriverName,
      fleetVehiclePlate: fleetVehiclePlate ?? this.fleetVehiclePlate,
      truckDriver: truckDriver ?? this.truckDriver,
      depotNum: depotNum ?? this.depotNum,
      bchNum: bchNum ?? this.bchNum,
      vehPlate: vehPlate ?? this.vehPlate,
      tankId: tankId ?? this.tankId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'volume': volume,
      'costPerLiter': costPerLiter,
      'totalCost': totalCost,
      'profitMargin': profitMargin,
      'timestamp': Timestamp.fromDate(timestamp),
      'pitId': pitId,
      'recordedBy': recordedBy,
      'supplierId': supplierId,
      'fleetTruckId': fleetTruckId,
      'fleetDriverName': fleetDriverName,
      'fleetVehiclePlate': fleetVehiclePlate,
      'truckDriver': truckDriver,
      'depotNum': depotNum,
      'bchNum': bchNum,
      'vehPlate': vehPlate,
      'tankId': tankId,
    };
  }

  factory PitRefill.fromMap(Map<String, dynamic> map) {
    return PitRefill(
      id: map['id'] as String? ?? '',
      volume: (map['volume'] as num?)?.toDouble() ?? 0.0,
      costPerLiter: (map['costPerLiter'] as num?)?.toDouble(),
      totalCost: (map['totalCost'] as num?)?.toDouble(),
      profitMargin: (map['profitMargin'] as num?)?.toDouble(),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      pitId: map['pitId'] as String? ?? '',
      recordedBy: map['recordedBy'] as String?,
      supplierId: map['supplierId'] as String?,
      fleetTruckId: map['fleetTruckId'] as String?,
      fleetDriverName: map['fleetDriverName'] as String?,
      fleetVehiclePlate: map['fleetVehiclePlate'] as String?,
      truckDriver: map['truckDriver'] as String?,
      depotNum: map['depotNum'] as String?,
      bchNum: map['bchNum'] as String?,
      vehPlate: map['vehPlate'] as String?,
      tankId: map['tankId'] as String?,
    );
  }
}
