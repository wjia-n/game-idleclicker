import 'package:flutter/material.dart';
import 'clicker_themes.dart';

/// "Starfall Tappers" design helpers — cozy toy-shop materials: chunky
/// walnut wood, brass rivets, cream paper labels, soft felt. No neon,
/// no cyberpunk, no generic Material look.
///
/// All widgets accept an optional [ClickerThemeDef]; they default to the
/// Starlit Woodshop theme so existing call sites keep working.
class Clicker {
  static TextStyle display(double size,
          {Color? color, ClickerThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color ?? theme?.accentLight ?? const Color(0xFFE8CE7A),
        letterSpacing: 0.8,
        shadows: const [
          Shadow(color: Color(0xFF1A0F08), offset: Offset(0, 2), blurRadius: 4),
        ],
      );

  static TextStyle body(double size, {Color? color, ClickerThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? theme?.paper ?? const Color(0xFFF7EFDC),
        height: 1.35,
      );

  static TextStyle label(double size, {Color? color, ClickerThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color ?? theme?.accentLight ?? const Color(0xFFE8CE7A),
        letterSpacing: 0.9,
      );

  static ThemeData theme([ClickerThemeDef? t]) {
    t ??= ClickerThemes.byId('woodshop');
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: t.woodDark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: t.accent,
        onPrimary: t.woodDeep,
        secondary: t.accentLight,
        onSecondary: t.woodDeep,
        surface: t.woodMid,
        onSurface: t.paper,
        error: t.highlight[0],
        onError: t.paper,
      ),
      textTheme: TextTheme(
        displayLarge: display(34, theme: t),
        displayMedium: display(26, theme: t),
        titleLarge: display(22, theme: t),
        bodyLarge: body(16, theme: t),
        bodyMedium: body(14, theme: t),
        labelLarge: label(14, theme: t),
      ),
      dialogTheme: DialogThemeData(backgroundColor: t.woodMid),
    );
  }
}

/// Walnut wood-grain background with a warm vignette, theme-aware.
class ToyBackdrop extends StatelessWidget {
  final Widget child;
  final ClickerThemeDef? theme;
  const ToyBackdrop({super.key, required this.child, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? ClickerThemes.byId('woodshop');
    return Container(
      decoration: BoxDecoration(color: t.woodDark),
      child: CustomPaint(
        painter: _WoodGrainPainter(t),
        child: child,
      ),
    );
  }
}

class _WoodGrainPainter extends CustomPainter {
  final ClickerThemeDef t;
  _WoodGrainPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Warm vignette.
    final vignette = RadialGradient(
      center: const Alignment(0, -0.25),
      radius: 1.15,
      colors: [
        t.woodMid.withValues(alpha: 0.55),
        t.woodDark.withValues(alpha: 0.0),
        Colors.black.withValues(alpha: 0.5),
      ],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = vignette.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    // Gentle wood grain arcs.
    final grain = Paint()
      ..color = t.woodDeep.withValues(alpha: 0.35)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 9; i++) {
      final y = size.height * (0.08 + 0.11 * i);
      canvas.drawArc(
        Rect.fromLTWH(-size.width * 0.4, y, size.width * 1.8,
            size.height * 0.16),
        3.25,
        2.85,
        false,
        grain,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WoodGrainPainter old) =>
      old.t.id != t.id;
}

/// Chunky wooden button with brass border and a heavy drop shadow.
/// Physical, toy-like, highly readable.
class ChunkyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final ClickerThemeDef? theme;
  final double width;
  final double height;
  final bool enabled;
  final IconData? icon;

  const ChunkyButton({
    super.key,
    required this.label,
    required this.onTap,
    this.theme,
    this.width = 220,
    this.height = 56,
    this.enabled = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme ?? ClickerThemes.byId('woodshop');
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [t.accentLight, t.accent, t.accentDark],
            ),
            border: Border.all(color: t.woodDeep, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                offset: const Offset(0, 6),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: t.woodDeep, size: 22),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  style: Clicker.label(16,
                      theme: t, color: t.woodDeep),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chunky wooden panel with brass border — for stat readouts and cards.
class ToyPanel extends StatelessWidget {
  final Widget child;
  final ClickerThemeDef? theme;
  final EdgeInsetsGeometry padding;
  const ToyPanel({
    super.key,
    required this.child,
    this.theme,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final t = theme ?? ClickerThemes.byId('woodshop');
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            t.woodMid.withValues(alpha: 0.92),
            t.woodDeep.withValues(alpha: 0.95),
          ],
        ),
        border: Border.all(color: t.accent.withValues(alpha: 0.7), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Cream paper price tag chip.
class PriceTag extends StatelessWidget {
  final String text;
  final ClickerThemeDef? theme;
  const PriceTag({super.key, required this.text, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? ClickerThemes.byId('woodshop');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: t.paper,
        border: Border.all(color: t.accentDark, width: 1.5),
      ),
      child: Text(
        text,
        style: Clicker.label(12, theme: t, color: t.woodDeep),
      ),
    );
  }
}
