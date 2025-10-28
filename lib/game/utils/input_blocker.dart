import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:pixel_adventure/pixel_quest.dart';

class InputBlocker extends PositionComponent with HasGameReference<PixelQuest>, TapCallbacks {
  final int priorityWhenActive;

  InputBlocker({this.priorityWhenActive = 1, bool active = false}) {
    size = game.size;
    active ? activate() : deactivate();
  }

  @override
  void onTapDown(TapDownEvent event) {
    event.handled = true;
  }

  void activate() => priority = priorityWhenActive;

  void deactivate() => priority = -99;
}
