import 'dart:developer';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:pixel_quest/l10n/app_localizations.dart';
import 'package:pixel_quest/game/game.dart';
import 'package:pixel_quest/splash/flutter%20extensions/build_context.dart';
import 'package:pixel_quest/splash/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefLangCode = 'lang_code';

void main() async {
  // ensure Flutter bindings and Flame device setup are ready before running the app
  WidgetsFlutterBinding.ensureInitialized();

  // basic config
  await _configureSystsemChrome();
  await _configureFlame();

  // load persisted locale once at startup (null = follow system locale)
  final prefs = await SharedPreferences.getInstance();
  final initialLocale = _localeFromCodeOrNull(prefs.getString(_prefLangCode));

  runApp(GameWrapper(prefs: prefs, initialLocale: initialLocale));
}

Future<void> _configureSystsemChrome() async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
}

Future<void> _configureFlame() async {
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();
}

Locale? _localeFromCodeOrNull(String? code) {
  if (code == null) return null;
  if (code == 'de') return const Locale('de');
  if (code == 'en') return const Locale('en');

  // fallback to system
  return null;
}

class GameWrapper extends StatefulWidget {
  final SharedPreferences prefs;
  final Locale? initialLocale;

  const GameWrapper({super.key, required this.prefs, required this.initialLocale});

  @override
  State<GameWrapper> createState() => _GameWrapperState();
}

class _GameWrapperState extends State<GameWrapper> {
  late Locale? _locale = widget.initialLocale;
  bool _removingGameForOneFrame = false;
  PixelQuest? _game;

  Future<void> _requestLocaleChange(Locale newLocale) async {
    await widget.prefs.setString(_prefLangCode, newLocale.languageCode);

    setState(() {
      _locale = newLocale;
      _removingGameForOneFrame = true;
      _game = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _removingGameForOneFrame = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          if (_removingGameForOneFrame) return SplashScreen(l10n: l10n);

          // create a fresh game instance
          _game ??= PixelQuest(l10n: l10n, requestLocaleChange: _requestLocaleChange, safeScreenPadding: context.paddingOf);

          return GameWidget(
            game: _game!,
            loadingBuilder: (_) => SplashScreen(l10n: l10n),
            errorBuilder: (_, error) {
              log(
                'Fatal error while loading the game',
                name: 'Pixel Quest',
                error: error,
                stackTrace: error is Error ? error.stackTrace : StackTrace.current,
                level: 1000, // severe fault
              );
              SchedulerBinding.instance.addPostFrameCallback((_) => SystemNavigator.pop());
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}
