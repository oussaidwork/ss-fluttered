import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/locale_provider.dart';
import 'l10n/app_localizations.dart';

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

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final ThemeController _themeController = ThemeController();

  @override
  void initState() {
    super.initState();
    _themeController.addListener(() => setState(() {}));
    _themeController.loadFromPrefs();
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    final locale = ref.watch(localeProvider);
    final textDirection = locale.languageCode == 'ar'
        ? TextDirection.rtl
        : TextDirection.ltr;

    final bool isAuthenticated = authState.when(
      data: (user) => user != null,
      loading: () => false,
      error: (_, _) => false,
    );

    return ThemeProvider(
      controller: _themeController,
      child: MaterialApp.router(
        title: 'SS-RAGRAGA Station OS',
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _themeController.themeMode,
        routerConfig: createRouter(isAuthenticated: isAuthenticated),
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return Directionality(
            textDirection: textDirection,
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
