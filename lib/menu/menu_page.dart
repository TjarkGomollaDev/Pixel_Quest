import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/game/level/background_szene.dart';
import 'package:pixel_adventure/data/level_data.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/menu/character_picker.dart';
import 'package:pixel_adventure/menu/dummy_character.dart';
import 'package:pixel_adventure/menu/level_tile.dart';
import 'package:pixel_adventure/menu/menu_header.dart';
import 'package:pixel_adventure/menu/previous_next_btn.dart';
import 'package:pixel_adventure/pixel_quest.dart';

class MenuPage extends World with HasGameReference<PixelQuest> {
  StreamSubscription? _sub;

  // back and foreground
  late final ParallaxComponent _menuBackground;
  late final SpriteComponent _menuForeground;

  // btns
  late final MenuHeader _menuHeader;
  late final PreviousNextBtn _previousWorldBtn;
  late final PreviousNextBtn _nextWorldBtn;

  // level grid
  final Map<String, LevelTile> _levelGrid = {};
  late final Vector2 _levelGridSize;
  late final Vector2 _levelGridPosition;
  static final Vector2 _tileSpacing = Vector2(32, 16);
  static const double _levelGridChangeWorldBtnsSpacing = 20;

  // character picker
  late final CharacterPicker _characterPicker;

  @override
  FutureOr<void> onLoad() {
    _setUpMenuBackground();
    _setUpMenuForeground();
    _setUpTitle();
    _setUpMenuHeader();
    _setUpLevelTiles();
    _setUpChangeWorldBtns();
    _setUpCharacterPicker();
    return super.onLoad();
  }

  @override
  void onMount() {
    debugPrint('mount');
    game.setUpCameraForMenu();
    _sub ??= game.storageCenter.onLevelDataChanged.listen((uuid) {
      _levelGrid[uuid]?.updateStars();
    });

    super.onMount();
  }

  void _setUpMenuBackground() {
    _menuBackground = BackgroundSzene(szene: Szene.szene1, position: Vector2.zero(), size: game.size);
    add(_menuBackground);
  }

  void _setUpMenuForeground() async {
    final sprite = loadSprite(game, 'Menu/Menu_Foreground.png');
    _menuForeground = SpriteComponent(sprite: sprite, size: game.size, anchor: Anchor.center, position: game.size / 2);

    // simulate BoxFit.cover
    final imageRatio = sprite.image.width / sprite.image.height;
    final screenRatio = game.size.x / game.size.y;

    if (imageRatio > screenRatio) {
      // image is wider → height fits, width is cropped
      _menuForeground.size = Vector2(game.size.y * imageRatio, game.size.y);
    } else {
      // image is higher → width fits, height is cropped
      _menuForeground.size = Vector2(game.size.x, game.size.x / imageRatio);
    }

    add(_menuForeground);
  }

  void _setUpTitle() {
    final sprite = loadSprite(game, 'Menu/Menu_World.png');

    const double desiredHeight = 30;

    final double aspectRatio = sprite.srcSize.x / sprite.srcSize.y;

    final double calculatedWidth = desiredHeight * aspectRatio;
    final title = SpriteComponent(
      sprite: sprite,
      size: Vector2(calculatedWidth, desiredHeight),
      anchor: Anchor.topCenter,
      position: Vector2(game.size.x / 2, 18),
    );
    add(title);
  }

  void _setUpMenuHeader() {
    _menuHeader = MenuHeader();
    add(_menuHeader);
  }

  void _setUpLevelTiles() {
    final tileSize = Vector2(48, 32);
    _levelGridSize = tileSize * 4 + _tileSpacing * 3;
    _levelGridPosition = Vector2((game.size.x - _levelGridSize.x) / 2, 63);

    final tilePositions = [];
    for (var i = 0; i < 4; i++) {
      for (var j = 0; j < 4; j++) {
        final position =
            _levelGridPosition + Vector2(24, 21) + Vector2((tileSize.x + _tileSpacing.x) * j, (tileSize.y + _tileSpacing.y) * i);
        tilePositions.add(position);
      }
    }

    int index = 0;
    for (var position in tilePositions) {
      if (index >= allLevels.length) {
        // break;
        final levelMetadata = allLevels[5];
        final levelTile = LevelTile(levelMetadata: levelMetadata, position: position);
        add(levelTile);
        _levelGrid[levelMetadata.uuid] = levelTile;
      } else {
        final levelMetadata = allLevels[index];
        final levelTile = LevelTile(levelMetadata: levelMetadata, position: position);
        add(levelTile);
        _levelGrid[levelMetadata.uuid] = levelTile;
      }
      index++;
    }
  }

  void _setUpChangeWorldBtns() {
    final levelGridVerticalCenter = _levelGridPosition.y + _levelGridSize.y / 2;
    final btnHorizontalCenter = PreviousNextBtn.btnSize.x / 2;
    _previousWorldBtn = PreviousNextBtn(
      type: PreviousNextBtnType.previous,
      action: () {},
      position: Vector2(_levelGridPosition.x - _levelGridChangeWorldBtnsSpacing - btnHorizontalCenter, levelGridVerticalCenter),
    );
    _nextWorldBtn = PreviousNextBtn(
      type: PreviousNextBtnType.next,
      action: () {},
      position: Vector2(
        _levelGridPosition.x + _levelGridSize.x + _levelGridChangeWorldBtnsSpacing + btnHorizontalCenter,
        levelGridVerticalCenter,
      ),
    );
    addAll([_previousWorldBtn, _nextWorldBtn]);
  }

  void _setUpCharacterPicker() {
    _characterPicker = CharacterPicker(
      position: Vector2(
        game.size.x / 2 - 17 * GameSettings.tileSize + DummyCharacter.gridSize.x / 2,
        7 * GameSettings.tileSize + DummyCharacter.gridSize.y / 2,
      ),
    );
    add(_characterPicker);
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
