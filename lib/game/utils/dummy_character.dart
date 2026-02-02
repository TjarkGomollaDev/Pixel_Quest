import 'dart:async';
import 'package:flame/components.dart';
import 'package:pixel_quest/app_theme.dart';
import 'package:pixel_quest/game/level/player/player.dart';
import 'package:pixel_quest/game/utils/load_sprites.dart';
import 'package:pixel_quest/game/game_settings.dart';
import 'package:pixel_quest/game/game.dart';

/// A reusable mixin that turns any [SpriteAnimationGroupComponent] into a
/// lightweight "dummy" character preview.
///
/// This is useful for:
/// - character selection screens
/// - menus / settings previews
/// - UI widgets that need to display a player character without full player logic
///
/// What it does:
/// - loads and caches sprite animations for *all* [PlayerCharacter]s and *all* [PlayerState]s
/// - applies the currently selected character from storage on load
/// - exposes [changeChracter] to swap the preview instantly
///
/// Requirements:
/// - Must be mixed into a [SpriteAnimationGroupComponent] (so `animations` + `current` exist)
/// - Must have access to the game via [HasGameReference]
mixin DummyCharacter on SpriteAnimationGroupComponent, HasGameReference<PixelQuest> {
  // animation settings
  static final Vector2 gridSize = Vector2.all(32);
  static final Vector2 _textureSize = Vector2(32, 32);
  static const String _path = 'Main Characters/';
  static const String _pathEnd = ' (32x32).png';

  // contains all animations of all characters
  final Map<PlayerCharacter, Map<PlayerState, SpriteAnimation>> _allCharacterAnimations = {};
  PlayerCharacter? _currentCharacter;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllSpriteAnimations();
    return super.onLoad();
  }

  void _initialSetup() {
    // debug
    if (GameSettings.customDebugMode) {
      debugMode = true;
      debugColor = AppTheme.debugColorMenu;
    }

    // general
    anchor = Anchor.center;
    priority = 5;
  }

  void _loadAllSpriteAnimations() {
    for (final character in PlayerCharacter.values) {
      final loadAnimation = spriteAnimationWrapper<PlayerState>(
        game,
        '$_path${character.fileName}/',
        _pathEnd,
        GameSettings.stepTime,
        _textureSize,
      );
      _allCharacterAnimations[character] = {for (final s in PlayerState.values) s: loadAnimation(s)};
    }

    changeChracter(game.storageCenter.inventory.character);
    current = PlayerState.idle;
  }

  /// Switches the displayed character by swapping the [animations] map.
  ///
  /// If the given [character] is already active, this is a no-op.
  void changeChracter(PlayerCharacter character) {
    if (_currentCharacter != null && isCurrentCharacter(character)) return;
    animations = _allCharacterAnimations[character];
    _currentCharacter = character;
  }

  /// Returns true if [character] is currently displayed.
  bool isCurrentCharacter(PlayerCharacter character) => _currentCharacter == character;
}
