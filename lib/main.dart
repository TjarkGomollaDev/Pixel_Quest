import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/pixel_quest.dart';
import 'package:pixel_adventure/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureFlame();
  final game = PixelQuest();
  runApp(GameWidget(game: game, loadingBuilder: (_) => SplashScreen()));
}

Future<void> _configureFlame() async {
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();
}
