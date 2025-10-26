import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/data/static/metadata/world_metadata.dart';
import 'package:pixel_adventure/game/level/background_szene.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game/utils/visible_components.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/menu/widgets/character_picker.dart';
import 'package:pixel_adventure/menu/widgets/dummy_character.dart';
import 'package:pixel_adventure/menu/widgets/level_grid.dart';
import 'package:pixel_adventure/menu/widgets/menu_header.dart';
import 'package:pixel_adventure/menu/widgets/previous_next_btn.dart';
import 'package:pixel_adventure/pixel_quest.dart';
import 'package:pixel_adventure/data/storage/storage_center.dart';

class MenuPage extends World with HasGameReference<PixelQuest>, HasTimeScale {
  StreamSubscription? _sub;

  // static content
  late final ParallaxComponent _menuBackground;
  late final MenuHeader _menuHeader;
  late final CharacterPicker _characterPicker;
  late final PreviousNextBtn _previousWorldBtn;
  late final PreviousNextBtn _nextWorldBtn;

  // worlds content
  final List<VisibleSpriteComponent> _worldTitles = [];
  final List<VisibleSpriteComponent> _worldForegrounds = [];
  final List<LevelGrid> _worldLevelGrids = [];

  // world index
  late int _currentWorldIndex;

  // spacing
  static const double _levelGridChangeWorldBtnsSpacing = 20;

  // animation event triggers
  NewStarsStorageEvent? _pendingWorldStorageEvent;

  bool _isChangingWorld = false;

  @override
  FutureOr<void> onLoad() {
    _setUpCurrentWorldIndex();
    _setUpMenuBackground();
    _setUpMenuHeader();
    _setUpWorldForegrounds();
    _setUpWorldTitles();
    _setUpWorldLevelGrids();
    _setUpChangeWorldBtns();
    _setUpCharacterPicker();
    return super.onLoad();
  }

  @override
  void onRemove() {
    debugPrint('onRemove');
    super.onRemove();
  }

  @override
  void onMount() {
    debugPrint('onMount');
    game.setUpCameraForMenu();
    _setUpSubscription();
    _checkForNewAnimationEvents();

    super.onMount();
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  void _setUpSubscription() {
    _sub ??= game.storageCenter.onDataChanged.listen((event) {
      if (event is NewStarsStorageEvent) {
        _menuHeader.updateStarsCount(index: _getWorldIndex(event.worldUuid), stars: event.totalStars);
        _pendingWorldStorageEvent = event;
      } else if (event is LevelStorageEvent) {
        // todo
      }
    });
  }

  int _getWorldIndex(String worldUuid) {
    if (worldUuid == game.staticCenter.allWorlds[_currentWorldIndex].uuid) return _currentWorldIndex;

    // fallback
    return game.staticCenter.allWorlds.getIndexByUUID(worldUuid);
  }

  Future<void> _checkForNewAnimationEvents() async {
    if (_pendingWorldStorageEvent != null) {
      await Future.delayed(Duration(milliseconds: 800));
      await _worldLevelGrids[_getWorldIndex(_pendingWorldStorageEvent!.worldUuid)].addNewStarsInTile(
        levelUuid: _pendingWorldStorageEvent!.levelUuid,
        stars: _pendingWorldStorageEvent!.newStars,
      );
      await Future.delayed(Duration(milliseconds: 200));
      await _menuHeader.starsCountAnimation(_pendingWorldStorageEvent!.newStars);
    }
    _pendingWorldStorageEvent = null;
  }

  void _setUpCurrentWorldIndex() =>
      _currentWorldIndex = game.staticCenter.allWorlds.getIndexByUUID(game.storageCenter.highestUnlockedWorld.uuid);

  void _setUpMenuBackground() {
    _menuBackground = BackgroundSzene(szene: Szene.szene1, position: Vector2.zero(), size: game.size);
    add(_menuBackground);
  }

  void _setUpMenuHeader() {
    _menuHeader = MenuHeader(startWorldIndex: _currentWorldIndex);
    add(_menuHeader);
  }

  void _setUpWorldForegrounds() async {
    for (var world in game.staticCenter.allWorlds) {
      final sprite = loadSprite(game, 'Menu/Worlds/${world.foreGroundFileName}.png');
      final size = calculateSizeForBoxFit(sprite.srcSize, game.size);
      final foreground = VisibleSpriteComponent(
        sprite: sprite,
        size: size,
        anchor: Anchor.center,
        position: game.size / 2,
        show: world.index == _currentWorldIndex,
      );
      add(foreground);
      _worldForegrounds.add(foreground);
    }
  }

  void _setUpWorldTitles() {
    for (var world in game.staticCenter.allWorlds) {
      final sprite = loadSprite(game, 'Menu/Worlds/${world.titleFileName}.png');
      final size = calculateSizeForHeight(sprite.srcSize, 30);
      final title = VisibleSpriteComponent(
        sprite: sprite,
        size: size,
        anchor: Anchor.topCenter,
        position: Vector2(game.size.x / 2, 16),
        show: world.index == _currentWorldIndex,
      );
      add(title);
      _worldTitles.add(title);
    }
  }

  void _setUpWorldLevelGrids() {
    for (var world in game.staticCenter.allWorlds) {
      final levelGrid = LevelGrid(worldUuid: world.uuid, show: world.index == _currentWorldIndex);
      add(levelGrid);
      _worldLevelGrids.add(levelGrid);
    }
  }

  void _setUpChangeWorldBtns() {
    final levelGridVerticalCenter = _worldLevelGrids[0].position.y + _worldLevelGrids[0].size.y / 2;
    final btnHorizontalCenter = PreviousNextBtn.btnSize.x / 2;
    _previousWorldBtn = PreviousNextBtn(
      type: PreviousNextBtnType.previous,
      action: () => _changeWorld(-1),
      position: Vector2(_worldLevelGrids[0].position.x - _levelGridChangeWorldBtnsSpacing - btnHorizontalCenter, levelGridVerticalCenter),
    );
    _nextWorldBtn = PreviousNextBtn(
      type: PreviousNextBtnType.next,
      action: () => _changeWorld(1),
      position: Vector2(
        _worldLevelGrids[0].position.x + _worldLevelGrids[0].size.x + _levelGridChangeWorldBtnsSpacing + btnHorizontalCenter,
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

  void _changeWorld(int direction) async {
    if (_isChangingWorld) return;
    final oldIndex = _currentWorldIndex;
    final newIndex = _currentWorldIndex + direction;

    // index out of range
    if (newIndex < 0 || newIndex >= game.staticCenter.allWorlds.length) return;

    _currentWorldIndex = newIndex;
    _updateContent(oldIndex, newIndex);
  }

  Future<void> _updateContent(int oldIndex, int newIndex) async {
    _isChangingWorld = true;
    _worldTitles[oldIndex].hide();
    _worldTitles[newIndex].show();
    _worldForegrounds[oldIndex].hide();
    _worldForegrounds[newIndex].show();
    _menuHeader.hideStarsCount(oldIndex);
    _menuHeader.showStarsCount(newIndex);
    _worldLevelGrids[oldIndex].hide();
    await _worldLevelGrids[newIndex].animatedShow(toLeft: newIndex > oldIndex);
    _isChangingWorld = false;
  }

  void pauseMenu() {
    timeScale = 0;
    _characterPicker.pause();
  }

  void resumeMenu() {
    timeScale = 1;
    _characterPicker.resume();
  }
}
