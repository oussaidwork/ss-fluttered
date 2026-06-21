import '../domain/entities/auth_user.dart';
import '../domain/entities/user.dart';
import '../domain/enums/user_role.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/user_repository.dart';

class AuthService {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  AuthService({
    required AuthRepository authRepository,
    required UserRepository userRepository,
  })  : _authRepository = authRepository,
        _userRepository = userRepository;

  Future<AuthUser?> signIn(String email, String password) async {
    await _authRepository.signIn(email, password);
    return _authRepository.currentUser;
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
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
    return _authRepository.currentUser?.uid;
  }

  Future<UserProfile?> getCurrentUserProfile() async {
    final uid = getCurrentUserId();
    if (uid == null) return null;
    return _userRepository.getUser(uid);
  }
}
