class FuelPriceHistory {
  final String id;
  final double? oldPriceIn;
  final double? newPriceIn;
  final double? oldPriceOut;
  final double? newPriceOut;
  final DateTime changedAt;
  final String gasTypeId;
  final String? changedBy;
  final bool isDeleted;

  const FuelPriceHistory({
    required this.id,
    this.oldPriceIn,
    this.newPriceIn,
    this.oldPriceOut,
    this.newPriceOut,
    required this.changedAt,
    required this.gasTypeId,
    this.changedBy,
    required this.isDeleted,
  });

  FuelPriceHistory copyWith({
    String? id,
    double? oldPriceIn,
    double? newPriceIn,
    double? oldPriceOut,
    double? newPriceOut,
    DateTime? changedAt,
    String? gasTypeId,
    String? changedBy,
    bool? isDeleted,
  }) {
    return FuelPriceHistory(
      id: id ?? this.id,
      oldPriceIn: oldPriceIn ?? this.oldPriceIn,
      newPriceIn: newPriceIn ?? this.newPriceIn,
      oldPriceOut: oldPriceOut ?? this.oldPriceOut,
      newPriceOut: newPriceOut ?? this.newPriceOut,
      changedAt: changedAt ?? this.changedAt,
      gasTypeId: gasTypeId ?? this.gasTypeId,
      changedBy: changedBy ?? this.changedBy,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'oldPriceIn': oldPriceIn,
      'newPriceIn': newPriceIn,
      'oldPriceOut': oldPriceOut,
      'newPriceOut': newPriceOut,
      'changedAt': changedAt.toIso8601String(),
      'gasTypeId': gasTypeId,
      'changedBy': changedBy,
      'isDeleted': isDeleted,
    };
  }

  factory FuelPriceHistory.fromMap(Map<String, dynamic> map) {
    return FuelPriceHistory(
      id: map['id'] as String? ?? '',
      oldPriceIn: (map['oldPriceIn'] as num?)?.toDouble(),
      newPriceIn: (map['newPriceIn'] as num?)?.toDouble(),
      oldPriceOut: (map['oldPriceOut'] as num?)?.toDouble(),
      newPriceOut: (map['newPriceOut'] as num?)?.toDouble(),
      changedAt: DateTime.tryParse(map['changedAt'] as String? ?? '') ?? DateTime.now(),
      gasTypeId: map['gasTypeId'] as String? ?? '',
      changedBy: map['changedBy'] as String?,
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }
}
