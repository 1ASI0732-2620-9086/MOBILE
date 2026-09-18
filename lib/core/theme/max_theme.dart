import 'package:flutter/material.dart';

abstract final class MaxColors {
  static const blue = Color(0xFF2F78E6);
  static const lightBlue = Color(0xFF5AA9F3);
  static const mediumBlue = Color(0xFF4B96F2);
  static const ink = Color(0xFF0B1A2A);
  static const paleBlue = Color(0xFFD8ECFF);
  static const canvas = Color(0xFFF2F7FF);
  static const border = Color(0xFFDBE7F6);
  static const darkBlue = Color(0xFF6FB0FF);
  static const darkPrimary = Color(0xFF4F9DFF);
  static const darkBorder = Color(0xFF1A3552);
  static const darkCanvas = Color(0xFF0F2033);
  static const darkSurface = Color(0xFF13263B);
  static const darkMuted = Color(0xFF26415F);
  static const success = Color(0xFF18B98B);
  static const danger = Color(0xFFE35D6A);
}

abstract final class MaxTheme {
  static ThemeData light({bool largeText = false}) => _build(
    brightness: Brightness.light,
    largeText: largeText,
    background: MaxColors.canvas,
    surface: Colors.white,
    border: MaxColors.border,
    primary: MaxColors.blue,
    text: MaxColors.ink,
  );

  static ThemeData dark({bool largeText = false}) => _build(
    brightness: Brightness.dark,
    largeText: largeText,
    background: MaxColors.darkCanvas,
    surface: MaxColors.darkSurface,
    border: MaxColors.darkBorder,
    primary: MaxColors.darkPrimary,
    text: const Color(0xFFEAF3FF),
  );

  static ThemeData _build({
    required Brightness brightness,
    required bool largeText,
    required Color background,
    required Color surface,
    required Color border,
    required Color primary,
    required Color text,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        surface: surface,
        error: MaxColors.danger,
      ),
      scaffoldBackgroundColor: background,
      fontFamily: 'Arial',
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: text,
        displayColor: text,
        fontSizeFactor: largeText ? 1.12 : 1,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: surface,
        foregroundColor: text,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      dividerColor: border,
    );
  }
}
