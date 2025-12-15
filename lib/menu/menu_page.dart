import 'dart:async';
import 'package:flame/components.dart';
import 'package:pixel_adventure/data/audio/audio_center.dart';
import 'package:pixel_adventure/data/static/metadata/world_metadata.dart';
import 'package:pixel_adventure/game/level/background_szene.dart';
import 'package:pixel_adventure/game/utils/button.dart';
import 'package:pixel_adventure/game/utils/dummy_character.dart';
import 'package:pixel_adventure/game/utils/input_blocker.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game/utils/visible_components.dart';
import 'package:pixel_adventure/game_settings.dart';
import 'package:pixel_adventure/menu/widgets/character_picker.dart';
import 'package:pixel_adventure/menu/widgets/level_grid.dart';
import 'package:pixel_adventure/menu/widgets/menu_top_bar.dart';
import 'package:pixel_adventure/pixel_quest.dart';
import 'package:pixel_adventure/data/storage/storage_center.dart';

class MenuPage extends World with HasGameReference<PixelQuest>, HasTimeScale {
  // subscription on storage center
  StreamSubscription? _sub;

  // static content
  late final MenuTopBar _menuTopBar;
  late final CharacterPicker _characterPicker;
  late final InputBlocker _blockerWhenSpotlight;
  late final SpriteBtn _previousWorldBtn;
  late final SpriteBtn _nextWorldBtn;

  // worlds content
  final List<BackgroundSzene> _worldBackgrounds = [];
  final List<VisibleSpriteComponent> _worldForegrounds = [];
  final List<VisibleSpriteComponent> _worldTitles = [];
  final List<LevelGrid> _worldLevelGrids = [];

  // world index
  late int _currentWorldIndex;

  // spacing
  static const double _levelGridChangeWorldBtnsSpacing = 22;

  // animation event triggers
  NewStarsStorageEvent? _pendingWorldStorageEvent;

  // flag for animation when world is changing
  bool _isChangingWorld = false;

  @override
  FutureOr<void> onLoad() {
    _setUpCurrentWorldIndex();
    _setUpWorldBackgrounds();
    _setUpWorldForegrounds();
    _setUpWorldTitles();
    _setUpWorldLevelGrids();
    _setUpMenuTopBar();
    _setUpChangeWorldBtns();
    _setUpCharacterPicker();
    _setUpSubscription();
    return super.onLoad();
  }

  @override
  void onMount() {
    resumeMenu();
    game.setUpCameraForMenu();
    _checkForNewAnimationEvents();
    game.audioCenter.playBackgroundMusic(BackgroundMusic.menu);
    super.onMount();
  }

  @override
  void onRemove() {
    pauseMenu();
    game.audioCenter.stopBackgroundMusic();
    super.onRemove();
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _menuTopBar.dispose();
  }

  void _setUpSubscription() {
    _sub ??= game.storageCenter.onDataChanged.listen((event) {
      if (event is NewStarsStorageEvent) {
        _pendingWorldStorageEvent = event;
      }
    });
  }

  int _getWorldIndex(String worldUuid) {
    if (worldUuid == game.staticCenter.allWorlds[_currentWorldIndex].uuid) return _currentWorldIndex;

    // fallback
    return game.staticCenter.allWorlds.getIndexByUUID(worldUuid);
  }

  Future<void> _checkForNewAnimationEvents() async {
    if (_pendingWorldStorageEvent == null) return;
    await Future.delayed(Duration(milliseconds: 800));
    await _worldLevelGrids[_getWorldIndex(_pendingWorldStorageEvent!.worldUuid)].addNewStarsInTile(
      levelUuid: _pendingWorldStorageEvent!.levelUuid,
      stars: _pendingWorldStorageEvent!.newStars,
    );
    await Future.delayed(Duration(milliseconds: 200));
    await _menuTopBar.starsCountAnimation(
      index: _getWorldIndex(_pendingWorldStorageEvent!.worldUuid),
      newStars: _pendingWorldStorageEvent!.newStars,
      totalStars: _pendingWorldStorageEvent!.totalStars,
    );
    _pendingWorldStorageEvent = null;
  }

  void _setUpCurrentWorldIndex() =>
      _currentWorldIndex = game.staticCenter.allWorlds.getIndexByUUID(game.storageCenter.highestUnlockedWorld.uuid);

  void _setUpWorldBackgrounds() {
    for (var world in game.staticCenter.allWorlds) {
      final background = BackgroundSzene(
        szene: world.backgroundSzene,
        position: Vector2.zero(),
        size: game.size,
        show: world.index == _currentWorldIndex,
      );
      add(background);
      _worldBackgrounds.add(background);
    }
  }

  void _setUpWorldForegrounds() async {
    for (var world in game.staticCenter.allWorlds) {
      final sprite = loadSprite(game, 'Menu/Worlds/${world.foregroundFileName}.png');
      final size = calculateSizeForBoxFit(sprite.srcSize, game.size);
      final foreground = VisibleSpriteComponent(
        sprite: sprite,
        position: game.size / 2,
        size: size,
        anchor: Anchor.center,
        show: world.index == _currentWorldIndex,
      );
      add(foreground);
      _worldForegrounds.add(foreground);
    }
  }

  void _setUpWorldTitles() {
    for (var world in game.staticCenter.allWorlds) {
      final sprite = loadSprite(game, 'Menu/Worlds/${world.titleFileName}.png');
      final size = calculateSizeForHeight(sprite.srcSize, 28);
      final title = VisibleSpriteComponent(
        sprite: sprite,
        position: Vector2(game.size.x / 2, 16),
        size: size,
        anchor: Anchor.topCenter,
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

  void _setUpMenuTopBar() {
    _menuTopBar = MenuTopBar(startWorldIndex: _currentWorldIndex);
    add(_menuTopBar);
  }

  void _setUpChangeWorldBtns() {
    final levelGridVerticalCenter = _worldLevelGrids[0].position.y + _worldLevelGrids[0].size.y / 2;
    final btnHorizontalCenter = SpriteBtnType.btnSizeSmall.x / 2;
    _previousWorldBtn = SpriteBtn.fromType(
      type: SpriteBtnType.previousSmall,
      onPressed: () => _changeWorld(-1),
      position: Vector2(_worldLevelGrids[0].position.x - _levelGridChangeWorldBtnsSpacing - btnHorizontalCenter, levelGridVerticalCenter),
    );
    _nextWorldBtn = SpriteBtn.fromType(
      type: SpriteBtnType.nextSmall,
      onPressed: () => _changeWorld(1),
      position: Vector2(
        _worldLevelGrids[0].position.x + _worldLevelGrids[0].size.x + _levelGridChangeWorldBtnsSpacing + btnHorizontalCenter,
        levelGridVerticalCenter,
      ),
    );
    addAll([_previousWorldBtn, _nextWorldBtn]);
  }

  void _setUpCharacterPicker() {
    _blockerWhenSpotlight = InputBlocker(priorityWhenActive: GameSettings.chracterPicker - 1);
    _characterPicker = CharacterPicker(
      inputBlocker: _blockerWhenSpotlight,
      spotlightCenter: Vector2(
        game.size.x / 2 - 16 * GameSettings.tileSize + DummyCharacter.gridSize.x / 2,
        7 * GameSettings.tileSize + DummyCharacter.gridSize.y / 2,
      ),
    );
    addAll([_blockerWhenSpotlight, _characterPicker]);
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
    _worldBackgrounds[oldIndex].hide();
    _worldBackgrounds[newIndex].show();
    _worldForegrounds[oldIndex].hide();
    _worldForegrounds[newIndex].show();
    _worldTitles[oldIndex].hide();
    _worldTitles[newIndex].show();
    _menuTopBar.hideStarsCount(oldIndex);
    _menuTopBar.showStarsCount(newIndex);
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
