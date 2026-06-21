import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════
// PART 1 — COLOR SCHEMES (explicit semantic colors)
// ═══════════════════════════════════════════════════════════════

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

  // Surfaces
  background: Color(0xFFF5F5F5),       // scaffold
  onBackground: Color(0xFF1A1A1A),     // primary text
  surface: Color(0xFFFFFFFF),          // cards, dialogs
  onSurface: Color(0xFF1A1A1A),       // primary text

  // Variants
  surfaceVariant: Color(0xFFF0F0F0),   // input fills, subtle backgrounds
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
  background: Color(0xFF0B1220),       // scaffold
  onBackground: Colors.white,           // primary text
  surface: Color(0xFF1A2332),          // cards, dialogs
  onSurface: Colors.white,              // primary text

  // Variants
  surfaceVariant: Color(0xFF243044),    // input fills, subtle backgrounds
  onSurfaceVariant: Color(0xFFB0B0B0), // secondary text

  // Borders & shadows
  outline: Color(0xFF3D4A5C),
  outlineVariant: Color(0xFF1A2538),   // subtle divider
  shadow: Color(0x45000000),

  // Inverse
  inverseSurface: Color(0xFFF5F5F5),
  onInverseSurface: Color(0xFF1A1A1A),
  inversePrimary: Color(0xFF99CCFF),
);

// ═══════════════════════════════════════════════════════════════
// PART 2 — TYPOGRAPHY
// ═══════════════════════════════════════════════════════════════

class AppTypography {
  AppTypography._();

  static final TextTheme textTheme = GoogleFonts.interTextTheme();
}

// ═══════════════════════════════════════════════════════════════
// PART 3 — APP THEME (builds ThemeData from ColorSchemes)
// ═══════════════════════════════════════════════════════════════

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(_lightColorScheme, _LightComponentTheme.build);
  static ThemeData get dark  => _build(_darkColorScheme, _DarkComponentTheme.build);

  static ThemeData _build(ColorScheme cs, ThemeData Function(ColorScheme) components) {
    final typography = GoogleFonts.interTextTheme().apply(
      bodyColor: cs.onSurface,
      displayColor: cs.onSurface,
    );

    return components(cs).copyWith(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.background,
      textTheme: typography,
      primaryTextTheme: typography,
      // Derive common semantic colors from the ColorScheme
      cardColor: cs.surface,
      hintColor: cs.onSurfaceVariant,
      disabledColor: cs.onSurface.withValues(alpha: 0.38),
      dividerColor: cs.outlineVariant,
      indicatorColor: cs.secondary,
    );
  }
}

// ── Component theme overrides ──────────────────────────────────

mixin _ComponentTheme {
  static const _radius = 8.0;

  static OutlinedBorder _shape() =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius));
}

class _LightComponentTheme with _ComponentTheme {
  static ThemeData build(ColorScheme cs) => ThemeData(
    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.textTheme.titleMedium?.copyWith(
        color: cs.onPrimary,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Input decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cs.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: cs.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: cs.secondary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: cs.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: cs.error, width: 2),
      ),
      labelStyle: TextStyle(color: cs.onSurfaceVariant),
      hintStyle: TextStyle(color: cs.onSurfaceVariant),
    ),

    // Elevated button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: cs.secondary,
        foregroundColor: cs.onSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: _shape(),
        textStyle: AppTypography.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Text button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: cs.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: _shape(),
      ),
    ),

    // Outlined button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.primary,
        side: BorderSide(color: cs.primary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: _shape(),
      ),
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
        color: cs.onSurface,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Card
    cardTheme: CardThemeData(
      color: cs.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(8),
    ),

    // Bottom navigation
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: cs.surface,
      selectedItemColor: cs.secondary,
      unselectedItemColor: cs.onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      elevation: 4,
    ),

    // Drawer
    drawerTheme: DrawerThemeData(
      backgroundColor: cs.surface,
    ),

    // Divider
    dividerTheme: DividerThemeData(
      color: cs.outlineVariant,
      thickness: 1,
    ),

    // Icon
    iconTheme: IconThemeData(
      color: cs.onSurfaceVariant,
      size: 24,
    ),

    // Checkbox
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return cs.secondary;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return cs.secondary;
        return cs.onSurfaceVariant;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return cs.secondary.withValues(alpha: 0.5);
        return cs.outlineVariant;
      }),
    ),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: cs.surfaceVariant,
      labelStyle: TextStyle(color: cs.onSurface),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    // FAB
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Popup menu
    popupMenuTheme: PopupMenuThemeData(
      color: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 4,
    ),

    // Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: cs.surfaceVariant,
      contentTextStyle: TextStyle(color: cs.onSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),

    // Progress indicator
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: cs.secondary,
      linearTrackColor: cs.surfaceVariant,
    ),

    // Navigation rail
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: cs.surface,
      selectedIconTheme: IconThemeData(color: cs.secondary),
      unselectedIconTheme: IconThemeData(color: cs.onSurfaceVariant),
      selectedLabelTextStyle: TextStyle(color: cs.secondary),
      unselectedLabelTextStyle: TextStyle(color: cs.onSurfaceVariant),
    ),

    // Tooltip
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: TextStyle(color: cs.surface),
    ),
  );
}

class _DarkComponentTheme with _ComponentTheme {
  static ThemeData build(ColorScheme cs) => ThemeData(
    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: cs.background,
      foregroundColor: cs.onBackground,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.textTheme.titleMedium?.copyWith(
        color: cs.onBackground,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Input decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cs.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: cs.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: cs.secondary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: cs.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: cs.error, width: 2),
      ),
      labelStyle: TextStyle(color: cs.onSurfaceVariant),
      hintStyle: TextStyle(color: cs.onSurfaceVariant),
    ),

    // Elevated button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: cs.secondary,
        foregroundColor: cs.onSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: _shape(),
        textStyle: AppTypography.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Text button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: cs.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: _shape(),
      ),
    ),

    // Outlined button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.secondary,
        side: BorderSide(color: cs.secondary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: _shape(),
      ),
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
        color: cs.onSurface,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Card
    cardTheme: CardThemeData(
      color: cs.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(8),
    ),

    // Bottom navigation
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: cs.background,
      selectedItemColor: cs.secondary,
      unselectedItemColor: cs.onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      elevation: 4,
    ),

    // Drawer
    drawerTheme: DrawerThemeData(
      backgroundColor: cs.surface,
    ),

    // Divider
    dividerTheme: DividerThemeData(
      color: cs.outlineVariant,
      thickness: 1,
    ),

    // Icon
    iconTheme: IconThemeData(
      color: cs.onSurfaceVariant,
      size: 24,
    ),

    // Checkbox
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return cs.secondary;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return cs.secondary;
        return cs.onSurfaceVariant;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return cs.secondary.withValues(alpha: 0.5);
        return cs.outlineVariant;
      }),
    ),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: cs.surfaceVariant,
      labelStyle: TextStyle(color: cs.onSurface),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    // FAB
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Popup menu
    popupMenuTheme: PopupMenuThemeData(
      color: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 4,
    ),

    // Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: cs.surfaceVariant,
      contentTextStyle: TextStyle(color: cs.onSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),

    // Progress indicator
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: cs.secondary,
      linearTrackColor: cs.surfaceVariant,
    ),

    // Navigation rail
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: cs.background,
      selectedIconTheme: IconThemeData(color: cs.secondary),
      unselectedIconTheme: IconThemeData(color: cs.onSurfaceVariant),
      selectedLabelTextStyle: TextStyle(color: cs.secondary),
      unselectedLabelTextStyle: TextStyle(color: cs.onSurfaceVariant),
    ),

    // Tooltip
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: TextStyle(color: cs.surface),
    ),
  );
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
