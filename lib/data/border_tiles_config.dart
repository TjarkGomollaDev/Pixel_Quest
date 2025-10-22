import 'dart:convert';
import 'package:flutter/services.dart';

class BorderTileConfig {
  final List<int> top;
  final List<int> right;
  final List<int> bottom;
  final List<int> left;
  final List<int> corners;

  BorderTileConfig({required this.top, required this.right, required this.bottom, required this.left, required this.corners});

  static Future<BorderTileConfig> load(String path) async {
    final jsonString = await rootBundle.loadString(path);
    final data = jsonDecode(jsonString);
    return BorderTileConfig(
      corners: [data['corners']['topLeft'], data['corners']['topRight'], data['corners']['bottomRight'], data['corners']['bottomLeft']],
      top: List<int>.from(data['borders']['top']),
      right: List<int>.from(data['borders']['right']),
      bottom: List<int>.from(data['borders']['bottom']),
      left: List<int>.from(data['borders']['left']),
    );
  }
}
