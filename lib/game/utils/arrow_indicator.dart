import 'dart:ui';
import 'package:flame/components.dart';

enum ArrowDir { left, right }

class ArrowIndicator extends PositionComponent {
  // constructor parameters
  final ArrowDir dir;
  final Vector2 arrowSize;
  final Paint paint;

  ArrowIndicator({required this.dir, required this.arrowSize, required Color color, super.position, super.anchor = Anchor.center})
    : paint = Paint()..color = color;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final w = arrowSize.x;
    final h = arrowSize.y;

    final path = Path();
    if (dir == ArrowDir.left) {
      // tip left
      path.moveTo(-w / 2, 0);
      path.lineTo(w / 2, -h / 2);
      path.lineTo(w / 2, h / 2);
    } else {
      // tip right
      path.moveTo(w / 2, 0);
      path.lineTo(-w / 2, -h / 2);
      path.lineTo(-w / 2, h / 2);
    }
    path.close();

    canvas.drawPath(path, paint);
  }
}
