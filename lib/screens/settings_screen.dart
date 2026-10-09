import 'package:flutter/material.dart';
import '../engine/idle_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/clicker_art.dart';
import '../theme/clicker_themes.dart';

/// Settings: audio toggles + volume, profile rename, reset progress.
/// All changes apply instantly and persist.
class SettingsScreen extends StatefulWidget {
  final ClickerAudio audio;
  final ClickerSettings settings;
  final IdleEngine engine;
  const SettingsScreen(
      {super.key,
      required this.audio,
      required this.settings,
      required this.engine});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ClickerThemeDef get _t => widget.settings.theme;
  final _nameCtrl = TextEditingController();
  late final FocusNode _nameNode;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.settings.playerName;
    // Commit on focus loss: flush the whole document so a rename is never
    // lost if the app is killed right after editing.
    _nameNode = FocusNode();
    _nameNode.addListener(() {
      if (!_nameNode.hasFocus) {
        widget.settings.setPlayerName(_nameCtrl.text);
        widget.settings.commitProfile();
      }
    });
  }

  @override
  void dispose() {
    _nameNode.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _applyAudio() {
    widget.audio.configure(
      musicOn: widget.settings.musicOn,
      sfxOn: widget.settings.sfxOn,
      volume: widget.settings.volume,
    );
  }

  void _confirmReset() {
    final t = _t;
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
              Text('🗑️', style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 8),
              Text('Start over?',
                  style: Clicker.display(22, theme: t)),
              const SizedBox(height: 8),
              Text(
                'This erases ALL stardust, upgrades, prestige, milestones and turbo records. It cannot be undone.',
                style: Clicker.body(14, theme: t),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ChunkyButton(
                      label: 'Keep it',
                      theme: t,
                      width: 120,
                      height: 48,
                      onTap: () {
                        widget.audio.click();
                        Navigator.pop(c);
                      }),
                  ChunkyButton(
                      label: 'Erase all',
                      theme: t,
                      width: 130,
                      height: 48,
                      onTap: () {
                        widget.audio.lose();
                        widget.engine.resetAll();
                        widget.settings.saveNow();
                        Navigator.pop(c);
                        setState(() {});
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
    final s = widget.settings;
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
              Navigator.of(context).pop();
            },
          ),
          title: Text('Settings', style: Clicker.display(22, theme: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Column(
                children: [
                  ToyPanel(
                    theme: t,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🔊 Sound & Music',
                            style: Clicker.label(15, theme: t)),
                        SwitchListTile(
                          title: Text('Music',
                              style: Clicker.body(14, theme: t)),
                          value: s.musicOn,
                          activeThumbColor: t.accentLight,
                          onChanged: (v) {
                            widget.audio.click();
                            s.setMusic(v);
                            _applyAudio();
                          },
                        ),
                        SwitchListTile(
                          title: Text('Sound effects',
                              style: Clicker.body(14, theme: t)),
                          value: s.sfxOn,
                          activeThumbColor: t.accentLight,
                          onChanged: (v) {
                            s.setSfx(v);
                            _applyAudio();
                            widget.audio.click();
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: Row(
                            children: [
                              Text('Volume',
                                  style: Clicker.body(14, theme: t)),
                              Expanded(
                                child: Slider(
                                  value: s.volume,
                                  activeColor: t.accentLight,
                                  onChanged: (v) {
                                    s.setVolume(v);
                                    _applyAudio();
                                  },
                                  onChangeEnd: (_) =>
                                      widget.audio.click(),
                                ),
                              ),
                              Text('${(s.volume * 100).round()}%',
                                  style: Clicker.body(12, theme: t)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ToyPanel(
                    theme: t,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🧑‍🚀 Tapper profile',
                            style: Clicker.label(15, theme: t)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameCtrl,
                          focusNode: _nameNode,
                          maxLength: 24,
                          style: Clicker.body(16,
                              theme: t, color: t.woodDeep),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: t.paper,
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                            counterText: '',
                          ),
                          // Save on EVERY keystroke into the
                          // order-preserving names document.
                          onChanged: (v) => s.setPlayerName(v),
                          onSubmitted: (v) {
                            widget.audio.click();
                            s.setPlayerName(v);
                            s.commitProfile();
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 8),
                        ChunkyButton(
                          label: 'Save name',
                          theme: t,
                          width: 180,
                          height: 46,
                          onTap: () {
                            widget.audio.click();
                            s.setPlayerName(_nameCtrl.text);
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ToyPanel(
                    theme: t,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('⚠️ Danger zone',
                            style: Clicker.label(15, theme: t)),
                        const SizedBox(height: 8),
                        ChunkyButton(
                          label: '🗑️ Reset all progress',
                          theme: t,
                          width: 220,
                          height: 46,
                          onTap: _confirmReset,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
