import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../shell/presentation/shell.dart';

class OnboardingGate extends StatefulWidget {
  const OnboardingGate({
    super.key,
    required this.onThemeModeChanged,
    required this.themeMode,
  });

  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ThemeMode themeMode;

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  static const _completeKey = 'crimetrack.onboarding_complete';
  bool? _complete;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final preferences = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _complete = preferences.getBool(_completeKey) ?? false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_complete == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _complete!
        ? Shell(
            onThemeModeChanged: widget.onThemeModeChanged,
            themeMode: widget.themeMode,
          )
        : OnboardingPage(
            onThemeModeChanged: widget.onThemeModeChanged,
            themeMode: widget.themeMode,
          );
  }
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.onThemeModeChanged,
    required this.themeMode,
  });

  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ThemeMode themeMode;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _completeKey = 'crimetrack.onboarding_complete';
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _OnboardingSlide(
      icon: Icons.radar_rounded,
      title: 'Know what is happening nearby',
      description:
          'See verified incidents and risk areas across your community in one clear view.',
      color: AppTheme.amber,
    ),
    _OnboardingSlide(
      icon: Icons.add_alert_rounded,
      title: 'Report what you see',
      description:
          'Share an incident with its location, details, and optional evidence to help others stay informed.',
      color: AppTheme.danger,
    ),
    _OnboardingSlide(
      icon: Icons.shield_rounded,
      title: 'Stay prepared',
      description:
          'Use the safety hub for emergency contacts and quick access when every second matters.',
      color: AppTheme.success,
    ),
  ];

  Future<void> _finish() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_completeKey, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => Shell(
          onThemeModeChanged: widget.onThemeModeChanged,
          themeMode: widget.themeMode,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: _finish, child: const Text('Skip')),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (_, index) => _SlideView(slide: _slides[index]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Row(
              children: [
                Row(
                  children: List.generate(
                    _slides.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 6),
                      width: index == _page ? 24 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: index == _page
                            ? AppTheme.amber
                            : const Color(0xFF465158),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    if (_page == _slides.length - 1) {
                      _finish();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Text(
                    _page == _slides.length - 1 ? 'Get started' : 'Continue',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String description;
  final Color color;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 34),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 148,
          height: 148,
          decoration: BoxDecoration(
            color: slide.color.withAlpha(30),
            shape: BoxShape.circle,
            border: Border.all(color: slide.color.withAlpha(120), width: 2),
          ),
          child: Icon(slide.icon, size: 72, color: slide.color),
        ),
        const SizedBox(height: 42),
        Text(
          slide.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          slide.description,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 15,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}
