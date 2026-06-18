class ClientFleet {
  final String id;
  final String clientId;
  final String plateNumber;
  final String? driverName;
  final String? vehicleType;
  final bool isActive;
  final bool isDeleted;

  const ClientFleet({
    required this.id,
    required this.clientId,
    required this.plateNumber,
    this.driverName,
    this.vehicleType,
    required this.isActive,
    required this.isDeleted,
  });

  ClientFleet copyWith({
    String? id,
    String? clientId,
    String? plateNumber,
    String? driverName,
    String? vehicleType,
    bool? isActive,
    bool? isDeleted,
  }) {
    return ClientFleet(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      plateNumber: plateNumber ?? this.plateNumber,
      driverName: driverName ?? this.driverName,
      vehicleType: vehicleType ?? this.vehicleType,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'plateNumber': plateNumber,
      'driverName': driverName,
      'vehicleType': vehicleType,
      'isActive': isActive,
      'isDeleted': isDeleted,
    };
  }

  factory ClientFleet.fromMap(Map<String, dynamic> map) {
    return ClientFleet(
      id: map['id'] as String? ?? '',
      clientId: map['clientId'] as String? ?? '',
      plateNumber: map['plateNumber'] as String? ?? '',
      driverName: map['driverName'] as String?,
      vehicleType: map['vehicleType'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }
}
