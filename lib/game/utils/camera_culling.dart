import 'package:flame/collisions.dart';
import 'package:pixel_adventure/game/game.dart';

extension CameraVisibility on PixelQuest {
  bool isEntityInVisibleWorldRectX(ShapeHitbox hitbox, {double buffer = 0}) {
    final rect = hitbox.toAbsoluteRect();
    final v = camera.visibleWorldRect;
    final left = v.left - buffer;
    final right = v.right + buffer;
    return rect.right > left && rect.left < right;
  }
}
