import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/clicker_art.dart';
import '../theme/clicker_themes.dart';

/// Idle Clicker PRO: Free-vs-Pro comparison, real purchase, restore, tip jar.
/// All prices come from the store — never hardcoded, never placeholders.
///
/// PRO IS COSMETIC/CONVENIENCE ONLY: extra themes, tap styles, the custom
/// theme creator, a profile badge and a longer offline-earnings cap.
/// It never multiplies earnings — no pay-to-win mechanics.
class ProScreen extends StatefulWidget {
  final ClickerAudio audio;
  final ClickerSettings settings;
  final StoreService store;

  const ProScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  ClickerThemeDef get _t => widget.settings.theme;

  @override
  void initState() {
    super.initState();
    widget.store.proPurchased.addListener(_onPro);
    widget.store.lastThanks.addListener(_onThanks);
  }

  void _onPro() {
    if (widget.store.proPurchased.value && mounted) {
      widget.settings.setPro(true);
      widget.audio.win();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PRO unlocked — enjoy everything!',
              style: Clicker.body(15, theme: _t)),
          backgroundColor: _t.woodDeep,
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.store.proPurchased.value = false;
    }
  }

  void _onThanks() {
    final msg = widget.store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Clicker.body(15, theme: _t)),
        backgroundColor: _t.woodDeep,
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.store.lastThanks.value = null;
  }

  @override
  void dispose() {
    widget.store.proPurchased.removeListener(_onPro);
    widget.store.lastThanks.removeListener(_onThanks);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    final store = widget.store;
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
          title: Text('Idle Clicker PRO', style: Clicker.display(22, theme: t)),
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
                  _ComparisonCard(theme: t, isPro: s.isPro),
                  const SizedBox(height: 16),
                  _BuyCard(
                    theme: t,
                    settings: s,
                    store: store,
                    audio: widget.audio,
                  ),
                  const SizedBox(height: 16),
                  _TipsCard(
                    theme: t,
                    store: store,
                    audio: widget.audio,
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

// ---------------------------------------------------------------------------
/// Free vs Pro comparison table — buyers see the big difference.
/// Pro is cosmetic/convenience only: full gameplay stays free.
class _ComparisonCard extends StatelessWidget {
  final ClickerThemeDef theme;
  final bool isPro;
  const _ComparisonCard({required this.theme, required this.isPro});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Complete clicker game', true, true),
      ('All upgrades & tiers', true, true),
      ('Prestige system', true, true),
      ('Turbo mode', true, true),
      ('Milestone challenges', true, true),
      ('Offline earnings (8h)', true, true),
      ('Music & sound effects', true, true),
      ('Toy-shop themes', '4', '12+'),
      ('Tap toy styles', '4', '8'),
      ('Custom theme creator', false, true),
      ('Offline earnings cap', '8h', '24h'),
      ('PRO profile badge', false, true),
      ('Earnings multipliers', 'never', 'never'),
    ];
    return ToyPanel(
      theme: theme,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        children: [
          Text('Free vs PRO', style: Clicker.display(20, theme: theme)),
          const SizedBox(height: 4),
          Text(
            'One purchase. Yours forever. Never pay-to-win.',
            style: Clicker.body(13,
                theme: theme,
                color: theme.paper.withValues(alpha: 0.7)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Header row.
          Row(
            children: [
              const Expanded(flex: 5, child: SizedBox()),
              Expanded(
                  flex: 2,
                  child: Text('FREE',
                      style: Clicker.label(12, theme: theme),
                      textAlign: TextAlign.center)),
              Expanded(
                  flex: 2,
                  child: Text('PRO',
                      style: Clicker.label(12, theme: theme),
                      textAlign: TextAlign.center)),
            ],
          ),
          const Divider(height: 14),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(r.$1, style: Clicker.body(13, theme: theme)),
                  ),
                  Expanded(flex: 2, child: _Cell(value: r.$2, theme: theme)),
                  Expanded(flex: 2, child: _Cell(value: r.$3, theme: theme)),
                ],
              ),
            ),
          if (isPro)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: theme.accent.withValues(alpha: 0.25),
                  border: Border.all(color: theme.accentLight),
                ),
                child: Text('✦ PRO ACTIVE ✦',
                    style: Clicker.label(14, theme: theme)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final Object value; // bool | String
  final ClickerThemeDef theme;
  const _Cell({required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (value is bool) {
      final v = value as bool;
      return Text(
        v ? '✓' : '—',
        style: Clicker.body(15,
            theme: theme,
            color: v
                ? theme.accentLight
                : theme.paper.withValues(alpha: 0.4)),
        textAlign: TextAlign.center,
      );
    }
    return Text(
      value as String,
      style: Clicker.label(12, theme: theme),
      textAlign: TextAlign.center,
    );
  }
}

// ---------------------------------------------------------------------------
class _BuyCard extends StatelessWidget {
  final ClickerThemeDef theme;
  final ClickerSettings settings;
  final StoreService store;
  final ClickerAudio audio;
  const _BuyCard({
    required this.theme,
    required this.settings,
    required this.store,
    required this.audio,
  });

  @override
  Widget build(BuildContext context) {
    final pro = store.proProduct;
    return ToyPanel(
      theme: theme,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        children: [
          Text('Unlock PRO', style: Clicker.display(20, theme: theme)),
          const SizedBox(height: 8),
          if (settings.isPro)
            Text('You already own PRO — thank you!',
                style: Clicker.body(14, theme: theme),
                textAlign: TextAlign.center)
          else if (!store.storeReady)
            Text(
              store.error ?? 'Available after store setup.',
              style: Clicker.body(14,
                  theme: theme,
                  color: theme.paper.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            )
          else if (pro != null) ...[
            Text(pro.description.isNotEmpty
                ? pro.description
                : 'Unlock everything in Idle Clicker, forever.',
                style: Clicker.body(14, theme: theme),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ValueListenableBuilder<bool>(
              valueListenable: store.purchaseInProgress,
              builder: (_, busy, _) => ChunkyButton(
                label: busy ? 'Working…' : 'Get PRO — ${pro.price}',
                width: 260,
                theme: theme,
                onTap: busy
                    ? () {}
                    : () {
                        audio.click();
                        store.buyPro();
                      },
              ),
            ),
          ],
          ValueListenableBuilder<String?>(
            valueListenable: store.purchaseError,
            builder: (_, err, _) => err == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(err,
                        style: Clicker.body(13,
                            theme: theme,
                            color: const Color(0xFFE08A8A)),
                        textAlign: TextAlign.center),
                  ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              audio.click();
              store.restore();
            },
            child: Text('Restore purchases',
                style: Clicker.label(13, theme: theme)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Consumable tips — pure support, with real store prices.
class _TipsCard extends StatelessWidget {
  final ClickerThemeDef theme;
  final StoreService store;
  final ClickerAudio audio;
  const _TipsCard(
      {required this.theme, required this.store, required this.audio});

  @override
  Widget build(BuildContext context) {
    final tips = [
      store.coffeeProduct,
      store.chocolateProduct,
    ].whereType<ProductDetails>().toList();
    return ToyPanel(
      theme: theme,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        children: [
          Text('Tip the Maker', style: Clicker.display(20, theme: theme)),
          const SizedBox(height: 8),
          Text(
            'Idle Clicker is free forever. A small tip keeps new games coming!',
            style: Clicker.body(14, theme: theme),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (!store.storeReady)
            Text(
              store.error ?? 'Available after store setup.',
              style: Clicker.body(13,
                  theme: theme,
                  color: theme.paper.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            )
          else if (tips.isEmpty)
            Text('Tips coming soon.',
                style: Clicker.body(13,
                    theme: theme,
                    color: theme.paper.withValues(alpha: 0.6)))
          else
            Wrap(
              spacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final p in tips)
                  _TipChip(
                    theme: theme,
                    label:
                        '${p.id == StoreService.chocolateId ? '🍫' : '☕'} ${p.price}',
                    onTap: () {
                      audio.click();
                      store.buyTip(p);
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TipChip extends StatelessWidget {
  final ClickerThemeDef theme;
  final String label;
  final VoidCallback onTap;
  const _TipChip(
      {required this.theme, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.black.withValues(alpha: 0.3),
          border:
              Border.all(color: theme.accent.withValues(alpha: 0.6), width: 1.5),
        ),
        child: Text(label, style: Clicker.label(14, theme: theme)),
      ),
    );
  }
}
