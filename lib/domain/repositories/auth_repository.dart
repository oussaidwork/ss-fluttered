import '../entities/auth_user.dart';

/// Abstract repository for authentication operations.
///
/// Implementations wrap Firebase Auth or any other auth provider.
abstract class AuthRepository {
  /// Returns the currently authenticated user, or null.
  AuthUser? get currentUser;

  /// Stream of auth state changes.
  Stream<AuthUser?> get authStateChanges;

  /// Signs in with email and password.
  Future<void> signIn(String email, String password);

  /// Signs out the current user.
  Future<void> signOut();

  /// Creates a new user account with email and password.
  Future<void> signUp(String email, String password);
}
