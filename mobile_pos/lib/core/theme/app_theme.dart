import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────────
///  KrubKrong ERP – Design System
///  Brand primary: #001f84
///  Inspired by: Linear, Stripe, Vercel, Notion
/// ─────────────────────────────────────────────
abstract class AppTheme {
  AppTheme._();

  // ── Brand ──────────────────────────────────
  /// Primary brand blue – used for CTAs, active states, links
  static const Color primary = Color(0xFF001F84);

  /// Slightly lighter variant for dark-mode primary text/icons
  static const Color primaryLight = Color(0xFF3D5FC4);

  /// Soft tinted container (light mode badge backgrounds, chip fills)
  static const Color primaryContainer = Color(0xFFDDE4FF);

  /// Text on top of primaryContainer
  static const Color onPrimaryContainer = Color(0xFF001366);

  // ── Semantic ───────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color successSurface = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningSurface = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorSurface = Color(0xFFFFEDED);
  static const Color info = Color(0xFF0284C7);
  static const Color infoSurface = Color(0xFFE0F2FE);

  // ── Light Mode Surfaces ────────────────────
  /// Page background – barely-off-white, reduces eye strain
  static const Color lightBg = Color(0xFFF5F7FA);

  /// Card / sheet surface
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// Subtle fill for inputs, chips, secondary cards
  static const Color lightFill = Color(0xFFF0F2F7);

  /// Border / divider stroke
  static const Color lightBorder = Color(0xFFE2E6EF);

  // ── Light Mode Text ────────────────────────
  static const Color lightTextPrimary = Color(0xFF0D1117);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightTextDisabled = Color(0xFFB0B7C3);

  // ── Dark Mode Surfaces ─────────────────────
  /// Page background – deep navy, complements brand blue
  static const Color darkBg = Color(0xFF0C0F1A);

  /// Card / elevated surface
  static const Color darkSurface = Color(0xFF141827);

  /// Higher-elevation card
  static const Color darkCard = Color(0xFF1C2236);

  /// Border / divider in dark mode
  static const Color darkBorder = Color(0xFF252D45);

  // ── Dark Mode Text ─────────────────────────
  static const Color darkTextPrimary = Color(0xFFF1F4FF);
  static const Color darkTextSecondary = Color(0xFF8891AA);
  static const Color darkTextDisabled = Color(0xFF404868);

  // ── Typography ─────────────────────────────
  static TextTheme get _base => GoogleFonts.interTextTheme();

  static TextTheme get textTheme => _base.copyWith(
        displayLarge: _base.displayLarge?.copyWith(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.8),
        displayMedium: _base.displayMedium?.copyWith(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.6),
        displaySmall: _base.displaySmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.4),
        headlineLarge: _base.headlineLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.3),
        headlineMedium: _base.headlineMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.2),
        headlineSmall: _base.headlineSmall?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        titleLarge: _base.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
        titleMedium: _base.titleMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0),
        titleSmall: _base.titleSmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
        bodyLarge: _base.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.6),
        bodyMedium: _base.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
        bodySmall: _base.bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w400, height: 1.5),
        labelLarge: _base.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
        labelMedium: _base.labelMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: _base.labelSmall?.copyWith(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.5),
      );

  // ──────────────────────────────────────────
  //  LIGHT THEME
  // ──────────────────────────────────────────
  static ThemeData get lightTheme {
    const scheme = ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: success,
      onSecondary: Colors.white,
      secondaryContainer: successSurface,
      onSecondaryContainer: Color(0xFF14532D),
      tertiary: info,
      onTertiary: Colors.white,
      tertiaryContainer: infoSurface,
      onTertiaryContainer: Color(0xFF0C4A6E),
      error: error,
      onError: Colors.white,
      errorContainer: errorSurface,
      onErrorContainer: Color(0xFF7F1D1D),
      surface: lightSurface,
      onSurface: lightTextPrimary,
      surfaceContainerHighest: lightFill,
      onSurfaceVariant: lightTextSecondary,
      outline: lightBorder,
      outlineVariant: Color(0xFFEDF0F7),
      shadow: Color(0x14000000),
      scrim: Color(0x33000000),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: lightBg,
      textTheme: textTheme,

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        backgroundColor: lightSurface,
        foregroundColor: lightTextPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x14000000),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: lightTextPrimary,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: lightTextPrimary, size: 22),
        actionsIconTheme: const IconThemeData(color: lightTextSecondary, size: 22),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        color: lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Buttons – Elevated
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFCDD3EF),
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // Buttons – Outlined
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: const BorderSide(color: lightBorder, width: 1.5),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // Buttons – Text
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: error, width: 1.8),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: lightTextSecondary),
        hintStyle: textTheme.bodyMedium?.copyWith(color: lightTextDisabled),
        errorStyle: textTheme.bodySmall?.copyWith(color: error, fontWeight: FontWeight.w500),
        prefixIconColor: lightTextSecondary,
        suffixIconColor: lightTextSecondary,
      ),

      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x14000000),
        elevation: 0,
        height: 64,
        indicatorColor: primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 22);
          }
          return const IconThemeData(color: lightTextSecondary, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall?.copyWith(color: primary, fontWeight: FontWeight.w700);
          }
          return textTheme.labelSmall?.copyWith(color: lightTextSecondary);
        }),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: lightFill,
        selectedColor: primaryContainer,
        labelStyle: textTheme.labelMedium?.copyWith(color: lightTextPrimary),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: primary),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: lightBorder),
        ),
        side: const BorderSide(color: lightBorder),
      ),

      // Divider
      dividerTheme: const DividerThemeData(color: lightBorder, thickness: 1, space: 1),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: lightTextPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),

      // FAB
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: StadiumBorder(),
      ),

      // Switch, Checkbox, Radio
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? primary : Colors.transparent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: lightBorder, width: 1.5),
      ),

      // List tile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titleTextStyle: textTheme.titleMedium?.copyWith(color: lightTextPrimary),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(color: lightTextSecondary),
        iconColor: lightTextSecondary,
      ),

      // Progress indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
    );
  }

  // ──────────────────────────────────────────
  //  DARK THEME
  // ──────────────────────────────────────────
  static ThemeData get darkTheme {
    const scheme = ColorScheme.dark(
      primary: primaryLight,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF162057),
      onPrimaryContainer: Color(0xFFBECAFF),
      secondary: Color(0xFF4ADE80),
      onSecondary: Color(0xFF052E16),
      secondaryContainer: Color(0xFF14532D),
      onSecondaryContainer: Color(0xFFBBF7D0),
      tertiary: Color(0xFF38BDF8),
      onTertiary: Color(0xFF0C4A6E),
      tertiaryContainer: Color(0xFF0C2D4A),
      onTertiaryContainer: Color(0xFFBAE6FD),
      error: Color(0xFFF87171),
      onError: Color(0xFF450A0A),
      errorContainer: Color(0xFF7F1D1D),
      onErrorContainer: Color(0xFFFECACA),
      surface: darkSurface,
      onSurface: darkTextPrimary,
      surfaceContainerHighest: darkCard,
      onSurfaceVariant: darkTextSecondary,
      outline: darkBorder,
      outlineVariant: Color(0xFF1E2640),
      shadow: Color(0x3F000000),
      scrim: Color(0x66000000),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: darkBg,
      textTheme: textTheme.apply(
        bodyColor: darkTextPrimary,
        displayColor: darkTextPrimary,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black26,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: darkTextPrimary,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: darkTextPrimary, size: 22),
        actionsIconTheme: const IconThemeData(color: darkTextSecondary, size: 22),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Buttons – Elevated
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF1C2236),
          disabledForegroundColor: darkTextDisabled,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // Buttons – Outlined
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: const BorderSide(color: darkBorder, width: 1.5),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // Buttons – Text
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryLight, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFF87171), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFF87171), width: 1.8),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: darkTextSecondary),
        hintStyle: textTheme.bodyMedium?.copyWith(color: darkTextDisabled),
        errorStyle: textTheme.bodySmall?.copyWith(color: Color(0xFFF87171), fontWeight: FontWeight.w500),
        prefixIconColor: darkTextSecondary,
        suffixIconColor: darkTextSecondary,
      ),

      // Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black26,
        elevation: 0,
        height: 64,
        indicatorColor: const Color(0xFF162057),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryLight, size: 22);
          }
          return const IconThemeData(color: darkTextSecondary, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall?.copyWith(color: primaryLight, fontWeight: FontWeight.w700);
          }
          return textTheme.labelSmall?.copyWith(color: darkTextSecondary);
        }),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: darkCard,
        selectedColor: const Color(0xFF162057),
        labelStyle: textTheme.labelMedium?.copyWith(color: darkTextPrimary),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: primaryLight),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: darkBorder),
        ),
        side: const BorderSide(color: darkBorder),
      ),

      // Divider
      dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1, space: 1),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkCard,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: darkTextPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkBorder),
        ),
        elevation: 4,
      ),

      // FAB
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: StadiumBorder(),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? primaryLight : Colors.transparent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: darkBorder, width: 1.5),
      ),

      // List tile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titleTextStyle: textTheme.titleMedium?.copyWith(color: darkTextPrimary),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(color: darkTextSecondary),
        iconColor: darkTextSecondary,
      ),

      // Progress indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primaryLight),
    );
  }
}
