import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const lightBackground = Colors.white;
  static const lightSurface = Color(0xFFF5F7F7);
  static const background = Colors.black;
  static const surface = Color(0xFF151515);
  static const navigation = Color(0xFF171C20);
  static const amber = Color(0xFFE8B65A);
  static const danger = Color(0xFFE86B55);
  static const success = Color(0xFF7CC5A4);
  static const muted = Color(0xFF9AA3A8);
  static const lightPrimary = Colors.black;
  static const darkPrimary = Colors.white;

  static final dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: amber,
          brightness: Brightness.dark,
        ).copyWith(
          primary: darkPrimary,
          onPrimary: Colors.black,
          surface: surface,
          surfaceContainerHighest: const Color(0xFF202020),
        ),
    fontFamily: 'Arial',
  );

  static final light = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBackground,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF176B68),
          brightness: Brightness.light,
        ).copyWith(
          primary: lightPrimary,
          onPrimary: Colors.white,
          surface: lightSurface,
          surfaceContainerHighest: const Color(0xFFE9EEEE),
        ),
    fontFamily: 'Arial',
  );
}
