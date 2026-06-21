import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/auth/firebase_auth_provider.dart';
import '../../domain/entities/user.dart';
import 'repository_providers.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return firebaseAuthProvider.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final repo = ref.watch(userRepositoryProvider);
  return repo.getUser(user.uid);
});

final userRoleProvider = Provider<String>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  return profile?.role.value ?? 'Worker';
});

final isAdminProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == 'Admin' || role == 'SuperUser';
});
