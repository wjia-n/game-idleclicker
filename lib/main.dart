import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/settings_service.dart';
import 'theme/clicker_art.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final settings = ClickerSettings();
  final engineJson = await settings.load();
  final audio = ClickerAudio();
  audio.configure(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    volume: settings.volume,
  );
  runApp(IdleClickerApp(
    settings: settings,
    audio: audio,
    engineJson: engineJson,
  ));
}

class IdleClickerApp extends StatefulWidget {
  final ClickerSettings settings;
  final ClickerAudio audio;
  final Map<String, dynamic> engineJson;
  const IdleClickerApp(
      {super.key,
      required this.settings,
      required this.audio,
      required this.engineJson});

  @override
  State<IdleClickerApp> createState() => _IdleClickerAppState();
}

class _IdleClickerAppState extends State<IdleClickerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.audio.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) on interruption so music resumes exactly where it
    // left off; screens additionally freeze their engines.
    if (state == AppLifecycleState.paused) {
      widget.audio.onAppPaused();
      widget.settings.saveNow();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) => MaterialApp(
        title: 'Idle Clicker',
        debugShowCheckedModeBanner: false,
        theme: Clicker.theme(widget.settings.theme),
        home: SplashScreen(
          audio: widget.audio,
          settings: widget.settings,
          engineJson: widget.engineJson,
        ),
      ),
    );
  }
}
