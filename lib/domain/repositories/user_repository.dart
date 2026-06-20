import '../entities/user.dart';
import '../entities/salary_advance.dart';

abstract class UserRepository {
  Stream<List<UserProfile>> watchUsers();
  Future<UserProfile?> getUser(String userId);
  Future<void> updateUser(UserProfile user);

  Stream<List<SalaryAdvance>> watchAdvances({String? workerId});
  Future<void> createAdvance(SalaryAdvance advance);
  Future<void> resolveAdvance({
    required String advanceId,
    required bool approved,
    String? resolvedBy,
  });
}
