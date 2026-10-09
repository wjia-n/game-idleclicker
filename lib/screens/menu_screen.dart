import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import '../engine/idle_engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/clicker_art.dart';
import '../theme/clicker_themes.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';
import 'theme_screen.dart';

/// Main menu: profile, Play, tier ladder, milestones, turbo best,
/// theme/settings/Pro/share/rate actions.
class MenuScreen extends StatefulWidget {
  final ClickerAudio audio;
  final ClickerSettings settings;
  final Map<String, dynamic> engineJson;
  const MenuScreen(
      {super.key,
      required this.audio,
      required this.settings,
      required this.engineJson});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late final StoreService _store;
  late final IdleEngine _engine;
  final _nameCtrl = TextEditingController();

  ClickerThemeDef get _t => widget.settings.theme;

  @override
  void initState() {
    super.initState();
    _store = StoreService();
    _store.init();
    _store.proPurchased.addListener(_onPro);
    _store.lastThanks.addListener(_onThanks);
    _engine = IdleEngine();
    _engine.onMutated = () {
      widget.settings.setEngineJson(_engine.toJson());
      widget.settings.requestSave();
    };
    if (widget.engineJson.isNotEmpty) {
      _engine.importJson(widget.engineJson);
    }
    _engine.start();
    _nameCtrl.text = widget.settings.playerName;
  }

  void _onPro() {
    if (_store.proPurchased.value && mounted) {
      widget.settings.setPro(true);
      _store.proPurchased.value = false;
      setState(() {});
    }
  }

  void _onThanks() {
    final msg = _store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Clicker.body(15, theme: _t)),
        backgroundColor: _t.woodDeep,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _store.lastThanks.value = null;
  }

  @override
  void dispose() {
    _store.proPurchased.removeListener(_onPro);
    _store.lastThanks.removeListener(_onThanks);
    _store.dispose();
    _engine.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  /// Real in-app review flow: the Play in-app review sheet when available,
  /// otherwise fall back to opening the store listing. No fake dialogs.
  Future<void> _requestReview() async {
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing(appStoreId: null);
      }
    } catch (_) {
      // Review UI unavailable on this device/build: stay silent, no fake UI.
    }
  }

  void _play() {
    widget.audio.gameStart();
    widget.audio.startGameMusic();
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => GameScreen(
        audio: widget.audio,
        settings: widget.settings,
        engine: _engine,
        store: _store,
        onReview: _requestReview,
      ),
    ))
        .then((_) {
      widget.audio.startMenuMusic();
    });
  }

  void _renameProfile() {
    final t = _t;
    final s = widget.settings;
    // Commit on focus loss: flush the whole document so a rename is never
    // lost if the app is killed right after editing.
    final node = FocusNode();
    node.addListener(() {
      if (!node.hasFocus) {
        s.setPlayerName(_nameCtrl.text);
        s.commitProfile();
      }
    });
    showDialog(
      context: context,
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
              Text('Tapper name', style: Clicker.display(20, theme: t)),
              const SizedBox(height: 12),
              TextField(
                controller: _nameCtrl,
                focusNode: node,
                maxLength: 24,
                style: Clicker.body(16, theme: t, color: t.woodDeep),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: t.paper,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  counterText: '',
                ),
                // Save on EVERY keystroke into the order-preserving
                // idleclicker_player_names_json document.
                onChanged: (v) => s.setPlayerName(v),
              ),
              const SizedBox(height: 14),
              ChunkyButton(
                label: 'Save name',
                theme: t,
                width: 200,
                onTap: () {
                  widget.audio.click();
                  s.setPlayerName(_nameCtrl.text);
                  s.commitProfile();
                  Navigator.pop(c);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    ).then((_) => node.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    return ToyBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: Listenable.merge([s, _engine]),
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                children: [
                  // Logo + title.
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: t.accent, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          offset: const Offset(0, 6),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/idle_logo.png',
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 10),
                  Text('Idle Clicker', style: Clicker.display(36, theme: t)),
                  Text('Tap a star. Build an empire. Nap while it works.',
                      style: Clicker.body(13, theme: t),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 14),
                  // Profile card.
                  ToyPanel(
                    theme: t,
                    child: Row(
                      children: [
                        Text('🧑‍🚀',
                            style: const TextStyle(fontSize: 30)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.playerName,
                                  style: Clicker.label(16, theme: t)),
                              Text(
                                'Tier: ${IdleEngine.tiers[_engine.tierIndex].emoji} ${IdleEngine.tiers[_engine.tierIndex].name} · Prestige ${_engine.prestige}',
                                style: Clicker.body(12, theme: t),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit,
                              color: t.accentLight, size: 22),
                          tooltip: 'Rename profile',
                          onPressed: () {
                            widget.audio.click();
                            _renameProfile();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ChunkyButton(
                    label: '▶  PLAY',
                    theme: t,
                    width: 240,
                    height: 62,
                    onTap: _play,
                  ),
                  const SizedBox(height: 14),
                  // Tier ladder.
                  _TierLadder(theme: t, tierIndex: _engine.tierIndex),
                  const SizedBox(height: 14),
                  // Milestone chips.
                  _MilestoneStrip(theme: t, engine: _engine),
                  const SizedBox(height: 14),
                  // Icon row.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MenuIcon(
                          theme: t,
                          icon: Icons.palette,
                          label: 'Themes',
                          onTap: () {
                            widget.audio.click();
                            Navigator.of(context)
                                .push(MaterialPageRoute(
                                    builder: (_) => ThemeScreen(
                                        audio: widget.audio,
                                        settings: s)))
                                .then((_) => setState(() {}));
                          }),
                      _MenuIcon(
                          theme: t,
                          icon: Icons.workspace_premium,
                          label: 'Pro',
                          onTap: () {
                            widget.audio.click();
                            Navigator.of(context)
                                .push(MaterialPageRoute(
                                    builder: (_) => ProScreen(
                                        audio: widget.audio,
                                        settings: s,
                                        store: _store)))
                                .then((_) => setState(() {}));
                          }),
                      _MenuIcon(
                          theme: t,
                          icon: Icons.settings,
                          label: 'Settings',
                          onTap: () {
                            widget.audio.click();
                            Navigator.of(context)
                                .push(MaterialPageRoute(
                                    builder: (_) => SettingsScreen(
                                        audio: widget.audio,
                                        settings: s,
                                        engine: _engine)))
                                .then((_) => setState(() {}));
                          }),
                      _MenuIcon(
                          theme: t,
                          icon: Icons.share,
                          label: 'Share',
                          onTap: () async {
                            widget.audio.click();
                            await SharePlus.instance.share(
                              ShareParams(
                                text:
                                    'Tap a star with me in Idle Clicker! https://play.google.com/store/apps/details?id=com.gameswajiha.idleclicker',
                              ),
                            );
                          }),
                      _MenuIcon(
                          theme: t,
                          icon: Icons.star_rate,
                          label: 'Rate',
                          onTap: () async {
                            widget.audio.click();
                            await _requestReview();
                          }),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Credits: WAJIHA',
                      style: Clicker.label(11, theme: t)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Progression tier ladder — the game's mode ladder.
class _TierLadder extends StatelessWidget {
  final ClickerThemeDef theme;
  final int tierIndex;
  const _TierLadder({required this.theme, required this.tierIndex});

  @override
  Widget build(BuildContext context) {
    return ToyPanel(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🌌 Progression Tiers',
              style: Clicker.label(15, theme: theme)),
          const SizedBox(height: 8),
          for (int i = 0; i < IdleEngine.tiers.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Text(IdleEngine.tiers[i].emoji,
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(IdleEngine.tiers[i].name,
                        style: Clicker.body(13, theme: theme)),
                  ),
                  if (i == tierIndex)
                    PriceTag(
                        text: 'YOU ARE HERE',
                        theme: theme)
                  else if (i < tierIndex)
                    Text('✓',
                        style: Clicker.body(14,
                            theme: theme,
                            color: theme.accentLight))
                  else
                    Text(IdleEngine.fmt(
                        IdleEngine.tiers[i].lifetimeNeeded),
                        style: Clicker.body(12, theme: theme)),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text('Nebula unlocks Comet Collectors · Galaxy unlocks Star Forges',
              style: Clicker.body(11, theme: theme)),
        ],
      ),
    );
  }
}

/// Milestone challenge strip — completed vs pending.
class _MilestoneStrip extends StatelessWidget {
  final ClickerThemeDef theme;
  final IdleEngine engine;
  const _MilestoneStrip({required this.theme, required this.engine});

  @override
  Widget build(BuildContext context) {
    final done = engine.milestonesDone.length;
    final total = IdleEngine.milestones.length;
    return ToyPanel(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🏆 Milestone Challenges',
                  style: Clicker.label(15, theme: theme)),
              const Spacer(),
              Text('$done/$total',
                  style: Clicker.body(13, theme: theme)),
            ],
          ),
          const SizedBox(height: 8),
          for (final m in IdleEngine.milestones)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Text(
                      engine.milestonesDone.contains(m.id) ? '✅' : '⬜',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(m.title,
                        style: Clicker.body(12, theme: theme)),
                  ),
                  Text('+${IdleEngine.fmt(m.bonus)}',
                      style: Clicker.label(11, theme: theme)),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Text('Turbo best: ${engine.turboBest} taps in 30s',
              style: Clicker.body(11, theme: theme)),
        ],
      ),
    );
  }
}

class _MenuIcon extends StatelessWidget {
  final ClickerThemeDef theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuIcon(
      {required this.theme,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [theme.accentLight, theme.accent, theme.accentDark],
                ),
                border: Border.all(color: theme.woodDeep, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(icon, color: theme.woodDeep, size: 26),
            ),
            const SizedBox(height: 4),
            Text(label, style: Clicker.label(10, theme: theme)),
          ],
        ),
      ),
    );
  }
}
