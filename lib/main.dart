import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/data/data_center.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureFlame();
  final dataCenter = await DataCenter.init();
  final game = PixelAdventure(dataCenter: dataCenter);
  runApp(GameWidget(game: game));
}

Future<void> _configureFlame() async {
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();
}
