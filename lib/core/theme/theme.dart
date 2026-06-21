import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════
// PART 1 — COLOR SCHEMES (explicit semantic colors)
// ═══════════════════════════════════════════════════════════════

/// Light mode palette — clean light‑grey dashboard aesthetic.
const ColorScheme _lightColorScheme = ColorScheme.light(
  // Brand
  primary: Color(0xFF0066CC),
  onPrimary: Colors.white,
  primaryContainer: Color(0xFFB3D4FF),
  onPrimaryContainer: Color(0xFF001A40),

  // Active / success
  secondary: Color(0xFF84CC16),
  onSecondary: Color(0xFF1E1E1E),
  secondaryContainer: Color(0xFFD6F0A0),
  onSecondaryContainer: Color(0xFF1E3500),

  // Warning / amber accent
  tertiary: Color(0xFFF59E0B),
  onTertiary: Colors.white,
  tertiaryContainer: Color(0xFFFFE0A0),
  onTertiaryContainer: Color(0xFF3A2A00),

  // Error / danger
  error: Color(0xFFEF4444),
  onError: Colors.white,
  errorContainer: Color(0xFFFFDAD4),
  onErrorContainer: Color(0xFF410002),

  // Surfaces (Flutter 3.22+ uses `surface` for both background & surface roles)
  surface: Color(0xFFFFFFFF),          // cards, dialogs, popups
  onSurface: Color(0xFF1A1A1A),       // primary text on any surface

  // Surface variants (replaces deprecated `surfaceVariant`)
  surfaceContainerHighest: Color(0xFFF0F0F0), // input fills, subtle backgrounds
  surfaceContainerHigh: Color(0xFFF8F8F8),
  surfaceContainerLow: Color(0xFFFAFAFA),

  // Text variants on surface
  onSurfaceVariant: Color(0xFF666666), // secondary text

  // Borders & shadows
  outline: Color(0xFFBDBDBD),
  outlineVariant: Color(0xFFE0E0E0),
  shadow: Color(0x1F000000),

  // Inverse
  inverseSurface: Color(0xFF333333),
  onInverseSurface: Colors.white,
  inversePrimary: Color(0xFFB3D4FF),
);

/// Dark mode palette — modern deep navy/slate.
const ColorScheme _darkColorScheme = ColorScheme.dark(
  // Brand
  primary: Color(0xFF0066CC),
  onPrimary: Colors.white,
  primaryContainer: Color(0xFF004A8C),
  onPrimaryContainer: Color(0xFFD6E8FF),

  // Active / success
  secondary: Color(0xFF84CC16),
  onSecondary: Color(0xFF1E1E1E),
  secondaryContainer: Color(0xFF3B5C00),
  onSecondaryContainer: Color(0xFFE6F5D0),

  // Warning / amber accent
  tertiary: Color(0xFFF59E0B),
  onTertiary: Colors.white,
  tertiaryContainer: Color(0xFF5C3A00),
  onTertiaryContainer: Color(0xFFFFE0A0),

  // Error / danger
  error: Color(0xFFEF4444),
  onError: Colors.white,
  errorContainer: Color(0xFF93000A),
  onErrorContainer: Color(0xFFFFDAD4),

  // Surfaces
  surface: Color(0xFF1A2332),          // cards, dialogs, popups
  onSurface: Colors.white,              // primary text

  // Surface variants
  surfaceContainerHighest: Color(0xFF243044), // input fills, subtle backgrounds
  surfaceContainerHigh: Color(0xFF1E2A3E),
  surfaceContainerLow: Color(0xFF161E30),

  // Text variants
  onSurfaceVariant: Color(0xFFB0B0B0), // secondary text

  // Borders & shadows
  outline: Color(0xFF3D4A5C),
  outlineVariant: Color(0xFF1A2538),
  shadow: Color(0x45000000),

  // Inverse
  inverseSurface: Color(0xFFF5F5F5),
  onInverseSurface: Color(0xFF1A1A1A),
  inversePrimary: Color(0xFF99CCFF),
);

/// Convenient access to constant source‑of‑truth scaffold backgrounds.
Color _lightScaffoldBg = const Color(0xFFF5F5F5);
Color _darkScaffoldBg  = const Color(0xFF0B1220);

// ═══════════════════════════════════════════════════════════════
// PART 2 — TYPOGRAPHY
// ═══════════════════════════════════════════════════════════════

class AppTypography {
  AppTypography._();

  static final TextTheme textTheme = GoogleFonts.interTextTheme();
}

// ═══════════════════════════════════════════════════════════════
// PART 3 — APP THEME
// ═══════════════════════════════════════════════════════════════

// Helpers shared by both light and dark builds.
const _radius = 8.0;

OutlinedBorder _shape() =>
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius));

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(
        colorScheme: _lightColorScheme,
        scaffoldBg: _lightScaffoldBg,
        isDark: false,
      );

  static ThemeData get dark => _build(
        colorScheme: _darkColorScheme,
        scaffoldBg: _darkScaffoldBg,
        isDark: true,
      );

  static ThemeData _build({
    required ColorScheme colorScheme,
    required Color scaffoldBg,
    required bool isDark,
  }) {
    final typography = GoogleFonts.interTextTheme().apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: typography,
      primaryTextTheme: typography,
      cardColor: colorScheme.surface,
      hintColor: colorScheme.onSurfaceVariant,
      disabledColor: colorScheme.onSurface.withValues(alpha: 0.38),
      dividerColor: colorScheme.outlineVariant,
    );

    return base.copyWith(
      // ── AppBar ──
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? colorScheme.surface : colorScheme.primary,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: typography.titleMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ── Input decoration ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: colorScheme.secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      ),

      // ── Elevated button ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: _shape(),
          textStyle: typography.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Text button ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: _shape(),
        ),
      ),

      // ── Outlined button ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: _shape(),
        ),
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titleTextStyle: typography.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ── Card ──
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: isDark ? 2 : 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(8),
      ),

      // ── Bottom navigation ──
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? scaffoldBg : colorScheme.surface,
        selectedItemColor: colorScheme.secondary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 4,
      ),

      // ── Drawer ──
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surface,
      ),

      // ── Divider ──
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),

      // ── Icon ──
      iconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: 24,
      ),

      // ── Checkbox ──
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.secondary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // ── Switch ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.secondary;
          return colorScheme.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.secondary.withValues(alpha: 0.5);
          }
          return colorScheme.outlineVariant;
        }),
      ),

      // ── Chip ──
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        labelStyle: TextStyle(color: colorScheme.onSurface),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // ── FAB ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // ── Popup menu ──
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 4,
      ),

      // ── Snackbar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        contentTextStyle: TextStyle(color: colorScheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Progress indicator ──
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.secondary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
      ),

      // ── Navigation rail ──
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? scaffoldBg : colorScheme.surface,
        selectedIconTheme: IconThemeData(color: colorScheme.secondary),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(color: colorScheme.secondary),
        unselectedLabelTextStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      ),

      // ── Tooltip ──
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: TextStyle(color: colorScheme.surface),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PART 4 — THEME CONTROLLER (ChangeNotifier)
// ═══════════════════════════════════════════════════════════════

/// Manages [ThemeMode] state with [SharedPreferences] persistence.
class ThemeController extends ChangeNotifier {
  static const _key = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.dark;

  /// The current theme mode.
  ThemeMode get themeMode => _themeMode;

  /// Returns `true` when dark mode is active.
  bool get isDark => _themeMode == ThemeMode.dark;

  /// Load persisted preference (called once at startup).
  Future<void> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key) ?? 'dark';
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => ThemeMode.dark,
      );
      notifyListeners();
    } catch (_) {
      // fallback to default
    }
  }

  /// Toggle between light and dark.
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    await _persist();
  }

  /// Set a specific mode.
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, _themeMode.name);
    } catch (_) {
      // ignore persistence failures
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// PART 5 — THEME PROVIDER (InheritedWidget)
// ═══════════════════════════════════════════════════════════════

/// Makes [ThemeController] accessible anywhere in the widget tree.
class ThemeProvider extends InheritedWidget {
  final ThemeController controller;

  const ThemeProvider({
    super.key,
    required this.controller,
    required super.child,
  });

  /// Retrieve the nearest [ThemeController] from the context.
  static ThemeController of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
    assert(provider != null, 'No ThemeProvider found in context');
    return provider!.controller;
  }

  @override
  bool updateShouldNotify(covariant ThemeProvider oldWidget) =>
      controller != oldWidget.controller;
}
