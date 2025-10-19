import 'dart:developer';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:pixel_adventure/extensions/build_context.dart';
import 'package:pixel_adventure/pixel_quest.dart';
import 'package:pixel_adventure/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureFlame();
  runApp(
    Builder(
      builder: (context) {
        final game = PixelQuest(safeScreenPadding: context.paddingOf);
        return GameWidget(
          game: game,
          loadingBuilder: (_) => const SplashScreen(),
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

Future<void> _configureFlame() async {
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();
}
