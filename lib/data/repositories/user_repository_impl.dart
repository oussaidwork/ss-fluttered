import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../data/firestore/firestore_provider.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/salary_advance.dart';
import '../../domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl._();
  static final _instance = UserRepositoryImpl._();
  factory UserRepositoryImpl() => _instance;

  @override
  Stream<List<UserProfile>> watchUsers() {
    return firestore
        .collection(FirestorePaths.users)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => UserProfile.fromMap(d.data())).toList(),
        );
  }

  @override
  Future<UserProfile?> getUser(String userId) async {
    final doc = await firestore
        .collection(FirestorePaths.users)
        .doc(userId)
        .get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(doc.data()!);
  }

  @override
  Future<void> updateUser(UserProfile user) async {
    await firestore
        .collection(FirestorePaths.users)
        .doc(user.id)
        .update(user.toMap());
  }

  @override
  Stream<List<SalaryAdvance>> watchAdvances({String? workerId}) {
    Query query = firestore
        .collection(FirestorePaths.salaryAdvances)
        .orderBy('requestDate', descending: true);

    if (workerId != null) {
      query = query.where('workerId', isEqualTo: workerId);
    }

    return query.snapshots().map(
          (snap) => snap.docs
              .map((d) => SalaryAdvance.fromMap(d.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  @override
  Future<void> createAdvance(SalaryAdvance advance) async {
    await firestore
        .collection(FirestorePaths.salaryAdvances)
        .doc(advance.id)
        .set(advance.toMap());
  }

  @override
  Future<void> resolveAdvance({
    required String advanceId,
    required bool approved,
    String? resolvedBy,
  }) async {
    await firestore
        .collection(FirestorePaths.salaryAdvances)
        .doc(advanceId)
        .update({
      'status': approved ? 'APPROVED' : 'REJECTED',
      'resolvedBy': resolvedBy,
      'resolutionDate': Timestamp.fromDate(DateTime.now()),
    });
  }
}

final userRepository = UserRepositoryImpl();
