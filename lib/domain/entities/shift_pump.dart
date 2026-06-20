
class ShiftPump {
  final String id;
  final String shiftId;
  final String pumpId;
  final double startAnalogCounter;
  final double? endAnalogCounter;
  final double? priceAtShift;
  double volume;
  double revenue;

  ShiftPump({
    required this.id,
    required this.shiftId,
    required this.pumpId,
    required this.startAnalogCounter,
    this.endAnalogCounter,
    this.priceAtShift,
    this.volume = 0.0,
    this.revenue = 0.0,
  });

  ShiftPump copyWith({
    String? id,
    String? shiftId,
    String? pumpId,
    double? startAnalogCounter,
    double? endAnalogCounter,
    double? priceAtShift,
    double? volume,
    double? revenue,
  }) {
    return ShiftPump(
      id: id ?? this.id,
      shiftId: shiftId ?? this.shiftId,
      pumpId: pumpId ?? this.pumpId,
      startAnalogCounter: startAnalogCounter ?? this.startAnalogCounter,
      endAnalogCounter: endAnalogCounter ?? this.endAnalogCounter,
      priceAtShift: priceAtShift ?? this.priceAtShift,
      volume: volume ?? this.volume,
      revenue: revenue ?? this.revenue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shiftId': shiftId,
      'pumpId': pumpId,
      'startAnalogCounter': startAnalogCounter,
      'endAnalogCounter': endAnalogCounter,
      'priceAtShift': priceAtShift,
      'volume': volume,
      'revenue': revenue,
    };
  }

  factory ShiftPump.fromMap(Map<String, dynamic> map) {
    return ShiftPump(
      id: map['id'] as String? ?? '',
      shiftId: map['shiftId'] as String? ?? '',
      pumpId: map['pumpId'] as String? ?? '',
      startAnalogCounter: (map['startAnalogCounter'] as num?)?.toDouble() ?? 0.0,
      endAnalogCounter: (map['endAnalogCounter'] as num?)?.toDouble(),
      priceAtShift: (map['priceAtShift'] as num?)?.toDouble(),
      volume: (map['volume'] as num?)?.toDouble() ?? 0.0,
      revenue: (map['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
