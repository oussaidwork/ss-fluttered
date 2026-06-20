import '../entities/app_permission.dart';

abstract class PermissionRepository {
  Stream<List<AppPermission>> watchPermissions();
  Future<void> updatePermission(AppPermission permission);
}
