import '../../core/constants/firestore_paths.dart';
import '../../data/firestore/firestore_provider.dart';
import '../../domain/entities/app_permission.dart';
import '../../domain/repositories/permission_repository.dart';

class PermissionRepositoryImpl implements PermissionRepository {
  PermissionRepositoryImpl._();
  static final _instance = PermissionRepositoryImpl._();
  factory PermissionRepositoryImpl() => _instance;

  @override
  Stream<List<AppPermission>> watchPermissions() {
    return firestore
        .collection(FirestorePaths.appPermissions)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AppPermission.fromMap(d.data()))
              .toList(),
        );
  }

  @override
  Future<void> updatePermission(AppPermission permission) async {
    await firestore
        .collection(FirestorePaths.appPermissions)
        .doc(permission.id)
        .update(permission.toMap());
  }
}

final permissionRepository = PermissionRepositoryImpl();
