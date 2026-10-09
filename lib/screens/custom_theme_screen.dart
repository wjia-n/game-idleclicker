import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/clicker_art.dart';
import '../theme/clicker_themes.dart';

/// Custom theme creator (PRO): pick every toy-shop color yourself,
/// with a live preview of the tap toy.
class CustomThemeScreen extends StatefulWidget {
  final ClickerAudio audio;
  final ClickerSettings settings;
  const CustomThemeScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _CustomThemeScreenState extends State<CustomThemeScreen> {
  ClickerThemeDef get _t => widget.settings.theme;

  static const Map<String, String> _labels = {
    'woodDark': 'Wood (dark)',
    'woodMid': 'Wood (mid)',
    'woodDeep': 'Wood (deep)',
    'accent': 'Brass accent',
    'accentLight': 'Brass light',
    'accentDark': 'Brass dark',
    'paper': 'Paper',
    'felt': 'Felt',
    'starFace': 'Star face',
    'starEdge': 'Star edge',
  };

  /// Curated warm toy-shop palette — no neon allowed in.
  static const List<Color> _palette = [
    Color(0xFF3B2416),
    Color(0xFF5C3A21),
    Color(0xFF241309),
    Color(0xFF4A1F14),
    Color(0xFF6E2F1C),
    Color(0xFFC9A227),
    Color(0xFFE8CE7A),
    Color(0xFF8A6D1A),
    Color(0xFFB87333),
    Color(0xFFF7EFDC),
    Color(0xFFFFF6F0),
    Color(0xFF1E4D3B),
    Color(0xFF145A66),
    Color(0xFFA31621),
    Color(0xFF1D4E9E),
    Color(0xFF1B7A4D),
    Color(0xFFD99A2B),
    Color(0xFFFFC93C),
    Color(0xFFFF9EBB),
    Color(0xFF7FE3D6),
    Color(0xFF9FE8C9),
    Color(0xFFE58A8A),
    Color(0xFF7D3C98),
    Color(0xFFE67E22),
  ];

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
          title:
              Text('My Creation', style: Clicker.display(22, theme: t)),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () {
                widget.audio.click();
                s.resetCustomColors();
                setState(() {});
              },
              child: Text('Reset',
                  style: Clicker.label(13, theme: t)),
            ),
          ],
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Column(
                children: [
                  // Live preview.
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          s.customTheme.starFace,
                          s.customTheme.starEdge
                        ],
                      ),
                      border: Border.all(
                          color: s.customTheme.accent, width: 5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          offset: const Offset(0, 8),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: const Center(
                        child: Text('⭐',
                            style: TextStyle(fontSize: 62))),
                  ),
                  const SizedBox(height: 6),
                  Text('Live preview',
                      style: Clicker.body(12, theme: t)),
                  const SizedBox(height: 14),
                  for (final key in _labels.keys)
                    _ColorRow(
                      theme: t,
                      label: _labels[key]!,
                      current: Color(s.customColors[key]!),
                      onPick: (c) {
                        widget.audio.knock();
                        s.setCustomColor(key, c.toARGB32());
                      },
                    ),
                  const SizedBox(height: 14),
                  ChunkyButton(
                    label: 'Use my theme',
                    theme: t,
                    width: 220,
                    onTap: () {
                      widget.audio.click();
                      s.setTheme('custom');
                      Navigator.of(context).pop();
                    },
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

class _ColorRow extends StatelessWidget {
  final ClickerThemeDef theme;
  final String label;
  final Color current;
  final ValueChanged<Color> onPick;
  const _ColorRow({
    required this.theme,
    required this.label,
    required this.current,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: current,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: theme.accentLight, width: 2),
                ),
              ),
              const SizedBox(width: 10),
              Text(label, style: Clicker.body(13, theme: theme)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c
                  in _CustomThemeScreenState._palette)
                GestureDetector(
                  onTap: () => onPick(c),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: c.toARGB32() == current.toARGB32()
                            ? Colors.white
                            : Colors.black.withValues(alpha: 0.4),
                        width: c.toARGB32() == current.toARGB32()
                            ? 3
                            : 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
