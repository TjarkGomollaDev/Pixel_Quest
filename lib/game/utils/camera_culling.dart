import 'package:flame/collisions.dart';
import 'package:pixel_quest/game/game.dart';

/// Small helpers for checking whether something is currently inside the camera view.
///
/// This is useful for simple “only update/spawn when on screen” logic without
/// coupling your entities too tightly to the camera.
extension CameraVisibility on PixelQuest {
  /// Returns `true` if the hitbox overlaps the camera's visible area on the X axis.
  ///
  /// [buffer] expands the visible range a bit on both sides.
  bool isEntityInVisibleWorldRectX(ShapeHitbox hitbox, {double buffer = 0}) {
    final rect = hitbox.toAbsoluteRect();
    final v = camera.visibleWorldRect;
    final left = v.left - buffer;
    final right = v.right + buffer;
    return rect.right > left && rect.left < right;
  }
}
