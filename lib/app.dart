import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'features/splash/presentation/splash_page.dart';

class CrimeTrackApp extends StatefulWidget {
  const CrimeTrackApp({super.key});

  @override
  State<CrimeTrackApp> createState() => _CrimeTrackAppState();
}

class _CrimeTrackAppState extends State<CrimeTrackApp> {
  static const _themeKey = 'crimetrack.theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_themeKey);
    if (!mounted || value == null) return;
    setState(() => _themeMode = ThemeMode.values.byName(value));
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeKey, mode.name);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CrimeTrack',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: _themeMode,
    home: SplashPage(onThemeModeChanged: _setThemeMode, themeMode: _themeMode),
  );
}
