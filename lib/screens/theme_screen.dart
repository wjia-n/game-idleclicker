import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/clicker_art.dart';
import '../theme/clicker_themes.dart';
import 'custom_theme_screen.dart';

/// Theme picker: 12+ toy-shop color themes + 8 tap-toy styles.
/// Pro-only entries show a lock for free players.
class ThemeScreen extends StatefulWidget {
  final ClickerAudio audio;
  final ClickerSettings settings;
  const ThemeScreen({super.key, required this.audio, required this.settings});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  ClickerThemeDef get _t => widget.settings.theme;

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
          title: Text('Toy Shop', style: Clicker.display(22, theme: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🎨 Toy-shop themes',
                      style: Clicker.label(16, theme: t)),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.35,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: ClickerThemes.all.length + 1, // + custom
                    itemBuilder: (c, i) {
                      if (i == ClickerThemes.all.length) {
                        return _ThemeCard(
                          theme: t,
                          settings: s,
                          id: 'custom',
                          name: 'My Creation',
                          preview: s.customTheme,
                          onTap: () {
                            widget.audio.click();
                            if (!s.isPro) {
                              _lockedNote();
                              return;
                            }
                            Navigator.of(context)
                                .push(MaterialPageRoute(
                                    builder: (_) => CustomThemeScreen(
                                        audio: widget.audio,
                                        settings: s)))
                                .then((_) => setState(() {}));
                          },
                        );
                      }
                      final def = ClickerThemes.all[i];
                      return _ThemeCard(
                        theme: t,
                        settings: s,
                        id: def.id,
                        name: def.name,
                        preview: def,
                        onTap: () {
                          widget.audio.click();
                          s.setTheme(def.id);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text('🧸 Tap toy styles',
                      style: Clicker.label(16, theme: t)),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: TapStyles.all.length,
                    itemBuilder: (c, i) {
                      final st = TapStyles.all[i];
                      final locked =
                          !s.isPro && TapStyles.isPro(st.id);
                      final selected = s.tapStyleId == st.id;
                      return GestureDetector(
                        onTap: () {
                          widget.audio.click();
                          if (locked) {
                            _lockedNote();
                            return;
                          }
                          s.setTapStyle(st.id);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: selected
                                ? t.accent.withValues(alpha: 0.3)
                                : Colors.black.withValues(alpha: 0.25),
                            border: Border.all(
                              color: selected
                                  ? t.accentLight
                                  : t.accent.withValues(alpha: 0.4),
                              width: selected ? 2.5 : 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(st.emoji,
                                  style: const TextStyle(fontSize: 34)),
                              const SizedBox(height: 4),
                              Text(
                                locked ? '🔒 ${st.name}' : st.name,
                                style: Clicker.body(10, theme: t),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  if (!s.isPro) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        '🔒 More themes & toys unlock with PRO',
                        style: Clicker.body(13, theme: t),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _lockedNote() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔒 That one is PRO-only — see the PRO tab!',
            style: Clicker.body(14, theme: _t)),
        backgroundColor: _t.woodDeep,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final ClickerThemeDef theme; // current app theme (for text)
  final ClickerSettings settings;
  final String id;
  final String name;
  final ClickerThemeDef preview; // the theme being previewed
  final VoidCallback onTap;
  const _ThemeCard({
    required this.theme,
    required this.settings,
    required this.id,
    required this.name,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = settings.themeId == id;
    final locked = !settings.isPro &&
        (id == 'custom' || ClickerThemes.isProTheme(id));
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [preview.woodMid, preview.woodDeep],
          ),
          border: Border.all(
            color: selected ? preview.accentLight : preview.accent,
            width: selected ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [preview.starFace, preview.starEdge],
                ),
                border:
                    Border.all(color: preview.accent, width: 2.5),
              ),
              child: Center(
                child: Text('⭐', style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              locked ? '🔒 $name' : name,
              style: Clicker.label(12, theme: preview),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (selected)
              Text('✓ selected',
                  style: Clicker.body(10, theme: preview)),
          ],
        ),
      ),
    );
  }
}
