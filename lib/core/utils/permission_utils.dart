/// Permission checking utilities based on user role.
class PermissionUtils {
  PermissionUtils._();

  /// Checks whether a [role] can perform actions in a given [section].
  /// If [permittedRoles] is null or empty, access is denied.
  static bool canPerformActions(String? role, List<String>? permittedRoles) {
    if (permittedRoles == null || permittedRoles.isEmpty) return false;
    if (role == null) return false;
    return permittedRoles.contains(role);
  }

  /// Filters navigation items by permission.
  static List<T> filterNavByPermission<T>(
    List<T> items, {
    required String? userRole,
    required Map<String, List<String>> sectionPermissions,
    required String Function(T) sectionExtractor,
  }) {
    return items.where((item) {
      final section = sectionExtractor(item);
      final permittedRoles = sectionPermissions[section];
      return canPerformActions(userRole, permittedRoles);
    }).toList();
  }

  /// Returns true if the [role] is Admin or SuperUser.
  static bool isAdminOrAbove(String? role) {
    return role == 'Admin' || role == 'SuperUser';
  }

  /// Returns true if the [role] is SuperUser.
  static bool isSuperUser(String? role) {
    return role == 'SuperUser';
  }

  /// Returns true if the [role] is Audit (read-only).
  static bool isAudit(String? role) {
    return role == 'Audit';
  }
}