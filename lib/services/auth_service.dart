import 'package:firebase_auth/firebase_auth.dart';
import '../data/auth/firebase_auth_provider.dart';
import '../data/firestore/firestore_provider.dart';

class AuthService {
  Future<User?> signIn(String email, String password) async {
    final result = await firebaseAuthProvider.signIn(email, password);
    return result.user;
  }

  Future<void> signOut() async {
    await firebaseAuthProvider.signOut();
  }

  Future<void> createUserProfile(String uid, String email, {String role = 'Worker'}) async {
    await firestore.collection('users').doc(uid).set({
      'email': email,
      'role': role,
      'isActive': true,
      'fullName': '',
    });
  }

  String? getCurrentUserId() {
    return firebaseAuthProvider.currentUser?.uid;
  }
}

final authService = AuthService();
