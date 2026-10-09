import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/clicker_art.dart';
import 'menu_screen.dart';

/// SINGLE launch splash, two moments in one screen:
/// 1. WAJIHA company moment — the official winged-W logo, copied untouched
///    into assets (never redrawn or altered).
/// 2. Game splash — original game logo + name, animated loading line,
///    and the "Credits: WAJIHA" line with the company logo.
///
/// Audio is prewarmed during the company moment and menu music starts
/// behind the splash.
class SplashScreen extends StatefulWidget {
  final ClickerAudio audio;
  final ClickerSettings settings;
  final Map<String, dynamic> engineJson;
  const SplashScreen(
      {super.key,
      required this.audio,
      required this.settings,
      required this.engineJson});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;
  bool _companyDone = false;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _run();
  }

  Future<void> _run() async {
    // Pre-warm audio and start menu music during the company moment.
    widget.audio.prewarm();
    widget.audio.startMenuMusic();
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _companyDone = true);
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
          engineJson: widget.engineJson,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_companyDone) return _buildCompanyMoment();
    return _buildGameSplash();
  }

  /// Moment 1: the official WAJIHA company logo, untouched.
  Widget _buildCompanyMoment() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1.0),
          duration: const Duration(milliseconds: 1200),
          builder: (_, s, __) => Transform.scale(
            scale: s,
            child: Opacity(
              opacity: ((s - 0.85) / 0.15).clamp(0.0, 1.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/wajiha_logo.png',
                    width: 170,
                    height: 170,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'WAJIHA',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 10,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Moment 2: game splash — logo, name, animated loading line, credits.
  Widget _buildGameSplash() {
    final theme = widget.settings.theme;
    return Scaffold(
      backgroundColor: const Color(0xFF241309),
      body: ToyBackdrop(
        theme: theme,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: theme.accent, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      offset: const Offset(0, 10),
                      blurRadius: 24,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset('assets/idle_logo.png', fit: BoxFit.cover),
              ),
              const SizedBox(height: 22),
              Text('Idle Clicker', style: Clicker.display(46, theme: theme)),
              const SizedBox(height: 6),
              Text(
                'STARFALL TAPPERS',
                style: Clicker.label(13, theme: theme),
              ),
              const SizedBox(height: 30),
              // Animated loading line.
              SizedBox(
                width: 220,
                child: AnimatedBuilder(
                  animation: _loader,
                  builder: (_, _) => Column(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: Colors.black.withValues(alpha: 0.45),
                          border: Border.all(
                              color: theme.accent.withValues(alpha: 0.5)),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _loader.value.clamp(0.02, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              gradient: LinearGradient(
                                colors: [
                                  theme.accentLight,
                                  theme.accent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _loader.value < 1
                            ? 'Winding up the tap toy…'
                            : 'Ready!',
                        style: Clicker.body(13,
                            theme: theme,
                            color: theme.paper.withValues(alpha: 0.75)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 44),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/wajiha_logo.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Credits: WAJIHA',
                    style: Clicker.label(14, theme: theme),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
