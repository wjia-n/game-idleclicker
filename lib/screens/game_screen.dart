import 'package:flutter/material.dart';
import '../engine/idle_engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/clicker_art.dart';
import '../theme/clicker_themes.dart';

/// Game screen: the big tap toy, stats, upgrade shop, turbo mode and the
/// prestige ceremony. All state and timers live in [IdleEngine]; this
/// widget renders and forwards input only.
class GameScreen extends StatefulWidget {
  final ClickerAudio audio;
  final ClickerSettings settings;
  final IdleEngine engine;
  final StoreService store;
  final Future<void> Function() onReview;
  const GameScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.engine,
    required this.store,
    required this.onReview,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  IdleEngine get _e => widget.engine;
  ClickerThemeDef get _t => widget.settings.theme;

  double _pop = 0;
  final List<_FloatText> _floats = [];
  int _floatId = 0;
  EnginePhase _prevPhase = EnginePhase.running;
  bool _prevTurbo = false;
  bool _reviewAsked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _prevPhase = _e.phase;
    _prevTurbo = _e.turboActive;
    _e.addListener(_onEngine);
    // Grant offline earnings now — the welcome-back moment lands in-game.
    final earned = _e.noteResumed(
        offlineCapMultiplier: widget.settings.offlineCapMultiplier);
    if (earned > 0) widget.audio.win();
  }

  void _onEngine() {
    if (!mounted) return;
    // Milestone celebrations (engine queues them; UI toasts them once).
    final event = _e.takeMilestoneEvent();
    if (event != null) {
      widget.audio.milestone();
      final m = IdleEngine.milestones.firstWhere((x) => x.id == event);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🏆 ${m.title}! +${IdleEngine.fmt(m.bonus)} stardust',
              style: Clicker.body(15, theme: _t)),
          backgroundColor: _t.woodDeep,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    // Prestige ceremony finished.
    if (_prevPhase == EnginePhase.prestiging &&
        _e.phase == EnginePhase.running) {
      widget.audio.prestige();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '💥 Prestige ${_e.prestige}! +50% earnings forever.',
              style: Clicker.body(15, theme: _t)),
          backgroundColor: _t.woodDeep,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
    _prevPhase = _e.phase;
    // Turbo round ended — sensible moment to ask for a review once.
    if (_prevTurbo && !_e.turboActive) {
      widget.audio.turboEnd();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚡ Turbo over! ${_e.turboBest} taps best.',
              style: Clicker.body(15, theme: _t)),
          backgroundColor: _t.woodDeep,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (!_reviewAsked) {
        _reviewAsked = true;
        widget.onReview();
      }
    }
    _prevTurbo = _e.turboActive;
    // Buy flash: let the pop animation read, then clear it.
    if (_e.buyFlash != null) {
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted) _e.clearBuyFlash();
      });
    }
    if (_pop > 0) {
      Future.delayed(const Duration(milliseconds: 90), () {
        if (mounted) setState(() => _pop = 0);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _e.pauseForLifecycle();
      widget.settings.saveNow();
    } else if (state == AppLifecycleState.resumed) {
      final earned = _e.noteResumed(
          offlineCapMultiplier: widget.settings.offlineCapMultiplier);
      if (earned > 0) widget.audio.win();
    }
  }

  @override
  void dispose() {
    _e.removeListener(_onEngine);
    _e.clearWelcomeBack();
    WidgetsBinding.instance.removeObserver(this);
    widget.settings.saveNow();
    super.dispose();
  }

  void _tap(TapDownDetails d) {
    final before = _e.dust;
    _e.tap();
    if (_e.dust == before) return; // engine ignored it (wrong phase)
    widget.audio.tap();
    // Float the "+N" number at the real tap point (screen coordinates).
    final box = context.findRenderObject() as RenderBox?;
    final local = box != null
        ? box.globalToLocal(d.globalPosition)
        : d.localPosition;
    setState(() {
      _pop = 1.0;
      _floats.add(_FloatText(
        id: _floatId++,
        dx: local.dx - 24,
        dy: local.dy - 70,
        text:
            '+${IdleEngine.fmt(_e.tapPower * (_e.turboActive ? IdleEngine.turboTapMultiplier : 1))}',
      ));
      if (_floats.length > 12) _floats.removeAt(0);
    });
  }

  void _buy(String id) {
    if (_e.buy(id)) {
      widget.audio.buy();
    } else {
      widget.audio.invalid();
    }
  }

  void _confirmPrestige() {
    final t = _t;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => Dialog(
        backgroundColor: t.woodMid,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: t.accent, width: 2)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('💥', style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 8),
              Text('Go supernova?',
                  style: Clicker.display(22, theme: t)),
              const SizedBox(height: 8),
              Text(
                'Reset stardust and upgrades for prestige ${_e.prestige + 1}:\n+50% permanent earnings forever.\nMilestones and turbo best are kept.',
                style: Clicker.body(14, theme: t),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ChunkyButton(
                      label: 'Not yet',
                      theme: t,
                      width: 120,
                      height: 48,
                      onTap: () {
                        widget.audio.click();
                        Navigator.pop(c);
                      }),
                  ChunkyButton(
                      label: 'Prestige!',
                      theme: t,
                      width: 130,
                      height: 48,
                      onTap: () {
                        widget.audio.click();
                        Navigator.pop(c);
                        _e.startPrestige();
                      }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return ToyBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.accentLight),
            onPressed: () {
              widget.audio.click();
              widget.audio.startMenuMusic();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Idle Clicker', style: Clicker.display(20, theme: t)),
          centerTitle: true,
          actions: [
            if (widget.settings.isPro)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                    child: Text('✦ PRO',
                        style: Clicker.label(13, theme: t))),
              ),
          ],
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _e,
            builder: (_, _) => Stack(
              children: [
                Column(
                  children: [
                    // Stats.
                    Text('✨ ${IdleEngine.fmt(_e.dust)}',
                        style: Clicker.display(34, theme: t)),
                    Text(
                        '+${IdleEngine.fmt(_e.perSec)}/sec · tap ${IdleEngine.fmt(_e.tapPower)} · prestige ${_e.prestige}',
                        style: Clicker.body(12, theme: t)),
                    Text(
                        '${IdleEngine.tiers[_e.tierIndex].emoji} ${IdleEngine.tiers[_e.tierIndex].name} tier',
                        style: Clicker.label(12, theme: t)),
                    if (_e.turboActive)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: t.accent.withValues(alpha: 0.25),
                          border: Border.all(color: t.accentLight),
                        ),
                        child: Text(
                            '⚡ TURBO ×5 — ${_e.turboSecondsLeft}s',
                            style: Clicker.label(14, theme: t)),
                      ),
                    if (_e.welcomeBackEarnings != null)
                      GestureDetector(
                        onTap: () {
                          widget.audio.click();
                          _e.clearWelcomeBack();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: t.felt.withValues(alpha: 0.9),
                            border: Border.all(color: t.accent),
                          ),
                          child: Text(
                            '🌙 While you were away: +${IdleEngine.fmt(_e.welcomeBackEarnings!)} (tap to dismiss)',
                            style: Clicker.body(13, theme: t),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    // Tap toy.
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: GestureDetector(
                          onTapDown: _tap,
                          child: AnimatedScale(
                            scale: _pop > 0 ? 1.12 : 1.0,
                            duration:
                                const Duration(milliseconds: 90),
                            child: _TapToy(
                                theme: t,
                                styleId: widget.settings.tapStyleId),
                          ),
                        ),
                      ),
                    ),
                    // Shop.
                    Expanded(
                      flex: 5,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          for (final u in IdleEngine.upgrades)
                            _shopCard(t, u),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: ChunkyButton(
                                  label: _e.turboActive
                                      ? 'Turbo…'
                                      : '⚡ Turbo (30s)',
                                  theme: t,
                                  height: 50,
                                  enabled: !_e.turboActive &&
                                      _e.phase ==
                                          EnginePhase.running,
                                  onTap: () {
                                    widget.audio.turboStart();
                                    _e.startTurbo();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ChunkyButton(
                                  label:
                                      '💥 Prestige (${IdleEngine.fmt(IdleEngine.prestigeLifetimeNeeded)})',
                                  theme: t,
                                  height: 50,
                                  enabled: _e.canPrestige,
                                  onTap: _e.canPrestige
                                      ? _confirmPrestige
                                      : () {},
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
                // Floating tap numbers.
                for (final f in _floats)
                  _FloatingNumber(
                    key: ValueKey(f.id),
                    theme: t,
                    dx: f.dx,
                    dy: f.dy,
                    text: f.text,
                    onDone: () {
                      if (mounted) {
                        setState(() => _floats
                            .removeWhere((x) => x.id == f.id));
                      }
                    },
                  ),
                // Prestige ceremony overlay (engine-staged).
                if (_e.phase == EnginePhase.prestiging)
                  _PrestigeOverlay(theme: t, stage: _e.prestigeStage),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _shopCard(ClickerThemeDef t, UpgradeDef u) {
    final unlocked = _e.upgradeUnlocked(u.id);
    final cost = _e.upgradeCost(u.id);
    final afford = _e.canAfford(u.id);
    final owned = _e.owned[u.id] ?? 0;
    final flashing = _e.buyFlash == u.id;
    return AnimatedScale(
      scale: flashing ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: Opacity(
        opacity: unlocked ? 1.0 : 0.5,
        child: ToyPanel(
          theme: t,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Text(u.emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${u.name} ×$owned',
                        style: Clicker.label(14, theme: t)),
                    Text(
                        unlocked
                            ? '${u.desc} · ✨ ${IdleEngine.fmt(cost)}'
                            : '🔒 Unlocks at ${IdleEngine.tiers[u.unlockTier].name} tier',
                        style: Clicker.body(11, theme: t)),
                  ],
                ),
              ),
              ChunkyButton(
                label: 'Buy',
                theme: t,
                width: 84,
                height: 42,
                enabled: unlocked && afford,
                onTap: () => _buy(u.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatText {
  final int id;
  final double dx;
  final double dy;
  final String text;
  _FloatText(
      {required this.id,
      required this.dx,
      required this.dy,
      required this.text});
}

class _FloatingNumber extends StatelessWidget {
  final ClickerThemeDef theme;
  final double dx;
  final double dy;
  final String text;
  final VoidCallback onDone;
  const _FloatingNumber({
    super.key,
    required this.theme,
    required this.dx,
    required this.dy,
    required this.text,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: dx.clamp(0, 300),
      top: dy.clamp(0, 500),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 800),
        onEnd: onDone,
        builder: (_, v, __) => Opacity(
          opacity: 1 - v,
          child: Transform.translate(
            offset: Offset(0, -60 * v),
            child: Text(text,
                style: Clicker.label(18,
                    theme: theme, color: theme.accentLight)),
          ),
        ),
      ),
    );
  }
}

/// The big tap toy: chunky wooden disc with brass rim, themed by the
/// player's chosen tap style.
class _TapToy extends StatelessWidget {
  final ClickerThemeDef theme;
  final String styleId;
  const _TapToy({required this.theme, required this.styleId});

  @override
  Widget build(BuildContext context) {
    final style = TapStyles.byId(styleId);
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.starFace, theme.starEdge],
        ),
        border: Border.all(color: theme.accent, width: 6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            offset: const Offset(0, 10),
            blurRadius: 22,
          ),
          BoxShadow(
            color: theme.accentLight.withValues(alpha: 0.35),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Center(
        child: Text(
          style.emoji,
          style: TextStyle(
            fontSize: 88,
            shadows: [
              Shadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen staged prestige ceremony, driven by engine.prestigeStage.
class _PrestigeOverlay extends StatelessWidget {
  final ClickerThemeDef theme;
  final int stage;
  const _PrestigeOverlay({required this.theme, required this.stage});

  @override
  Widget build(BuildContext context) {
    const stages = [
      '🌌 Gathering all your stardust…',
      '⭐ The star is swelling…',
      '💥 SUPERNOVA!',
      '🌠 A new universe forms…',
    ];
    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1.0 + stage * 0.25),
              duration: const Duration(milliseconds: 500),
              builder: (_, s, __) => Transform.scale(
                scale: s,
                child: Text('💥', style: const TextStyle(fontSize: 90)),
              ),
            ),
            const SizedBox(height: 16),
            Text(stages[stage.clamp(0, 3)],
                style: Clicker.display(22, theme: theme),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: (stage + 1) / 4,
                backgroundColor:
                    Colors.white.withValues(alpha: 0.15),
                color: theme.accentLight,
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
