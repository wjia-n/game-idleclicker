import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/clicker_themes.dart';

/// Persisted settings + full game state for Idle Clicker.
///
/// Everything — renameable player profile, audio toggles, theme choices,
/// Pro unlock, custom theme colors, AND the complete engine state (an idle
/// game must survive restarts with its progress intact) — lives in ONE
/// JSON string under [_kSave]. Ordered data is never stored as a
/// StringList: Android's SharedPreferences stores StringLists as an
/// unordered StringSet, which scrambles order on every restart.
///
/// Legacy migration: the original v1.0.1 stored `ic_*` keys. On first
/// load of the new build those are imported once into the new document
/// and the old keys are removed.
class ClickerSettings extends ChangeNotifier {
  static const _kSave = 'idleclicker_save_json';

  // Legacy v1.0.1 keys (one-time migration source).
  static const _legacyPrefix = 'ic_';

  static const defaultPlayerName = 'Star Tapper';

  /// Encode the whole save document as one JSON string (order-preserving).
  static String encodeSave(Map<String, dynamic> doc) => jsonEncode(doc);

  /// Decode a save document; returns null on missing/corrupt data.
  static Map<String, dynamic>? decodeSave(String? raw) {
    if (raw == null) return null;
    try {
      final d = jsonDecode(raw);
      if (d is Map<String, dynamic>) return d;
      if (d is Map) return Map<String, dynamic>.from(d);
    } catch (_) {}
    return null;
  }

  static String _cleanName(Object? v) {
    final s = v is String ? v.trim() : '';
    return s.isEmpty ? defaultPlayerName : s.substring(0, min(24, s.length));
  }

  // ---------------------------------------------------------------- profile
  /// The profile name lives in its OWN order-preserving JSON string under
  /// this key — NEVER setStringList (Android stores StringLists as an
  /// unordered StringSet, which scrambles slot order on every restart).
  /// The list form keeps every future multi-profile slot order-stable.
  static const _kNames = 'idleclicker_player_names_json';

  /// Legacy name sources, migrated once: the v1.0.1 `ic_name` key, and the
  /// v2 save document's embedded `playerName` field (this key predates it).
  static const _legacyNameKey = 'ic_name';

  String playerName = defaultPlayerName;

  /// Loads the profile name from the dedicated names key. Falls back, in
  /// order, to (1) the legacy `idleclicker_save_json` document's playerName
  /// field, (2) the v1.0.1 `ic_name` key, (3) the default — then commits
  /// the canonical names document so every future load reads it.
  Future<void> _loadPlayerName(SharedPreferences p,
      Map<String, dynamic>? doc) async {
    final raw = p.getString(_kNames);
    List<dynamic>? names;
    if (raw != null) {
      try {
        final d = jsonDecode(raw);
        if (d is List) names = d;
      } catch (_) {}
    }
    if (names != null && names.isNotEmpty) {
      playerName = _cleanName(names.first);
    } else {
      var fallback = defaultPlayerName;
      final docName = doc?['playerName'];
      if (docName is String && docName.trim().isNotEmpty) {
        fallback = docName;
      } else {
        final legacy = p.getString(_legacyNameKey);
        if (legacy != null && legacy.trim().isNotEmpty) {
          fallback = legacy;
        }
        await p.remove(_legacyNameKey);
      }
      playerName = _cleanName(fallback);
    }
    await p.setString(_kNames, jsonEncode([playerName]));
  }

  /// Save on EVERY keystroke (callers wire onChanged here). The full name
  /// document is one JSON string via setString — order-preserving, safe
  /// across restarts.
  Future<void> setPlayerName(String name) async {
    playerName = _cleanName(name);
    notifyListeners();
    final p = _prefs;
    if (p != null) {
      await p.setString(_kNames, jsonEncode([playerName]));
    }
  }

  /// Commit on focus loss: flush the whole document so a rename is never
  /// lost if the app is killed right after editing.
  Future<void> commitProfile() => saveNow();

  // ------------------------------------------------------------------ audio
  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;

  // -------------------------------------------------------------- appearance
  String themeId = 'woodshop';
  String tapStyleId = 'star';
  bool isPro = false;

  /// Custom theme colors (ARGB ints). Defaults mirror Starlit Woodshop.
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'woodDark': 0xFF3B2416,
    'woodMid': 0xFF5C3A21,
    'woodDeep': 0xFF241309,
    'accent': 0xFFC9A227,
    'accentLight': 0xFFE8CE7A,
    'accentDark': 0xFF8A6D1A,
    'paper': 0xFFF7EFDC,
    'felt': 0xFF1E4D3B,
    'starFace': 0xFFFFC93C,
    'starEdge': 0xFFD99420,
  };

  ClickerThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return ClickerThemeDef(
      id: 'custom',
      name: 'My Creation',
      woodDark: c('woodDark'),
      woodMid: c('woodMid'),
      woodDeep: c('woodDeep'),
      accent: c('accent'),
      accentLight: c('accentLight'),
      accentDark: c('accentDark'),
      paper: c('paper'),
      felt: c('felt'),
      starFace: c('starFace'),
      starEdge: c('starEdge'),
      highlight: const [
        Color(0xFFA31621),
        Color(0xFF1D4E9E),
        Color(0xFF1B7A4D),
        Color(0xFFD99A2B),
      ],
    );
  }

  ClickerThemeDef get theme =>
      ClickerThemes.byId(themeId, custom: customTheme);

  SharedPreferences? _prefs;
  bool _savePending = false;

  /// Loads everything. Returns the engine-state map for the engine to
  /// import (from the save document, or from the legacy v1.0.1 keys on
  /// first run of the new build).
  Future<Map<String, dynamic>> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    final doc = decodeSave(p.getString(_kSave));
    Map<String, dynamic> engineJson = {};
    if (doc != null) {
      await _loadPlayerName(p, doc);
      _applyDoc(doc);
      final e = doc['engine'];
      if (e is Map) engineJson = Map<String, dynamic>.from(e);
      // Wall-clock stamp the engine import needs for offline earnings.
      final savedAt = (doc['savedAt'] as num?)?.toInt();
      if (savedAt != null && savedAt > 0) {
        engineJson['savedAt'] = savedAt;
      }
    } else {
      // First run on the new build — try the legacy migration.
      await _loadPlayerName(p, null);
      engineJson = _migrateLegacy(p);
      notifyListeners();
      await _saveNow();
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
    return engineJson;
  }

  void _applyDoc(Map<String, dynamic> doc) {
    // playerName is NOT read here on purpose: it lives in
    // idleclicker_player_names_json (loaded/migrated by _loadPlayerName).
    musicOn = doc['musicOn'] as bool? ?? true;
    sfxOn = doc['sfxOn'] as bool? ?? true;
    volume = ((doc['volume'] as num?)?.toDouble() ?? 0.8).clamp(0.0, 1.0);
    themeId = doc['themeId'] as String? ?? 'woodshop';
    tapStyleId = doc['tapStyleId'] as String? ?? 'star';
    isPro = doc['isPro'] as bool? ?? false;
    final cc = doc['customColors'];
    if (cc is Map) {
      for (final k in _defaultCustomColors.keys) {
        final v = cc[k];
        customColors[k] = v is int ? v : _defaultCustomColors[k]!;
      }
    }
  }

  /// One-time import from the legacy `ic_*` keys (v1.0.1 format), then
  /// deletes them. Returns the engine-state map for the engine to import.

  Map<String, dynamic> _migrateLegacy(SharedPreferences p) {
    // Legacy tap level started at 1 (base tap power). The new engine's
    // power upgrade adds +1 per tap on top of the base, so subtract 1.
    final legacyPower = ((p.getInt('${_legacyPrefix}taplvl') ?? 1) - 1).clamp(0, 1 << 30);
    final owned = <String, int>{
      'tapper': p.getInt('${_legacyPrefix}tap') ?? 0,
      'mega': p.getInt('${_legacyPrefix}mega') ?? 0,
      'power': legacyPower,
      'mult': p.getInt('${_legacyPrefix}mult') ?? 0,
      'comet': 0,
      'forge': 0,
    };
    final engine = <String, dynamic>{
      'dust': p.getDouble('${_legacyPrefix}dust') ?? 0,
      'lifetime': p.getDouble('${_legacyPrefix}life') ?? 0,
      'taps': 0,
      'prestige': p.getInt('${_legacyPrefix}pres') ?? 0,
      'owned': owned,
      'milestones': <String>[],
      'turboBest': 0,
    };
    // Legacy stored tap level starting at 1 meaning +1 power per level.
    // New engine: power upgrade level adds +1 per tap on top of base 1.
    for (final k in p.getKeys().toList()) {
      if (k.startsWith(_legacyPrefix)) {
        p.remove(k);
      }
    }
    return engine;
  }

  /// The engine-state half of the save document; the engine fills it in.
  Map<String, dynamic>? _engineJson;

  void setEngineJson(Map<String, dynamic> j) {
    _engineJson = j;
  }

  Future<void> _saveNow() async {
    final p = _prefs;
    if (p == null) return;
    final doc = <String, dynamic>{
      'v': 3,
      // NOTE: playerName is intentionally NOT in this document — it lives
      // in its own order-preserving JSON string under
      // `idleclicker_player_names_json` (migrated in _loadPlayerName).
      'musicOn': musicOn,
      'sfxOn': sfxOn,
      'volume': volume,
      'themeId': themeId,
      'tapStyleId': tapStyleId,
      'isPro': isPro,
      'customColors': Map<String, int>.from(customColors),
      'engine': _engineJson ?? <String, dynamic>{},
      // Wall-clock stamp so the engine can compute offline earnings after
      // a restart (the isolate's own heartbeat is gone when killed).
      'savedAt': DateTime.now().millisecondsSinceEpoch,
    };
    await p.setString(_kSave, encodeSave(doc));
  }

  /// Debounced save — coalesces rapid mutation bursts (ticks, tap storms).
  Future<void> requestSave() async {
    if (_savePending) return;
    _savePending = true;
    await Future.delayed(const Duration(seconds: 5));
    _savePending = false;
    await _saveNow();
  }

  Future<void> saveNow() => _saveNow();

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || ClickerThemes.isProTheme(themeId)) {
      themeId = 'woodshop';
      changed = true;
    }
    if (TapStyles.isPro(tapStyleId)) {
      tapStyleId = 'star';
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      requestSave();
    }
  }

  /// Offline earnings cap multiplier: Pro tappers nap longer.
  /// Convenience only — never a gameplay earnings multiplier.
  int get offlineCapMultiplier => isPro ? 3 : 1;

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _saveNow();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _saveNow();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _saveNow();
  }

  Future<void> setTheme(String id) async {
    if (!isPro && (id == 'custom' || ClickerThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _saveNow();
  }

  Future<void> setTapStyle(String id) async {
    if (!TapStyles.all.any((s) => s.id == id)) return;
    if (!isPro && TapStyles.isPro(id)) return;
    tapStyleId = id;
    notifyListeners();
    await _saveNow();
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _saveNow();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!isPro) return; // custom theme creator is a Pro feature
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _saveNow();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _saveNow();
  }
}
