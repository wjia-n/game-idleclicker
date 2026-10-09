import 'package:flutter/material.dart';

/// Theme, tap-style catalog for Idle Clicker ("Starfall Tappers").
///
/// Every theme stays inside the cozy toy-shop material world: walnut wood,
/// brass, cream paper, jewel-tone accents. Playful physical materials —
/// chunky wood, lacquered paint, soft felt. No neon, no cyberpunk, no
/// generic Material look. Variety comes from different woods, paints,
/// paper tones and star colors.
class ClickerThemeDef {
  final String id;
  final String name;
  final Color woodDark;
  final Color woodMid;
  final Color woodDeep;
  final Color accent; // brass / copper / silver …
  final Color accentLight;
  final Color accentDark;
  final Color paper; // cream paper / ivory
  final Color felt;
  final Color starFace;
  final Color starEdge;
  final List<Color> highlight; // jewel tones for confetti / tiers

  const ClickerThemeDef({
    required this.id,
    required this.name,
    required this.woodDark,
    required this.woodMid,
    required this.woodDeep,
    required this.accent,
    required this.accentLight,
    required this.accentDark,
    required this.paper,
    required this.felt,
    required this.starFace,
    required this.starEdge,
    required this.highlight,
  });
}

class ClickerThemes {
  /// First 4 are the FREE starter themes. The rest are PRO.
  static const List<String> freeThemeIds = [
    'woodshop',
    'candy',
    'reef',
    'meadow',
  ];

  static bool isProTheme(String id) => !freeThemeIds.contains(id);

  static const List<ClickerThemeDef> all = [
    ClickerThemeDef(
      id: 'woodshop',
      name: 'Starlit Woodshop',
      woodDark: Color(0xFF3B2416),
      woodMid: Color(0xFF5C3A21),
      woodDeep: Color(0xFF241309),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      paper: Color(0xFFF7EFDC),
      felt: Color(0xFF1E4D3B),
      starFace: Color(0xFFFFC93C),
      starEdge: Color(0xFFD99420),
      highlight: [
        Color(0xFFA31621),
        Color(0xFF1D4E9E),
        Color(0xFF1B7A4D),
        Color(0xFFD99A2B),
      ],
    ),
    ClickerThemeDef(
      id: 'candy',
      name: 'Candy Store',
      woodDark: Color(0xFF5A2A38),
      woodMid: Color(0xFF7A3E4E),
      woodDeep: Color(0xFF3A1622),
      accent: Color(0xFFFFB3C6),
      accentLight: Color(0xFFFFD6E0),
      accentDark: Color(0xFFC96B87),
      paper: Color(0xFFFFF6F0),
      felt: Color(0xFF8A2B4A),
      starFace: Color(0xFFFF9EBB),
      starEdge: Color(0xFFD96A8D),
      highlight: [
        Color(0xFFD94F70),
        Color(0xFF7D3C98),
        Color(0xFF2E86C1),
        Color(0xFFE67E22),
      ],
    ),
    ClickerThemeDef(
      id: 'reef',
      name: 'Aqua Reef',
      woodDark: Color(0xFF14343C),
      woodMid: Color(0xFF1F4B54),
      woodDeep: Color(0xFF0A1E22),
      accent: Color(0xFF6FD3C6),
      accentLight: Color(0xFFB8EBE3),
      accentDark: Color(0xFF3E8F85),
      paper: Color(0xFFF0FBF8),
      felt: Color(0xFF145A66),
      starFace: Color(0xFF7FE3D6),
      starEdge: Color(0xFF3EA797),
      highlight: [
        Color(0xFF2471A3),
        Color(0xFF1E8449),
        Color(0xFFE67E22),
        Color(0xFF8E44AD),
      ],
    ),
    ClickerThemeDef(
      id: 'meadow',
      name: 'Meadow Picnic',
      woodDark: Color(0xFF3E4423),
      woodMid: Color(0xFF5A6336),
      woodDeep: Color(0xFF262B14),
      accent: Color(0xFFD9C93C),
      accentLight: Color(0xFFF1E58A),
      accentDark: Color(0xFF8F8225),
      paper: Color(0xFFFBF7E4),
      felt: Color(0xFF4A6B2F),
      starFace: Color(0xFFE8D53C),
      starEdge: Color(0xFFAC9A22),
      highlight: [
        Color(0xFF1B7A4D),
        Color(0xFFD99A2B),
        Color(0xFFA31621),
        Color(0xFF1D4E9E),
      ],
    ),
    ClickerThemeDef(
      id: 'berry',
      name: 'Berry Jam',
      woodDark: Color(0xFF3A1230),
      woodMid: Color(0xFF55204A),
      woodDeep: Color(0xFF240A1E),
      accent: Color(0xFFD16BA5),
      accentLight: Color(0xFFF0A8CC),
      accentDark: Color(0xFF8A3E6D),
      paper: Color(0xFFFBF0F6),
      felt: Color(0xFF5E1F52),
      starFace: Color(0xFFE58BB8),
      starEdge: Color(0xFFA34E7C),
      highlight: [
        Color(0xFFC0392B),
        Color(0xFF7D3C98),
        Color(0xFF1D4E9E),
        Color(0xFFD4AC0D),
      ],
    ),
    ClickerThemeDef(
      id: 'honey',
      name: 'Honey Bakery',
      woodDark: Color(0xFF4A2E12),
      woodMid: Color(0xFF6E4420),
      woodDeep: Color(0xFF2B1A08),
      accent: Color(0xFFE8A93C),
      accentLight: Color(0xFFFFD98A),
      accentDark: Color(0xFF9A6A20),
      paper: Color(0xFFFFF7E8),
      felt: Color(0xFF8A5A24),
      starFace: Color(0xFFFFBE4D),
      starEdge: Color(0xFFC07F1E),
      highlight: [
        Color(0xFFB26A00),
        Color(0xFF7D3C98),
        Color(0xFF1E8449),
        Color(0xFF2471A3),
      ],
    ),
    ClickerThemeDef(
      id: 'coral',
      name: 'Coral Shore',
      woodDark: Color(0xFF523021),
      woodMid: Color(0xFF73463A),
      woodDeep: Color(0xFF33180E),
      accent: Color(0xFFFF8A6B),
      accentLight: Color(0xFFFFBFA6),
      accentDark: Color(0xFFB2553D),
      paper: Color(0xFFFFF4EC),
      felt: Color(0xFF2E6B70),
      starFace: Color(0xFFFF9D7E),
      starEdge: Color(0xFFC65F40),
      highlight: [
        Color(0xFFE67E22),
        Color(0xFF2471A3),
        Color(0xFF1E8449),
        Color(0xFF8E44AD),
      ],
    ),
    ClickerThemeDef(
      id: 'mint',
      name: 'Mint Frost',
      woodDark: Color(0xFF1E3A36),
      woodMid: Color(0xFF33554F),
      woodDeep: Color(0xFF102019),
      accent: Color(0xFF9FE8C9),
      accentLight: Color(0xFFD4F7E6),
      accentDark: Color(0xFF5FA88A),
      paper: Color(0xFFF2FBF6),
      felt: Color(0xFF2F6B5A),
      starFace: Color(0xFFB3F0D4),
      starEdge: Color(0xFF6DB894),
      highlight: [
        Color(0xFF1B7A4D),
        Color(0xFF1D4E9E),
        Color(0xFF7D3C98),
        Color(0xFFD99A2B),
      ],
    ),
    ClickerThemeDef(
      id: 'rose',
      name: 'Rose Garden',
      woodDark: Color(0xFF4A1E26),
      woodMid: Color(0xFF68303C),
      woodDeep: Color(0xFF2C0E14),
      accent: Color(0xFFE58A8A),
      accentLight: Color(0xFFFFC2C2),
      accentDark: Color(0xFF9A5050),
      paper: Color(0xFFFFF2F0),
      felt: Color(0xFF4A6B2F),
      starFace: Color(0xFFF09D9D),
      starEdge: Color(0xFFB35C5C),
      highlight: [
        Color(0xFFA31621),
        Color(0xFFD99A2B),
        Color(0xFF1E8449),
        Color(0xFF7D3C98),
      ],
    ),
    ClickerThemeDef(
      id: 'choco',
      name: 'Choco Factory',
      woodDark: Color(0xFF2E1B10),
      woodMid: Color(0xFF4A2C18),
      woodDeep: Color(0xFF1A0E08),
      accent: Color(0xFFD4A25C),
      accentLight: Color(0xFFF0CD94),
      accentDark: Color(0xFF8A6234),
      paper: Color(0xFFF7EFE0),
      felt: Color(0xFF5C3A21),
      starFace: Color(0xFFE8B96A),
      starEdge: Color(0xFF9A6E30),
      highlight: [
        Color(0xFFCA8A2B),
        Color(0xFFA31621),
        Color(0xFF1D4E9E),
        Color(0xFF1B7A4D),
      ],
    ),
    ClickerThemeDef(
      id: 'amber',
      name: 'Amber Lantern',
      woodDark: Color(0xFF3A2410),
      woodMid: Color(0xFF553818),
      woodDeep: Color(0xFF221406),
      accent: Color(0xFFFFB84D),
      accentLight: Color(0xFFFFD98A),
      accentDark: Color(0xFFB37722),
      paper: Color(0xFFFFF8EA),
      felt: Color(0xFF6B4423),
      starFace: Color(0xFFFFC93C),
      starEdge: Color(0xFFC7861F),
      highlight: [
        Color(0xFFE67E22),
        Color(0xFF7D3C98),
        Color(0xFF2471A3),
        Color(0xFF1E8449),
      ],
    ),
    ClickerThemeDef(
      id: 'slate',
      name: 'Slate Workshop',
      woodDark: Color(0xFF23262E),
      woodMid: Color(0xFF383C46),
      woodDeep: Color(0xFF14161B),
      accent: Color(0xFFC0C6D4),
      accentLight: Color(0xFFE8ECF5),
      accentDark: Color(0xFF7E8698),
      paper: Color(0xFFF2F0EA),
      felt: Color(0xFF3A4A5E),
      starFace: Color(0xFFE3C566),
      starEdge: Color(0xFF9A7F35),
      highlight: [
        Color(0xFFD64545),
        Color(0xFF4A90D9),
        Color(0xFF3FB97F),
        Color(0xFFE0A83C),
      ],
    ),
  ];

  static ClickerThemeDef byId(String id, {ClickerThemeDef? custom}) {
    if (id == 'custom' && custom != null) return custom;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }

  static String displayName(String id) {
    if (id == 'custom') return 'My Creation';
    return byId(id).name;
  }
}

/// Tap-target styles — chunky physical toy shapes for the big tap button.
/// First 4 are FREE, the rest are PRO.
class TapStyleDef {
  final String id;
  final String name;
  final String emoji;
  const TapStyleDef({
    required this.id,
    required this.name,
    required this.emoji,
  });
}

class TapStyles {
  static const List<String> freeIds = ['star', 'coin', 'gem', 'moon'];

  static const List<TapStyleDef> all = [
    TapStyleDef(id: 'star', name: 'Wooden Star', emoji: '⭐'),
    TapStyleDef(id: 'coin', name: 'Brass Coin', emoji: '🪙'),
    TapStyleDef(id: 'gem', name: 'Polished Gem', emoji: '💎'),
    TapStyleDef(id: 'moon', name: 'Moon Rattle', emoji: '🌙'),
    TapStyleDef(id: 'heart', name: 'Love Locket', emoji: '💛'),
    TapStyleDef(id: 'gear', name: 'Brass Gear', emoji: '⚙️'),
    TapStyleDef(id: 'bell', name: 'Shop Bell', emoji: '🔔'),
    TapStyleDef(id: 'donut', name: 'Honey Donut', emoji: '🍩'),
  ];

  static bool isPro(String id) => !freeIds.contains(id);

  static TapStyleDef byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return all.first;
  }
}
