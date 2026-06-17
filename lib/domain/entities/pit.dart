class Pit {
  final String id;
  final String name;
  final double capacity;
  final double currentVolume;
  final String? gasTypeId;
  final bool isDeleted;

  const Pit({
    required this.id,
    required this.name,
    required this.capacity,
    required this.currentVolume,
    this.gasTypeId,
    required this.isDeleted,
  });

  Pit copyWith({
    String? id,
    String? name,
    double? capacity,
    double? currentVolume,
    String? gasTypeId,
    bool? isDeleted,
  }) {
    return Pit(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      currentVolume: currentVolume ?? this.currentVolume,
      gasTypeId: gasTypeId ?? this.gasTypeId,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'capacity': capacity,
      'currentVolume': currentVolume,
      'gasTypeId': gasTypeId,
      'isDeleted': isDeleted,
    };
  }

  factory Pit.fromMap(Map<String, dynamic> map) {
    return Pit(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      capacity: (map['capacity'] as num?)?.toDouble() ?? 0.0,
      currentVolume: (map['currentVolume'] as num?)?.toDouble() ?? 0.0,
      gasTypeId: map['gasTypeId'] as String?,
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }
}
