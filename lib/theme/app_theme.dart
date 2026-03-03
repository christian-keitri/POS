import 'package:flutter/material.dart';

/// Reusable app colors and font sizes for a consistent, sleek POS UI.
/// Change these once to update the whole app.
class AppTheme {
  AppTheme._();

  // ─── Colors ─────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFD4A017); // Refined gold accent
  static const Color primaryDark = Color(0xFFB8860B); // Darker gold (hover/pressed)
  static const Color appBarBackground = Color(0xFF0F172A); // Slate 900 – sleek dark
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF8FAFC); // Slate 50
  static const Color background = Color(0xFFF1F5F9); // Slate 100
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);

  // ─── Font sizes ──────────────────────────────────────────────────────────
  static const double fontSizeDisplay = 28.0; // Hero / splash titles
  static const double fontSizeTitle = 22.0;   // Screen titles, card titles
  static const double fontSizeHeading = 18.0; // Section headings
  static const double fontSizeBody = 16.0;   // Body text, buttons
  static const double fontSizeCaption = 14.0; // Labels, captions
  static const double fontSizeSmall = 12.0;  // Nav labels, hints

  // ─── Text styles (use theme font sizes & colors) ─────────────────────────
  static TextStyle get displayStyle => const TextStyle(
        fontSize: fontSizeDisplay,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get titleStyle => const TextStyle(
        fontSize: fontSizeTitle,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get headingStyle => const TextStyle(
        fontSize: fontSizeHeading,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get bodyStyle => const TextStyle(
        fontSize: fontSizeBody,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      );

  static TextStyle get bodySecondaryStyle => const TextStyle(
        fontSize: fontSizeBody,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      );

  static TextStyle get captionStyle => const TextStyle(
        fontSize: fontSizeCaption,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      );

  static TextStyle get smallStyle => const TextStyle(
        fontSize: fontSizeSmall,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      );

  /// ThemeData for MaterialApp – uses AppTheme colors and typography.
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: surface,
        error: error,
        onPrimary: textPrimary,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarBackground,
        foregroundColor: surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: fontSizeHeading,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeBody,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: textSecondary, fontSize: fontSizeBody),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: appBarBackground,
        contentTextStyle: const TextStyle(
          fontSize: fontSizeBody,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 6,
        showCloseIcon: true,
        closeIconColor: Colors.white70,
      ),
    );
  }
}

/// Sleek snackbars with optional type (success / error) and consistent styling.
class AppSnackBar {
  AppSnackBar._();

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    final theme = Theme.of(context).snackBarTheme;
    final backgroundColor = isError
        ? AppTheme.error
        : isSuccess
            ? AppTheme.success
            : (theme.backgroundColor ?? AppTheme.appBarBackground);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (isError || isSuccess) ...[
              Icon(
                isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: theme.contentTextStyle?.copyWith(color: Colors.white) ??
                    const TextStyle(color: Colors.white, fontSize: AppTheme.fontSizeBody),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        elevation: 6,
        showCloseIcon: true,
        closeIconColor: Colors.white70,
      ),
    );
  }

  static void success(BuildContext context, String message) =>
      show(context, message, isSuccess: true);

  static void error(BuildContext context, String message) =>
      show(context, message, isError: true);
}
