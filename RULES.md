# Idle Clicker — "Starfall Tappers" — RULES

_The authoritative source of truth for this game. If the implementation
ever conflicts with this document, the implementation is wrong — fix it._

Idle Clicker is a cozy toy-shop incremental game: tap a chunky wooden
star, earn stardust, buy upgrades that earn for you, climb progression
tiers, and prestige (go supernova) for permanent bonuses. The game keeps
earning while you are away (offline earnings).

## 1. Objective

Earn as much stardust as possible. Tapping the star and buying upgrades
increases your stardust income. Climbing the five progression tiers
(Firefly → Starlight → Nebula → Galaxy → Universe) unlocks stronger
upgrades. Prestiging resets your stardust and upgrades in exchange for a
permanent +50% earnings bonus per prestige level.

## 2. Setup

- Every player starts with 0 stardust, 0 lifetime stardust, 0 taps, 0
  prestige, and no upgrades.
- Base tap power is 1 stardust per tap.
- The profile starts with the default tapper name "Star Tapper" and the
  free theme "Starlit Woodshop" + "Wooden Star" tap toy.
- 4 themes and 4 tap-toy styles are free; the other 8 themes, 4 styles
  and the custom theme creator are PRO-only.
- No player count: single player, no AI opponents.

## 3. Turn order

There are no turns — the game is continuous and real-time:

- The engine owns a single 200 ms tick timer that adds income
  (`perSec × 0.2` stardust per tick) and checks milestones, tier
  crossings and staged sequences.
- A 1 s watchdog verifies the tick timer is alive and re-arms any
  silently-dead staged sequence (prestige ceremony, turbo countdown).
- Engine phases are explicit: `running`, `prestiging` (staged ceremony),
  `paused` (app backgrounded). Every phase has a legal forward action and
  a recovery path; stuck states are impossible by construction.

## 4. Legal moves

While the phase is `running` the player may:

- **Tap** the star any number of times. Each tap grants `tapPower`
  stardust (×5 during Turbo). Taps also count toward the tap milestone.
- **Buy** one level of any upgrade that is (a) unlocked at the current
  tier and (b) affordable. Cost is deducted immediately.
- **Start Turbo** when no turbo is active: 30 seconds of ×5 tap power.
- **Prestige** when lifetime stardust ≥ 100,000 and no turbo is active.
  This opens a confirmation dialog, then runs the staged 4-step
  supernova ceremony owned by the engine.

## 5. Illegal moves

- Tapping during the `prestiging` or `paused` phase is ignored — the
  engine never changes state on it.
- Buying an upgrade that is tier-locked or unaffordable is rejected; the
  UI plays the invalid sound and no stardust is deducted.
- Starting Turbo while one is active, or during `prestiging`, is ignored.
- Starting Prestige while a turbo is active, during `prestiging`, or with
  lifetime stardust < 100,000 is ignored.

## 6. Captures

Not applicable — there is no board, no pieces and no opponent captures
in Idle Clicker.

## 7. Special rules

- **Upgrades** (6): Auto-Tapper (+1/s), Mega Tapper (+8/s), Tap Power
  (+1 per tap), Multiplier (×2 everything), Comet Collector (+40/s,
  unlocks at Nebula tier), Star Forge (×3 tap power, unlocks at Galaxy
  tier). Each level costs `baseCost × costGrowth^owned`.
- **Tap power formula:** `(powerLevels + 1) × (1 + prestige × 0.5) ×
  2^multiplierLevels × 3^starForgeLevels`.
- **Income formula:** `(tappers + 8×mega + 40×comet) × (1 + prestige ×
  0.5) × 2^multiplierLevels` stardust per second.
- **Prestige:** resets dust, lifetime and all upgrades to zero, keeps
  milestones and turbo best, and adds +1 prestige (+50% earnings forever,
  multiplicative with income and tap power). First prestige grants the
  Supernova milestone.
- **Turbo:** 30 s, taps worth ×5. Tap count is tracked; best turbo score
  persists. The countdown is engine-owned and the watchdog guarantees it
  always ends.
- **Offline earnings:** on return, the engine grants `perSec ×
  secondsAway`, capped at 8 hours (24 hours for PRO). Awards require at
  least 60 s away and income > 0. Measured against the persisted save
  timestamp, consumed exactly once — never double-granted.
- **Milestones** (7 one-time challenges): Warming Up (100 taps),
  First Thousand (hold 1,000), Little Workforce (10 Auto-Tappers),
  Nebula Bound (reach Nebula tier), Supernova (first prestige),
  Millionaire (1,000,000 lifetime), Turbo Hands (500 taps in one turbo).
  Each grants a stardust bonus and a celebration toast.

## 8. Scoring

- The score is stardust: current dust, lifetime dust, total taps,
  prestige count, upgrades owned, milestones completed, turbo best.
- Large numbers display abbreviated: 1.5K, 2.30M, 4.10B (floor below
  1,000).
- All progress persists across restarts in one JSON save document plus
  the order-preserving `idleclicker_player_names_json` names document.

## 9. Winning conditions

Idle Clicker is an endless game — there is no terminal win screen. The
progression ladder is the win path: reach higher tiers, complete all
milestones, and prestige repeatedly. Each prestige is a victory beat
(celebrated with a ceremony and a permanent bonus).

## 10. Draw conditions

Not applicable — single-player, no opponent, no draws.

## 11. AI strategy

Not applicable — there is no AI player. All progression math is
deterministic (formulas in §7); the only randomness is cosmetic
(confetti/audio). No bot difficulties are needed for an idle game.

## 12. Edge cases

- **Killed mid-prestige:** imports always resume in the `running` phase
  with a clean state — the ceremony is never half-applied.
- **Clock changes:** a saved timestamp in the future is ignored; the
  live heartbeat is used instead.
- **Offline cap:** earnings never exceed the 8 h (free) / 24 h (PRO)
  cap, no matter how long the app was closed.
- **Reset:** "Erase all" wipes dust, upgrades, prestige, milestones,
  turbo records AND the offline anchor — no stale grant afterwards.
- **Backgrounding:** the engine phase goes `paused`, audio pauses (not
  stops) and resumes exactly where it left off; a save is flushed.
- **Corrupt save:** decode failure falls back to a fresh game rather
  than crashing; legacy v1.0.1 keys and the v2 document are migrated
  once and old keys removed.
- **Name persistence:** names are stored as one order-preserving JSON
  string (`idleclicker_player_names_json`) via setString — never
  setStringList (Android stores StringLists as an unordered StringSet).

## 13. Test cases

1. Fresh install: dust 0, tap power 1, phase `running`, default name
   "Star Tapper", free theme/style selected.
2. Tap 10 times → dust increases by exactly 10 × tapPower; a floating
   "+N" number animates at the tap point.
3. Buy Auto-Tapper at 25 dust → dust drops by 25, owned becomes 1,
   perSec becomes 1; the card plays a buy pop animation.
4. Buying with insufficient dust returns false and plays the invalid
   sound; dust unchanged.
5. Comet Collector is locked (greyed, shows unlock tier) until lifetime
   ≥ 100,000 (Nebula); Star Forge until 1,000,000 (Galaxy).
6. Multiplier ×2: buying it doubles both perSec and tapPower.
7. Prestige is disabled until lifetime ≥ 100,000; starting it runs the
   4-stage ceremony, resets dust/upgrades, keeps milestones, prestige
   becomes 1, and income is permanently ×1.5.
8. Turbo: taps grant ×5 for 30 s; the round always ends (watchdog
   re-arms a dead timer); turbo best persists.
9. Milestones: tapping 100 times grants "Warming Up" + 250 dust and a
   toast exactly once.
10. Offline: kill the app with perSec > 0, reopen after 10 min → welcome
    back banner grants ≈ perSec × 600; reopen again immediately →
    no second grant.
11. Offline cap: away 30 h as free player grants at most perSec ×
    28,800 (8 h); PRO grants up to 86,400 s (24 h).
12. Rename: type in the name field → name updates on every keystroke;
    kill the app mid-typing → the name survives and stays in its slot
    (order-preserving JSON, never scrambled).
13. Audio: menu music starts behind the splash; entering the game
    switches to gameplay BGM; toggles + volume apply instantly and
    persist; audio never crashes or silently dies (lifecycle
    pause/resume, generation-serialized track changes).
14. PRO: before Play Console setup the Pro screen shows an honest
    "available after store setup" state with no fake buy buttons; after
    a real `idleclickerpro` purchase, PRO themes/styles/custom creator
    unlock and premium stays locked in free.
15. Watchdog: with the tick timer forcibly killed, the game self-heals
    within ~1 s and income resumes; no stuck state is reachable.
