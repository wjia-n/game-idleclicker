import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const IdleClickerApp());

class IdleClickerApp extends StatelessWidget {
  const IdleClickerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Idle Clicker',
      tagline: 'Tap a star. Build an empire. Nap while it works.',
      emoji: '⭐',
      slug: 'idleclicker',
      howToPlay: '• Tap the big star to earn stardust\n• Spend stardust on upgrades in the shop\n• Auto-tappers earn while you\'re away\n• Prestige at 100K lifetime for a permanent boost',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) => IdleClickerScreen(players: players, callbacks: cb),
    );
  }
}
