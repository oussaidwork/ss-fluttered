import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_provider.dart';

bool _firebaseInitFailed = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
      _firebaseInitFailed = true;
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (_firebaseInitFailed) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Failed to initialize Firebase. Please check console output.',
                style: TextStyle(color: Colors.red)),
          ),
        ),
        debugShowCheckedModeBanner: false,
      );
    }

    final authState = ref.watch(authStateProvider);
    // If the stream has data and a non‑null user, consider the user authenticated.
    final bool isAuthenticated = authState.when(data: (user) => user != null, loading: () => false, error: (_, __) => false);
    return MaterialApp.router(
      title: 'SS-RAGRAGA Station OS',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: createRouter(isAuthenticated: isAuthenticated),
      debugShowCheckedModeBanner: false,
    );
  }
}
