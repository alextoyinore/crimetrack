import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const background = Color(0xFF101418);
  static const surface = Color(0xFF1A2025);
  static const navigation = Color(0xFF171C20);
  static const amber = Color(0xFFE8B65A);
  static const danger = Color(0xFFE86B55);
  static const success = Color(0xFF7CC5A4);
  static const muted = Color(0xFF9AA3A8);

  static final dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: amber,
      brightness: Brightness.dark,
    ),
    fontFamily: 'Arial',
  );
}
