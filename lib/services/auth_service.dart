import 'package:firebase_auth/firebase_auth.dart';

import '../data/auth/firebase_auth_provider.dart';
import '../domain/entities/user.dart';
import '../domain/enums/user_role.dart';
import '../domain/repositories/user_repository.dart';

class AuthService {
  final UserRepository _userRepository;

  AuthService({
    required UserRepository userRepository,
  }) : _userRepository = userRepository;

  Future<User?> signIn(String email, String password) async {
    final result = await firebaseAuthProvider.signIn(email, password);
    return result.user;
  }

  Future<void> signOut() async {
    await firebaseAuthProvider.signOut();
  }

  Future<void> createUserProfile(String uid, String email,
      {String role = 'Worker'}) async {
    final user = UserProfile(
      id: uid,
      email: email,
      role: UserRole.fromString(role),
      isActive: true,
      fullName: '',
    );
    await _userRepository.updateUser(user);
  }

  String? getCurrentUserId() {
    return firebaseAuthProvider.currentUser?.uid;
  }

  Future<UserProfile?> getCurrentUserProfile() async {
    final uid = getCurrentUserId();
    if (uid == null) return null;
    return _userRepository.getUser(uid);
  }
}
