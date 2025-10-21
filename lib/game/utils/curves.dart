import 'dart:math';

import 'package:flutter/material.dart';

class FastStartAccelerateCurve extends Curve {
  @override
  double transform(double t) => 0.4 * t + 0.6 * t * t;
}

class JumpFallCurve extends Curve {
  @override
  double transform(double t) {
    return pow(t, 1.8).toDouble();
  }
}
