import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class ShiftPump {
  final String id;
  final double? endAnalogCounter;
  final double? priceAtShift;
  final String shiftId;
  final String pumpId;
  double? previousEndAnalogCounter;
  double volume;
  double revenue;

  ShiftPump({
    required this.id,
    this.endAnalogCounter,
    this.priceAtShift,
    required this.shiftId,
    required this.pumpId,
    this.previousEndAnalogCounter,
    this.volume = 0.0,
    this.revenue = 0.0,
  });

  ShiftPump copyWith({
    String? id,
    double? endAnalogCounter,
    double? priceAtShift,
    String? shiftId,
    String? pumpId,
    double? previousEndAnalogCounter,
    double? volume,
    double? revenue,
  }) {
    return ShiftPump(
      id: id ?? this.id,
      endAnalogCounter: endAnalogCounter ?? this.endAnalogCounter,
      priceAtShift: priceAtShift ?? this.priceAtShift,
      shiftId: shiftId ?? this.shiftId,
      pumpId: pumpId ?? this.pumpId,
      previousEndAnalogCounter:
          previousEndAnalogCounter ?? this.previousEndAnalogCounter,
      volume: volume ?? this.volume,
      revenue: revenue ?? this.revenue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'endAnalogCounter': endAnalogCounter,
      'priceAtShift': priceAtShift,
      'shiftId': shiftId,
      'pumpId': pumpId,
      'previousEndAnalogCounter': previousEndAnalogCounter,
      'volume': volume,
      'revenue': revenue,
    };
  }

  factory ShiftPump.fromMap(Map<String, dynamic> map) {
    return ShiftPump(
      id: map['id'] as String? ?? '',
      endAnalogCounter: (map['endAnalogCounter'] as num?)?.toDouble(),
      priceAtShift: (map['priceAtShift'] as num?)?.toDouble(),
      shiftId: map['shiftId'] as String? ?? '',
      pumpId: map['pumpId'] as String? ?? '',
      previousEndAnalogCounter:
          (map['previousEndAnalogCounter'] as num?)?.toDouble(),
      volume: (map['volume'] as num?)?.toDouble() ?? 0.0,
      revenue: (map['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
