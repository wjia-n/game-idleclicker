import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

class IdleClickerScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;
  const IdleClickerScreen({super.key, required this.players, required this.callbacks});
  @override
  State<IdleClickerScreen> createState() => _IdleClickerScreenState();
}

class _IdleClickerScreenState extends State<IdleClickerScreen> with WidgetsBindingObserver {
  double dust = 0, lifetime = 0;
  int tappers = 0, megas = 0, tapLvl = 1, multLvl = 0, prestige = 0;
  double pop = 0; String? welcomeBack;
  bool over = false;

  double get tapPower => (tapLvl * (1 + prestige * 0.5)) * pow(2, multLvl).toDouble();
  double get perSec => ((tappers + megas * 8) * (1 + prestige * 0.5) * pow(2, multLvl)).toDouble();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    Timer.periodic(const Duration(milliseconds: 200), _tick);
  }

  @override
  void dispose() {
    _save();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused || s == AppLifecycleState.inactive) _save();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = p.getInt('ic_last') ?? now;
    setState(() {
      dust = p.getDouble('ic_dust') ?? 0;
      lifetime = p.getDouble('ic_life') ?? 0;
      tappers = p.getInt('ic_tap') ?? 0;
      megas = p.getInt('ic_mega') ?? 0;
      tapLvl = p.getInt('ic_taplvl') ?? 1;
      multLvl = p.getInt('ic_mult') ?? 0;
      prestige = p.getInt('ic_pres') ?? 0;
    });
    final away = (now - last) / 1000;
    if (away > 60 && perSec > 0) {
      final earned = perSec * min(away, 8 * 3600);
      setState(() { dust += earned; lifetime += earned; welcomeBack = '🌙 While you were away: +${_fmt(earned)}'; });
      Sfx.win();
    }
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble('ic_dust', dust);
    await p.setDouble('ic_life', lifetime);
    await p.setInt('ic_tap', tappers);
    await p.setInt('ic_mega', megas);
    await p.setInt('ic_taplvl', tapLvl);
    await p.setInt('ic_mult', multLvl);
    await p.setInt('ic_pres', prestige);
    await p.setInt('ic_last', DateTime.now().millisecondsSinceEpoch);
  }

  void _tick(Timer t) {
    if (!mounted || over) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    setState(() {
      final e = perSec * 0.2;
      dust += e; lifetime += e;
      if (pop > 0) pop -= 0.2;
    });
  }

  void _tap() {
    setState(() { dust += tapPower; lifetime += tapPower; pop = 1.0; });
    Sfx.tap();
  }

  String _fmt(double v) {
    if (v >= 1e6) return '${(v/1e6).toStringAsFixed(2)}M';
    if (v >= 1e3) return '${(v/1e3).toStringAsFixed(1)}K';
    return v.floor().toString();
  }

  void _buy(String kind) {
    double cost;
    switch (kind) {
      case 'tap': cost = 25 * pow(1.6, tappers).toDouble(); break;
      case 'mega': cost = 400 * pow(1.7, megas).toDouble(); break;
      case 'power': cost = 100 * pow(2.2, tapLvl - 1).toDouble(); break;
      default: cost = 1500 * pow(3.0, multLvl).toDouble();
    }
    if (dust < cost) return;
    setState(() {
      dust -= cost;
      if (kind == 'tap') { tappers++; }
      else if (kind == 'mega') { megas++; }
      else if (kind == 'power') { tapLvl++; }
      else { multLvl++; }
    });
    Sfx.click();
  }

  void _prestige() {
    if (lifetime < 100000 || over) return;
    showDialog(context: context, builder: (c) => WajihaDialog(
      title: 'Go supernova?', emoji: '💥',
      children: [
        Text('Reset everything for prestige ${prestige + 1}:\n+50% permanent earnings forever.',
            style: TextStyle(color: ThemeController.of(context).theme.muted)),
        const SizedBox(height: 12),
        WajihaButton(label: 'Prestige!', emoji: '🌟', primary: true, onTap: () {
          Navigator.pop(c);
          setState(() { dust = 0; lifetime = 0; tappers = 0; megas = 0; tapLvl = 1; multLvl = 0; prestige++; });
          Sfx.win();
        }),
      ],
    ));
  }

  void _retire() {
    if (over) return; over = true;
    widget.players.first.score = lifetime.floor();
    widget.callbacks.finish(headline: 'You cashed out ${_fmt(lifetime)} stardust!',
        subline: 'Prestige level $prestige · tap power ${_fmt(tapPower)}');
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    return Column(children: [
      const SizedBox(height: 8),
      Text('✨ ${_fmt(dust)}', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: t.text)),
      Text('+${_fmt(perSec)}/sec · tap ${_fmt(tapPower)} · prestige $prestige',
          style: TextStyle(color: t.muted)),
      if (welcomeBack != null)
        Padding(padding: const EdgeInsets.all(6),
            child: Text(welcomeBack!, style: TextStyle(color: t.accent, fontWeight: FontWeight.bold))),
      Expanded(
        child: Center(
          child: GestureDetector(
            onTap: _tap,
            child: AnimatedScale(
              scale: pop > 0 ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 90),
              child: Container(
                width: 190, height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: t.headerGradient,
                  boxShadow: [BoxShadow(color: t.accent.withValues(alpha: 0.5), blurRadius: 30)],
                ),
                child: Center(child: Text('⭐', style: TextStyle(fontSize: 84, shadows: [
                  Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8),
                ]))),
              ),
            ),
          ),
        ),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            _shop(t, '🤖', 'Auto-tapper', '+1/sec', 25 * pow(1.6, tappers).toDouble(), 'tap', tappers),
            _shop(t, '🚀', 'Mega tapper', '+8/sec', 400 * pow(1.7, megas).toDouble(), 'mega', megas),
            _shop(t, '👆', 'Tap power', '+1 per tap', 100 * pow(2.2, tapLvl - 1).toDouble(), 'power', tapLvl - 1),
            _shop(t, '✖️', 'Multiplier', '×2 everything', 1500 * pow(3.0, multLvl).toDouble(), 'mult', multLvl),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: WajihaButton(label: 'Prestige (100K)', emoji: '💥',
                  onTap: lifetime >= 100000 ? _prestige : () {})),
              const SizedBox(width: 8),
              Expanded(child: WajihaButton(label: 'Cash out', emoji: '🏁', onTap: _retire)),
            ]),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ]);
  }

  Widget _shop(GameTheme t, String e, String name, String desc, double cost, String kind, int owned) {
    final afford = dust >= cost;
    return Card(
      color: t.surface, shape: RoundedRectangleBorder(borderRadius: t.radius),
      child: ListTile(
        leading: Text(e, style: const TextStyle(fontSize: 30)),
        title: Text('$name ×$owned', style: TextStyle(color: t.text, fontWeight: FontWeight.bold)),
        subtitle: Text('$desc · 💫 ${_fmt(cost)}', style: TextStyle(color: t.muted)),
        trailing: Opacity(
          opacity: afford ? 1 : 0.4,
          child: WajihaButton(label: 'Buy', emoji: '🛒', onTap: afford ? () => _buy(kind) : () {}),
        ),
      ),
    );
  }
}
