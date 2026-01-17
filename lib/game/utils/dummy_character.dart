import 'dart:async';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/level/player/player.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/pixel_quest.dart';

mixin DummyCharacter on SpriteAnimationGroupComponent, HasGameReference<PixelQuest> {
  // animation settings
  static final Vector2 gridSize = Vector2.all(32);
  static final Vector2 _textureSize = Vector2(32, 32);
  static const String _path = 'Main Characters/';
  static const String _pathEnd = ' (32x32).png';

  // all available characters and the current index
  final List<PlayerCharacter> allCharacters = [];
  int currentCharacterIndex = 0;

  // contains all animations of all characters
  final Map<PlayerCharacter, Map<PlayerState, SpriteAnimation>> allCharacterAnimations = {};

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _setUpAllCharacters();
    _loadAllSpriteAnimations();
    return super.onLoad();
  }

  void _initialSetup() {
    // debug
    if (GameSettings.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorMenu;
    }

    // general
    anchor = Anchor.center;
    priority = 5;
  }

  void _setUpAllCharacters() {
    allCharacters.addAll(PlayerCharacter.values);
    currentCharacterIndex = allCharacters.indexOf(game.storageCenter.settings.character);
  }

  void _loadAllSpriteAnimations() {
    for (var character in PlayerCharacter.values) {
      final loadAnimation = spriteAnimationWrapper<PlayerState>(
        game,
        '$_path${character.fileName}/',
        _pathEnd,
        GameSettings.stepTime,
        _textureSize,
      );
      allCharacterAnimations[character] = {for (final s in PlayerState.values) s: loadAnimation(s)};
    }

    animations = allCharacterAnimations[game.storageCenter.settings.character];
    current = PlayerState.idle;
  }
}
