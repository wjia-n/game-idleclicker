import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Idle Clicker engine — "Starfall Tappers".
///
/// The ENGINE owns all game state, all phases and all timers. The UI is a
/// dumb listener: it renders state and forwards taps/buys. Stuck states are
/// impossible by construction:
/// - A single 200ms tick timer drives income, milestone checks, tier
///   upgrades and turbo countdown. All state transitions happen inside it.
/// - A 1s watchdog verifies the tick timer is alive and that any staged
///   sequence (prestige ceremony, turbo) still has a live timer; if a timer
///   ever dies silently the watchdog re-arms it — the game self-heals.
/// - Phases are explicit: [running], [prestiging] (a staged animation
///   ceremony), [paused] (lifecycle). Every phase has a legal forward
///   action and a recovery path.
/// - Offline progress is computed by the engine from wall-clock time on
///   resume (capped), never by the UI.
enum EnginePhase { running, prestiging, paused }

/// Upgrade definitions: staged purchases with animated buy feedback.
class UpgradeDef {
  final String id;
  final String name;
  final String emoji;
  final String desc;
  final int unlockTier; // tier index that unlocks this upgrade
  final double baseCost;
  final double costGrowth;
  const UpgradeDef({
    required this.id,
    required this.name,
    required this.emoji,
    required this.desc,
    required this.unlockTier,
    required this.baseCost,
    required this.costGrowth,
  });
}

/// Progression tiers — the game's mode ladder. Higher tiers unlock
/// stronger upgrades.
class TierDef {
  final String name;
  final String emoji;
  final double lifetimeNeeded;
  const TierDef({
    required this.name,
    required this.emoji,
    required this.lifetimeNeeded,
  });
}

/// One-time milestone challenges with stardust bonuses.
class MilestoneDef {
  final String id;
  final String title;
  final String desc;
  final double bonus;
  const MilestoneDef({
    required this.id,
    required this.title,
    required this.desc,
    required this.bonus,
  });
}

class IdleEngine extends ChangeNotifier {
  // ------------------------------------------------------------- catalog
  static const List<UpgradeDef> upgrades = [
    UpgradeDef(
        id: 'tapper',
        name: 'Auto-Tapper',
        emoji: '🤖',
        desc: '+1 stardust/sec',
        unlockTier: 0,
        baseCost: 25,
        costGrowth: 1.6),
    UpgradeDef(
        id: 'mega',
        name: 'Mega Tapper',
        emoji: '🚀',
        desc: '+8 stardust/sec',
        unlockTier: 0,
        baseCost: 400,
        costGrowth: 1.7),
    UpgradeDef(
        id: 'power',
        name: 'Tap Power',
        emoji: '👆',
        desc: '+1 per tap',
        unlockTier: 0,
        baseCost: 100,
        costGrowth: 2.2),
    UpgradeDef(
        id: 'mult',
        name: 'Multiplier',
        emoji: '✖️',
        desc: '×2 everything',
        unlockTier: 0,
        baseCost: 1500,
        costGrowth: 3.0),
    UpgradeDef(
        id: 'comet',
        name: 'Comet Collector',
        emoji: '☄️',
        desc: '+40 stardust/sec',
        unlockTier: 2,
        baseCost: 50000,
        costGrowth: 1.75),
    UpgradeDef(
        id: 'forge',
        name: 'Star Forge',
        emoji: '🔥',
        desc: '×3 tap power',
        unlockTier: 3,
        baseCost: 250000,
        costGrowth: 3.2),
  ];

  static const List<TierDef> tiers = [
    TierDef(name: 'Firefly', emoji: '🪲', lifetimeNeeded: 0),
    TierDef(name: 'Starlight', emoji: '✨', lifetimeNeeded: 10000),
    TierDef(name: 'Nebula', emoji: '🌌', lifetimeNeeded: 100000),
    TierDef(name: 'Galaxy', emoji: '🌀', lifetimeNeeded: 1000000),
    TierDef(name: 'Universe', emoji: '🌠', lifetimeNeeded: 10000000),
  ];

  static const double prestigeLifetimeNeeded = 100000;

  static const List<MilestoneDef> milestones = [
    MilestoneDef(
        id: 'm_taps100',
        title: 'Warming Up',
        desc: 'Tap 100 times',
        bonus: 250),
    MilestoneDef(
        id: 'm_dust1k',
        title: 'First Thousand',
        desc: 'Hold 1,000 stardust at once',
        bonus: 500),
    MilestoneDef(
        id: 'm_tappers10',
        title: 'Little Workforce',
        desc: 'Own 10 Auto-Tappers',
        bonus: 1000),
    MilestoneDef(
        id: 'm_nebula',
        title: 'Nebula Bound',
        desc: 'Reach the Nebula tier',
        bonus: 5000),
    MilestoneDef(
        id: 'm_prestige1',
        title: 'Supernova',
        desc: 'Prestige for the first time',
        bonus: 25000),
    MilestoneDef(
        id: 'm_dust1m',
        title: 'Millionaire',
        desc: 'Earn 1,000,000 lifetime stardust',
        bonus: 100000),
    MilestoneDef(
        id: 'm_turbo500',
        title: 'Turbo Hands',
        desc: 'Score 500 taps in one Turbo round',
        bonus: 2000),
  ];

  static const Duration turboLength = Duration(seconds: 30);
  static const double turboTapMultiplier = 5.0;
  static const int maxOfflineSeconds = 8 * 3600;

  // ---------------------------------------------------------------- state
  double dust = 0;
  double lifetime = 0;
  int taps = 0;
  int prestige = 0;
  Map<String, int> owned = {for (final u in upgrades) u.id: 0};
  Set<String> milestonesDone = {};
  int turboBest = 0;

  EnginePhase phase = EnginePhase.running;
  int prestigeStage = 0; // staged prestige ceremony 0..3
  bool turboActive = false;
  int turboTaps = 0;
  int turboSecondsLeft = 0;

  /// Set by [noteResumed] when offline earnings were granted; the UI shows
  /// a welcome-back banner and then clears it via [clearWelcomeBack].
  double? welcomeBackEarnings;

  /// Queue of freshly-completed milestone ids for the UI to celebrate
  /// (animated toasts). UI pops them with [takeMilestoneEvent].
  final List<String> _milestoneEvents = [];

  /// Id of the upgrade just bought (for the buy pop animation).
  /// UI clears it with [clearBuyFlash].
  String? buyFlash;

  DateTime? _lastTickWall;

  /// Wall-clock ms of the persisted save (from `savedAt` in the save
  /// document), consumed EXACTLY ONCE by the first [noteResumed] after a
  /// restart. Set by [importJson]; never refreshed by the tick loop, so a
  /// killed-then-reopened app correctly grants offline earnings instead of
  /// seeing a fresh heartbeat.
  int? _restoredSavedAt;
  Timer? _tick;
  Timer? _watchdog;
  Timer? _prestigeTimer;
  Timer? _turboTimer;
  bool _disposed = false;

  /// Fired whenever state mutated in a way worth persisting.
  VoidCallback? onMutated;

  // ------------------------------------------------------------ derived
  int get tierIndex {
    var t = 0;
    for (int i = 0; i < tiers.length; i++) {
      if (lifetime >= tiers[i].lifetimeNeeded) t = i;
    }
    return t;
  }

  double get tapPower {
    final p = owned['power'] ?? 0;
    final forge = owned['forge'] ?? 0;
    return ((p + 1) * (1 + prestige * 0.5) * pow(2, owned['mult'] ?? 0) * pow(3, forge))
        .toDouble();
  }

  double get perSec {
    final base = ((owned['tapper'] ?? 0) +
            (owned['mega'] ?? 0) * 8 +
            (owned['comet'] ?? 0) * 40)
        .toDouble();
    return base *
        (1 + prestige * 0.5) *
        pow(2, owned['mult'] ?? 0).toDouble();
  }

  bool get canPrestige =>
      phase == EnginePhase.running &&
      !turboActive &&
      lifetime >= prestigeLifetimeNeeded;

  double upgradeCost(String id) {
    final def = upgrades.firstWhere((u) => u.id == id);
    return def.baseCost * pow(def.costGrowth, owned[id] ?? 0);
  }

  bool upgradeUnlocked(String id) {
    final def = upgrades.firstWhere((u) => u.id == id);
    return tierIndex >= def.unlockTier;
  }

  bool canAfford(String id) => phase == EnginePhase.running && dust >= upgradeCost(id);

  // ------------------------------------------------------------ lifecycle
  /// Start the engine timers. Called once after construction/import.
  void start() {
    if (_disposed || _tick != null) return;
    _lastTickWall = DateTime.now();
    _tick = Timer.periodic(const Duration(milliseconds: 200), _onTick);
    _watchdog =
        Timer.periodic(const Duration(seconds: 1), (_) => _onWatchdog());
  }

  void _onTick(Timer t) {
    if (_disposed) return;
    _lastTickWall = DateTime.now();
    if (phase == EnginePhase.paused || phase == EnginePhase.prestiging) {
      return; // income frozen while paused or during the prestige ceremony
    }
    final gain = perSec * 0.2;
    if (gain > 0) {
      dust += gain;
      lifetime += gain;
    }
    if (turboActive && turboSecondsLeft > 0) {
      // Turbo countdown is owned by its 1s timer; the watchdog re-arms it
      // if it ever dies — a turbo round always ends.
    }
    _checkMilestones();
    _mutated();
  }

  /// Watchdog: heals any silently-dead timer. Runs every second.
  /// If the tick timer has gone >2s without a heartbeat while the game is
  /// supposed to be running, the tick timer is re-armed. If a staged
  /// sequence (prestige ceremony / turbo) is active without a live timer,
  /// its timer is re-armed from current state.
  void _onWatchdog() {
    if (_disposed) return;
    final now = DateTime.now();
    if (_tick == null || !_tick!.isActive) {
      _tick = Timer.periodic(const Duration(milliseconds: 200), _onTick);
      _lastTickWall = now;
    } else if (phase == EnginePhase.running &&
        _lastTickWall != null &&
        now.difference(_lastTickWall).inSeconds > 2) {
      // Tick timer exists but went silent — re-arm it.
      _tick!.cancel();
      _tick = Timer.periodic(const Duration(milliseconds: 200), _onTick);
      _lastTickWall = now;
    }
    if (phase == EnginePhase.prestiging &&
        (_prestigeTimer == null || !_prestigeTimer!.isActive)) {
      _armPrestigeTimer(); // resume the ceremony where it left off
    }
    if (turboActive && (_turboTimer == null || !_turboTimer!.isActive)) {
      _armTurboTimer();
    }
  }

  // ------------------------------------------------------------ actions
  /// The big tap. Always legal while running; ignored in other phases
  /// (engine stays consistent — no invalid state transitions).
  void tap() {
    if (_disposed || phase != EnginePhase.running) return;
    var power = tapPower;
    if (turboActive) {
      power *= turboTapMultiplier;
      turboTaps++;
    }
    dust += power;
    lifetime += power;
    taps++;
    _checkMilestones();
    _mutated();
  }

  /// Buy one level of an upgrade. Returns false if illegal (locked,
  /// unaffordable, or wrong phase) — the UI plays the invalid sound.
  bool buy(String id) {
    if (_disposed || phase != EnginePhase.running) return false;
    if (!upgrades.any((u) => u.id == id)) return false;
    if (!upgradeUnlocked(id)) return false;
    final cost = upgradeCost(id);
    if (dust < cost) return false;
    dust -= cost;
    owned[id] = (owned[id] ?? 0) + 1;
    buyFlash = id;
    _mutated();
    return true;
  }

  /// Start the prestige ceremony: a staged 4-step animation owned by the
  /// engine. Income is frozen while it runs; the watchdog guarantees it
  /// always completes.
  void startPrestige() {
    if (!canPrestige) return;
    phase = EnginePhase.prestiging;
    prestigeStage = 0;
    _armPrestigeTimer();
    _mutated();
  }

  void _armPrestigeTimer() {
    _prestigeTimer?.cancel();
    _prestigeTimer = Timer.periodic(
      const Duration(milliseconds: 600),
      (t) {
        if (_disposed) {
          t.cancel();
          return;
        }
        if (phase != EnginePhase.prestiging) {
          t.cancel();
          return;
        }
        prestigeStage++;
        if (prestigeStage >= 4) {
          t.cancel();
          _applyPrestige();
        }
        _mutated();
      },
    );
  }

  void _applyPrestige() {
    final wasFirst = prestige == 0;
    dust = 0;
    lifetime = 0;
    for (final k in owned.keys) {
      owned[k] = 0;
    }
    prestige++;
    turboActive = false;
    turboTaps = 0;
    turboSecondsLeft = 0;
    phase = EnginePhase.running;
    prestigeStage = 0;
    if (wasFirst) _grantMilestone('m_prestige1');
    _mutated();
  }

  /// 30-second Turbo round: taps are worth ×5. Engine-owned countdown and
  /// auto-finish; the watchdog guarantees the round always ends.
  void startTurbo() {
    if (_disposed ||
        phase != EnginePhase.running ||
        turboActive) return;
    turboActive = true;
    turboTaps = 0;
    turboSecondsLeft = turboLength.inSeconds;
    _armTurboTimer();
    _mutated();
  }

  void _armTurboTimer() {
    _turboTimer?.cancel();
    _turboTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_disposed) {
        t.cancel();
        return;
      }
      if (!turboActive) {
        t.cancel();
        return;
      }
      turboSecondsLeft--;
      if (turboSecondsLeft <= 0) {
        t.cancel();
        _endTurbo();
      }
      _mutated();
    });
  }

  void _endTurbo() {
    turboActive = false;
    if (turboTaps > turboBest) turboBest = turboTaps;
    turboTaps = 0;
    turboSecondsLeft = 0;
    _mutated();
  }

  void pauseForLifecycle() {
    if (phase == EnginePhase.running) {
      phase = EnginePhase.paused;
      _mutated();
    }
  }

  void resumeFromLifecycle() {
    if (phase == EnginePhase.paused) {
      phase = EnginePhase.running;
      _lastTickWall = DateTime.now();
      _mutated();
    }
  }

  /// Compute offline earnings from wall-clock time. Returns the granted
  /// amount (0 if nothing). Called by the UI on app resume and when the
  /// game screen opens; the engine decides, capped at
  /// [maxOfflineSeconds] (×3 for Pro).
  ///
  /// The FIRST call after a restart measures against the persisted
  /// `savedAt` stamp (the isolate heartbeat was lost with the process).
  /// That stamp is consumed exactly once — never double-granted.
  double noteResumed({required int offlineCapMultiplier}) {
    if (_disposed) return 0;
    resumeFromLifecycle();
    final now = DateTime.now();
    final restored = _restoredSavedAt;
    _restoredSavedAt = null; // consume exactly once
    final DateTime last;
    if (restored != null && restored <= now.millisecondsSinceEpoch) {
      last = DateTime.fromMillisecondsSinceEpoch(restored);
    } else {
      last = _lastTickWall ?? now;
    }
    final awaySecs = now.difference(last).inSeconds;
    _lastTickWall = now;
    if (awaySecs < 60 || perSec <= 0) return 0;
    final cap = maxOfflineSeconds * offlineCapMultiplier;
    final earned = perSec * min(awaySecs, cap);
    dust += earned;
    lifetime += earned;
    welcomeBackEarnings = earned;
    _checkMilestones();
    _mutated();
    return earned;
  }

  // ------------------------------------------------------------ milestones
  void _checkMilestones() {
    bool check(String id) {
      switch (id) {
        case 'm_taps100':
          return taps >= 100;
        case 'm_dust1k':
          return dust >= 1000;
        case 'm_tappers10':
          return (owned['tapper'] ?? 0) >= 10;
        case 'm_nebula':
          return tierIndex >= 2;
        case 'm_prestige1':
          return prestige >= 1;
        case 'm_dust1m':
          return lifetime >= 1000000;
        case 'm_turbo500':
          return turboTaps >= 500 || turboBest >= 500;
        default:
          return false;
      }
    }

    for (final m in milestones) {
      if (!milestonesDone.contains(m.id) && check(m.id)) {
        _grantMilestone(m.id);
      }
    }
  }

  void _grantMilestone(String id) {
    final def = milestones.firstWhere((m) => m.id == id);
    milestonesDone.add(id);
    dust += def.bonus;
    lifetime += def.bonus;
    _milestoneEvents.add(id);
  }

  /// UI pops milestone celebration events one at a time.
  String? takeMilestoneEvent() =>
      _milestoneEvents.isEmpty ? null : _milestoneEvents.removeAt(0);

  void clearBuyFlash() {
    buyFlash = null;
  }

  void clearWelcomeBack() {
    welcomeBackEarnings = null;
  }

  // ------------------------------------------------------------ reset
  void resetAll() {
    _prestigeTimer?.cancel();
    _turboTimer?.cancel();
    dust = 0;
    lifetime = 0;
    taps = 0;
    prestige = 0;
    for (final k in owned.keys) {
      owned[k] = 0;
    }
    milestonesDone.clear();
    turboBest = 0;
    turboActive = false;
    turboTaps = 0;
    turboSecondsLeft = 0;
    phase = EnginePhase.running;
    prestigeStage = 0;
    welcomeBackEarnings = null;
    _milestoneEvents.clear();
    buyFlash = null;
    _restoredSavedAt = null; // reset wipes the offline anchor too
    _lastTickWall = DateTime.now();
    _mutated();
  }

  // ------------------------------------------------------------ persistence
  Map<String, dynamic> toJson() => {
        'dust': dust,
        'lifetime': lifetime,
        'taps': taps,
        'prestige': prestige,
        'owned': Map<String, int>.from(owned),
        'milestones': milestonesDone.toList(),
        'turboBest': turboBest,
      };

  void importJson(Map<String, dynamic> j) {
    dust = (j['dust'] as num?)?.toDouble() ?? 0;
    lifetime = (j['lifetime'] as num?)?.toDouble() ?? 0;
    taps = (j['taps'] as num?)?.toInt() ?? 0;
    prestige = (j['prestige'] as num?)?.toInt() ?? 0;
    final o = j['owned'];
    if (o is Map) {
      for (final u in upgrades) {
        owned[u.id] = (o[u.id] as num?)?.toInt() ?? 0;
      }
    }
    final ms = j['milestones'];
    if (ms is List) {
      milestonesDone = {for (final m in ms) m.toString()};
    }
    turboBest = (j['turboBest'] as num?)?.toInt() ?? 0;
    // Persisted wall-clock stamp for first-resume offline earnings.
    final savedAt = (j['savedAt'] as num?)?.toInt();
    _restoredSavedAt = (savedAt != null && savedAt > 0) ? savedAt : null;
    // Never import a mid-ceremony state: always resume in a clean phase.
    phase = EnginePhase.running;
    prestigeStage = 0;
    turboActive = false;
    turboTaps = 0;
    turboSecondsLeft = 0;
    _mutated();
  }

  void _mutated() {
    if (!_disposed) {
      notifyListeners();
      onMutated?.call();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _tick?.cancel();
    _watchdog?.cancel();
    _prestigeTimer?.cancel();
    _turboTimer?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------ formatting
  static String fmt(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.floor().toString();
  }
}
