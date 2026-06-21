import '../../core/constants/firestore_paths.dart';
import '../../data/datasource/database_datasource.dart';
import '../../data/datasource/firestore_datasource.dart';
import '../../data/firestore/firestore_provider.dart';
import '../../domain/entities/app_permission.dart';
import '../../domain/repositories/permission_repository.dart';

class PermissionRepositoryImpl implements PermissionRepository {
  final DatabaseDataSource _ds;

  PermissionRepositoryImpl(this._ds);

  /// Simple singleton for direct use (no DI).
  factory PermissionRepositoryImpl.simple() =>
      PermissionRepositoryImpl(FirestoreDataSourceImpl(firestore: firestore));

  @override
  Stream<List<AppPermission>> watchPermissions() {
    return _ds.streamQuery(
      FirestorePaths.appPermissions,
    ).map(
      (snap) => snap.docs
          .map((d) => AppPermission.fromMap(d.data() as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<void> updatePermission(AppPermission permission) async {
    await _ds.updateDoc(
        FirestorePaths.appPermissions, permission.id, permission.toMap());
  }
}

/// Top-level singleton for use in pages without DI.
final permissionRepository = PermissionRepositoryImpl.simple();
