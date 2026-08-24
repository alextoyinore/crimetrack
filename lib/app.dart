import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/onboarding_page.dart';

class CrimeTrackApp extends StatelessWidget {
  const CrimeTrackApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CrimeTrack',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    home: const OnboardingGate(),
  );
}
