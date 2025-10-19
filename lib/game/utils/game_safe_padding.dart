class GameSafePadding {
  final double top;
  final double bottom;
  final double left;
  final double right;

  const GameSafePadding({required this.top, required this.bottom, required this.left, required this.right});

  @override
  String toString() => '[top: $top, bottom: $bottom, left: $left, right: $right]';

  double minLeft(double value) => left > value ? left : value;
  double minRight(double value) => right > value ? right : value;
  double minTop(double value) => top > value ? top : value;
  double minBottom(double value) => bottom > value ? bottom : value;
}
