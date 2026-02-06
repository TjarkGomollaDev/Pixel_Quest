import 'dart:ui';
import 'package:pixel_quest/app_theme.dart';

/// Enumerates all parallax background scenes and their metadata.
enum BackgroundScene {
  scene1('Scene 1', 4, AppTheme.miniMapBgScene1),
  scene2('Scene 2', 5, AppTheme.miniMapBgScene2),
  scene3('Scene 3', 4, AppTheme.miniMapBgScene3),
  scene4('Scene 4', 5, AppTheme.miniMapBgScene4),
  scene5('Scene 5', 3, AppTheme.miniMapBgScene5),
  scene6('Scene 6', 4, AppTheme.miniMapBgScene6);

  /// Scene sublist used for the level background picker.
  static const List<BackgroundScene> levelChoices = [.scene1, .scene6, .scene2];

  /// Scene sublist used for the loading overlay background picker.
  static const List<BackgroundScene> loadingChoices = [.scene3, .scene4, .scene5];

  // path
  static const String _basePath = 'Background/';
  static const String _pathEnd = '.png';
  static const String _pathOrig = 'orig_big_square';

  /// Returns the asset path for the square preview image shown in UI pickers.
  String get pathOrig => '$_basePath$fileName/$_pathOrig$_pathEnd';

  final String fileName;
  final int amount;
  final ({Color a, Color b, Color c}) miniMapBg;
  const BackgroundScene(this.fileName, this.amount, this.miniMapBg);

  static const BackgroundScene defaultScene = scene1;

  /// Returns the three minimap background colors as a list.
  List<Color> get miniMapBackgroundColors => [miniMapBg.a, miniMapBg.b, miniMapBg.c];

  /// Parse by enum name.
  /// - If [orNull] is true: returns null when not found.
  /// - Otherwise: returns [defaultScene] when not found.
  static BackgroundScene? fromName(String? name, {bool orNull = false}) {
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return orNull ? null : defaultScene;

    for (final scene in BackgroundScene.values) {
      if (scene.name == trimmed) return scene;
    }
    return orNull ? null : defaultScene;
  }
}

/// Enumerates colored-tile background variants and their metadata.
enum BackgroundColor {
  blue('Blue'),
  brown('Brown'),
  gray('Gray'),
  green('Green'),
  pink('Pink'),
  purple('Purple'),
  yellow('Yellow');

  final String fileName;
  const BackgroundColor(this.fileName);

  static const BackgroundColor defaultColor = blue;

  /// Parse by enum name.
  /// - If [orNull] is true: returns null when not found.
  /// - Otherwise: returns [defaultColor] when not found.
  static BackgroundColor? fromName(String? name, {bool orNull = false}) {
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return orNull ? null : defaultColor;

    for (final color in BackgroundColor.values) {
      if (color.name == trimmed) return color;
    }
    return orNull ? null : defaultColor;
  }
}
