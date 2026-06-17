/// User roles.
enum UserRole {
  worker('Worker'),
  admin('Admin'),
  superUser('SuperUser'),
  audit('Audit');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String role) {
    return UserRole.values.firstWhere(
      (r) => r.value == role,
      orElse: () => UserRole.worker,
    );
  }

  bool get isAdminOrAbove => this == admin || this == superUser;
  bool get isSuperUser => this == superUser;
  bool get isAudit => this == audit;
  bool get canWrite => this != audit;
}