import '../../core/constants/firestore_paths.dart';
import '../../data/datasource/database_datasource.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/salary_advance.dart';
import '../../domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final DatabaseDataSource _ds;

  UserRepositoryImpl(this._ds);

  @override
  Stream<List<UserProfile>> watchUsers() {
    return _ds.streamQuery(
      FirestorePaths.users,
    ).map(
      (snap) => snap.docs
          .map((d) => UserProfile.fromMap(d.data() as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<UserProfile?> getUser(String userId) async {
    final doc = await _ds.getDoc(FirestorePaths.users, userId);
    if (doc == null) return null;
    return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
  }

  @override
  Future<void> updateUser(UserProfile user) async {
    await _ds.updateDoc(FirestorePaths.users, user.id, user.toMap());
  }

  @override
  Stream<List<SalaryAdvance>> watchAdvances({String? workerId}) {
    if (workerId != null) {
      return _ds.streamQuery(
        FirestorePaths.salaryAdvances,
        filters: [QueryFilter(field: 'workerId', value: workerId)],
        orderByField: 'requestDate',
        orderByDescending: true,
      ).map(
        (snap) => snap.docs
            .map((d) => SalaryAdvance.fromMap(d.data() as Map<String, dynamic>))
            .toList(),
      );
    }

    return _ds.streamQuery(
      FirestorePaths.salaryAdvances,
      orderByField: 'requestDate',
      orderByDescending: true,
    ).map(
      (snap) => snap.docs
          .map((d) => SalaryAdvance.fromMap(d.data() as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<void> createAdvance(SalaryAdvance advance) async {
    await _ds.setDoc(
        FirestorePaths.salaryAdvances, advance.id, advance.toMap());
  }

  @override
  Future<void> resolveAdvance({
    required String advanceId,
    required bool approved,
    String? resolvedBy,
  }) async {
    await _ds.updateDoc(FirestorePaths.salaryAdvances, advanceId, {
      'status': approved ? 'APPROVED' : 'REJECTED',
      'resolvedBy': resolvedBy,
      'resolutionDate': DateTime.now().toIso8601String(),
    });
  }
}
