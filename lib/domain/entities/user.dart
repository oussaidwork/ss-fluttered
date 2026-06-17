import '../enums/user_role.dart';

class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final UserRole role;
  final bool isActive;
  final double? monthlySalary;

  const UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    required this.isActive,
    this.monthlySalary,
  });

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    UserRole? role,
    bool? isActive,
    double? monthlySalary,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      monthlySalary: monthlySalary ?? this.monthlySalary,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'role': role.value,
      'isActive': isActive,
      'monthlySalary': monthlySalary,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      fullName: map['fullName'] as String?,
      role: UserRole.fromString(map['role'] as String? ?? 'Worker'),
      isActive: map['isActive'] as bool? ?? false,
      monthlySalary: (map['monthlySalary'] as num?)?.toDouble(),
    );
  }
}
