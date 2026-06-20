import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════
// PART 1 — BRAND COLORS (shared across light & dark)
// ═══════════════════════════════════════════════════════════════

class AppColors {
  AppColors._();

  // Primary
  static const Color primaryBlue = Color(0xFF0066CC);
  static const Color primaryGreen = Color(0xFF84CC16);

  // Semantic
  static const Color error   = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info    = Color(0xFF06B6D4);
  static const Color accent  = Color(0xFF8B5CF6);
}

// ═══════════════════════════════════════════════════════════════
// PART 2 — THEME-SPECIFIC PALETTES
// ═══════════════════════════════════════════════════════════════

/// Dark‑mode palette (inverted → light uses [AppColorsLight]).
class AppColorsDark {
  AppColorsDark._();

  static const Color background       = Color(0xFF0B1220);
  static const Color surface          = Color(0xFF1A2332);
  static const Color surfaceVariant   = Color(0xFF243044);
  static const Color onBackground     = Colors.white;
  static const Color onSurface        = Colors.white;
  static const Color onSurfaceVariant = Colors.white70;

  // Text opacity scale
  static const Color textPrimary   = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textHint      = Colors.white54;
  static const Color textTertiary  = Colors.white38;
  static const Color textDisabled  = Colors.white24;
  static const Color divider       = Colors.white12;

  // Component fills
  static const Color inputFill      = Color(0xFF151E2E);
  static const Color selectedTileBg = Color(0xFF243044);
}

/// Light‑mode palette (inverted from dark).
class AppColorsLight {
  AppColorsLight._();

  static const Color background       = Color(0xFFF5F5F5);
  static const Color surface          = Color(0xFFFFFFFF);
  static const Color surfaceVariant   = Color(0xFFEBEBEB);
  static const Color onBackground     = Color(0xFF1A1A1A);
  static const Color onSurface        = Color(0xFF1A1A1A);
  static const Color onSurfaceVariant = Color(0xFF666666);

  // Text opacity scale (Material default)
  static const Color textPrimary   = Color(0xDD000000); // black87
  static const Color textSecondary = Color(0x8A000000); // black54
  static const Color textHint      = Color(0x61000000); // black38
  static const Color textTertiary  = Color(0x42000000); // black26
  static const Color textDisabled  = Color(0x1F000000); // black12
  static const Color divider       = Color(0x1F000000); // black12

  // Component fills
  static const Color inputFill      = Color(0xFFF0F0F0);
  static const Color selectedTileBg = Color(0xFFE8F5D0);
}

// ═══════════════════════════════════════════════════════════════
// PART 3 — TYPOGRAPHY
// ═══════════════════════════════════════════════════════════════

class AppTypography {
  AppTypography._();

  static final TextTheme textTheme = GoogleFonts.interTextTheme();
}

// ═══════════════════════════════════════════════════════════════
// PART 4 — THEME DATA
// ═══════════════════════════════════════════════════════════════

class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildLight();
  static ThemeData get dark  => _buildDark();

  // ── helpers ──────────────────────────────────────────────────

  static const _radius = 8.0;

  static OutlinedBorder _shape() =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius));

  // ── LIGHT ────────────────────────────────────────────────────

  static ThemeData _buildLight() {
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      brightness: Brightness.light,
    ).copyWith(
      surface: AppColorsLight.surface,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColorsLight.background,
      textTheme: AppTypography.textTheme,
      primaryTextTheme: AppTypography.textTheme,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsLight.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: AppColorsLight.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: TextStyle(color: AppColorsLight.textHint),
        hintStyle: TextStyle(color: AppColorsLight.textHint),
      ),

      // Elevated button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColorsLight.onBackground,
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
          foregroundColor: AppColors.primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: _shape(),
        ),
      ),

      // Outlined button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          side: const BorderSide(color: AppColors.primaryBlue),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: _shape(),
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColorsLight.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
          color: AppColorsLight.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: AppColorsLight.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // Bottom navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColorsLight.surface,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColorsLight.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 4,
      ),

      // Drawer
      drawerTheme: DrawerThemeData(
        backgroundColor: AppColorsLight.surface,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: AppColorsLight.divider,
        thickness: 1,
      ),

      // Icon
      iconTheme: IconThemeData(
        color: AppColorsLight.onSurfaceVariant,
        size: 24,
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primaryGreen;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primaryGreen;
          return AppColorsLight.textHint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryGreen.withAlpha(80);
          }
          return AppColorsLight.divider;
        }),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColorsLight.surfaceVariant,
        labelStyle: TextStyle(color: AppColorsLight.onSurface),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Popup menu
      popupMenuTheme: PopupMenuThemeData(
        color: AppColorsLight.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 4,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorsLight.surfaceVariant,
        contentTextStyle: TextStyle(color: AppColorsLight.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      // Progress indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primaryGreen,
        linearTrackColor: AppColorsLight.surfaceVariant,
      ),

      // Navigation rail
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColorsLight.surface,
        selectedIconTheme: const IconThemeData(color: AppColors.primaryGreen),
        unselectedIconTheme: IconThemeData(color: AppColorsLight.textSecondary),
        selectedLabelTextStyle: TextStyle(color: AppColors.primaryGreen),
        unselectedLabelTextStyle: TextStyle(color: AppColorsLight.textSecondary),
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColorsLight.onSurface.withAlpha(230),
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: TextStyle(color: AppColorsLight.surface),
      ),
    );
  }

  // ── DARK ─────────────────────────────────────────────────────

  static ThemeData _buildDark() {
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.primaryGreen,
      brightness: Brightness.dark,
    ).copyWith(
      surface: AppColorsDark.surface,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColorsDark.background,
      textTheme: AppTypography.textTheme,
      primaryTextTheme: AppTypography.textTheme,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorsDark.background,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsDark.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: AppColorsDark.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: TextStyle(color: AppColorsDark.textHint),
        hintStyle: TextStyle(color: AppColorsDark.textHint),
      ),

      // Elevated button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColorsDark.onBackground,
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
          foregroundColor: AppColors.primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: _shape(),
        ),
      ),

      // Outlined button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          side: const BorderSide(color: AppColors.primaryGreen),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: _shape(),
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColorsDark.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
          color: AppColorsDark.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: AppColorsDark.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // Bottom navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColorsDark.background,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColorsDark.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 4,
      ),

      // Drawer
      drawerTheme: DrawerThemeData(
        backgroundColor: AppColorsDark.surface,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: AppColorsDark.divider,
        thickness: 1,
      ),

      // Icon
      iconTheme: IconThemeData(
        color: AppColorsDark.onSurfaceVariant,
        size: 24,
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primaryGreen;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primaryGreen;
          return AppColorsDark.textHint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryGreen.withAlpha(80);
          }
          return AppColorsDark.divider;
        }),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColorsDark.surfaceVariant,
        labelStyle: TextStyle(color: AppColorsDark.onSurface),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Popup menu
      popupMenuTheme: PopupMenuThemeData(
        color: AppColorsDark.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 4,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorsDark.surfaceVariant,
        contentTextStyle: TextStyle(color: AppColorsDark.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      // Progress indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primaryGreen,
        linearTrackColor: AppColorsDark.surfaceVariant,
      ),

      // Navigation rail
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColorsDark.background,
        selectedIconTheme: const IconThemeData(color: AppColors.primaryGreen),
        unselectedIconTheme: IconThemeData(color: AppColorsDark.textSecondary),
        selectedLabelTextStyle: TextStyle(color: AppColors.primaryGreen),
        unselectedLabelTextStyle: TextStyle(color: AppColorsDark.textSecondary),
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColorsDark.onSurface.withAlpha(230),
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: TextStyle(color: AppColorsDark.surface),
      ),
    );
  }
}
