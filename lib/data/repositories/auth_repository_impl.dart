import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../auth/firebase_auth_provider.dart';

/// Implementation of [AuthRepository] using Firebase Auth.
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthProvider _authProvider;

  AuthRepositoryImpl({FirebaseAuthProvider? authProvider})
      : _authProvider = authProvider ?? firebaseAuthProvider;

  @override
  AuthUser? get currentUser {
    final user = _authProvider.currentUser;
    if (user == null) return null;
    return AuthUser(uid: user.uid, email: user.email);
  }

  @override
  Stream<AuthUser?> get authStateChanges =>
      _authProvider.authStateChanges.map((user) {
        if (user == null) return null;
        return AuthUser(uid: user.uid, email: user.email);
      });

  @override
  Future<void> signIn(String email, String password) async {
    await _authProvider.signIn(email, password);
  }

  @override
  Future<void> signOut() async {
    await _authProvider.signOut();
  }

  @override
  Future<void> signUp(String email, String password) async {
    await _authProvider.signUp(email, password);
  }
}
