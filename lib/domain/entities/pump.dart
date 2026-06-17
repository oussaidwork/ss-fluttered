class Pump {
  final String id;
  final String name;
  final bool isActive;
  final double initialAnalogCounter;
  final String? groupId;
  final String? subgroup;
  final String? color;
  final String pitId;
  final bool isDeleted;

  const Pump({
    required this.id,
    required this.name,
    required this.isActive,
    required this.initialAnalogCounter,
    this.groupId,
    this.subgroup,
    this.color,
    required this.pitId,
    required this.isDeleted,
  });

  Pump copyWith({
    String? id,
    String? name,
    bool? isActive,
    double? initialAnalogCounter,
    String? groupId,
    String? subgroup,
    String? color,
    String? pitId,
    bool? isDeleted,
  }) {
    return Pump(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      initialAnalogCounter: initialAnalogCounter ?? this.initialAnalogCounter,
      groupId: groupId ?? this.groupId,
      subgroup: subgroup ?? this.subgroup,
      color: color ?? this.color,
      pitId: pitId ?? this.pitId,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isActive': isActive,
      'initialAnalogCounter': initialAnalogCounter,
      'groupId': groupId,
      'subgroup': subgroup,
      'color': color,
      'pitId': pitId,
      'isDeleted': isDeleted,
    };
  }

  factory Pump.fromMap(Map<String, dynamic> map) {
    return Pump(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? false,
      initialAnalogCounter: (map['initialAnalogCounter'] as num?)?.toDouble() ?? 0.0,
      groupId: map['groupId'] as String?,
      subgroup: map['subgroup'] as String?,
      color: map['color'] as String?,
      pitId: map['pitId'] as String? ?? '',
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }
}
