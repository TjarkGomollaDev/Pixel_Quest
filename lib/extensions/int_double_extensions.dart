import 'package:flutter/material.dart';

extension IntExtensions on int {
  Widget get widthSizedBox => SizedBox(width: toDouble());
  Widget get heightSizedBox => SizedBox(height: toDouble());
}

extension DoubleExtensions on double {
  Widget get widthSizedBox => SizedBox(width: toDouble());
  Widget get heightSizedBox => SizedBox(height: toDouble());
}
