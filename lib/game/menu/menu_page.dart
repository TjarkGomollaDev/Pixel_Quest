import 'dart:async';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/data/audio/audio_center.dart';
import 'package:pixel_adventure/data/static/metadata/world_metadata.dart';
import 'package:pixel_adventure/game/events/game_event_bus.dart';
import 'package:pixel_adventure/game/utils/background_parallax.dart';
import 'package:pixel_adventure/game/utils/button.dart';
import 'package:pixel_adventure/game/utils/dots_indicator.dart';
import 'package:pixel_adventure/game/utils/dummy_character.dart';
import 'package:pixel_adventure/game/utils/input_blocker.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game/utils/visible_components.dart';
import 'package:pixel_adventure/game/game_settings.dart';
import 'package:pixel_adventure/game/menu/widgets/character_picker.dart';
import 'package:pixel_adventure/game/menu/widgets/level_grid.dart';
import 'package:pixel_adventure/game/menu/widgets/menu_top_bar.dart';
import 'package:pixel_adventure/game/game.dart';

class MenuPage extends World with HasGameReference<PixelQuest>, HasTimeScale {
  // static content
  late final MenuTopBar _menuTopBar;
  late final CharacterPicker _characterPicker;
  late final InputBlocker _blockerWhenSpotlight;
  late final SpriteBtn _previousWorldBtn;
  late final SpriteBtn _nextWorldBtn;

  // worlds content
  final List<BackgroundParallax> _worldBackgrounds = [];
  final List<VisibleSpriteComponent> _worldForegrounds = [];
  final List<VisibleSpriteComponent> _worldTitles = [];
  final List<LevelGrid> _worldLevelGrids = [];

  // world index
  late int _currentWorldIndex;
  late final DotsIndicator _dotsIndicator;

  // spacing
  static const double _levelGridChangeWorldBtnsSpacing = 22;
  static const double _levelGridDotsIndicatorSpacing = 14;

  // animation event for new stars
  NewStarsEarned? _pendingNewStarsEarnedEvent;
  int _animationGuard = 0;
  bool _menuActive = false;

  // flag for animation when world is changing
  bool _isChangingWorld = false;

  // subscription for game events
  GameSubscription? _sub;

  @override
  FutureOr<void> onLoad() {
    _addSubscription();
    _setUpCurrentWorldIndex();
    _setUpWorldBackgrounds();
    _setUpWorldForegrounds();
    _setUpWorldTitles();
    _setUpWorldLevelGrids();
    _setUpMenuTopBar();
    _setUpChangeWorldBtns();
    _setUpCharacterPicker();
    _setUpDotsIndicator();
    return super.onLoad();
  }

  @override
  void onMount() {
    _menuActive = true;
    resumeMenu();
    game.setUpCameraForMenu();
    unawaited(_checkForNewStarsEvent());
    game.audioCenter.playBackgroundMusic(BackgroundMusic.menu);
    super.onMount();
  }

  @override
  void onRemove() {
    _menuActive = false;
    _animationGuard++;
    _abortNewStarsAnimationAndSync();
    pauseMenu();
    game.audioCenter.stopBackgroundMusic();
    super.onRemove();
  }

  void dispose() {
    _removeSubscription();
    _menuTopBar.dispose();
  }

  void _addSubscription() {
    _sub = GameEventBus.instance.listen<NewStarsEarned>((event) => _pendingNewStarsEarnedEvent = event);
  }

  void _removeSubscription() {
    _sub?.cancel();
    _sub = null;
  }

  void _setUpCurrentWorldIndex() =>
      _currentWorldIndex = game.staticCenter.allWorlds.getIndexByUUID(game.storageCenter.highestUnlockedWorld.uuid);

  void _setUpWorldBackgrounds() {
    for (var world in game.staticCenter.allWorlds) {
      final background = BackgroundParallax.szene(
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
    _blockerWhenSpotlight = InputBlocker(size: game.size, priority: GameSettings.chracterPicker - 1);
    _characterPicker = CharacterPicker(
      inputBlocker: _blockerWhenSpotlight,
      spotlightCenter: Vector2(
        game.size.x / 2 - 16 * GameSettings.tileSize + DummyCharacter.gridSize.x / 2,
        7 * GameSettings.tileSize + DummyCharacter.gridSize.y / 2,
      ),
    );
    addAll([_blockerWhenSpotlight, _characterPicker]);
  }

  void _setUpDotsIndicator() {
    _dotsIndicator = DotsIndicator(
      dotCount: 2,
      backgroundColor: AppTheme.tileBlur,
      position:
          _worldLevelGrids[0].position +
          Vector2(_worldLevelGrids[0].size.x / 2, _worldLevelGrids[0].size.y + _levelGridDotsIndicatorSpacing),
    );
    add(_dotsIndicator);
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
    // abort possible new stars animations
    _animationGuard++;
    _abortNewStarsAnimationAndSync();

    // update content
    _isChangingWorld = true;
    _dotsIndicator.activeIndex = newIndex;
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

  int _getWorldIndex(String worldUuid) {
    if (worldUuid == game.staticCenter.allWorlds[_currentWorldIndex].uuid) return _currentWorldIndex;

    // fallback
    return game.staticCenter.allWorlds.getIndexByUUID(worldUuid);
  }

  bool _shouldContinue(int guardSnapshot, NewStarsEarned eventSnapshot) {
    if (!_menuActive) return false;
    if (!isMounted) return false;
    if (_animationGuard != guardSnapshot) return false;
    if (_pendingNewStarsEarnedEvent != eventSnapshot) return false;
    return true;
  }

  Future<void> _checkForNewStarsEvent() async {
    // capture current event and gurad
    final eventSnapshot = _pendingNewStarsEarnedEvent;
    if (eventSnapshot == null) return;
    final guardSnapshot = _animationGuard;
    final worldIndex = _getWorldIndex(eventSnapshot.worldUuid);

    // visual delay + continue check
    await Future.delayed(Duration(milliseconds: 800));
    if (!_shouldContinue(guardSnapshot, eventSnapshot)) return;

    // new stars in single level tile animation + continue check
    await _worldLevelGrids[worldIndex].newStarsInTileAnimation(levelUuid: eventSnapshot.levelUuid, newStars: eventSnapshot.newStars);
    if (!_shouldContinue(guardSnapshot, eventSnapshot)) return;

    // visual delay + continue check
    await Future.delayed(Duration(milliseconds: 200));
    if (!_shouldContinue(guardSnapshot, eventSnapshot)) return;

    // new stars in total count animation + continue check
    await _menuTopBar.starsCountAnimation(index: worldIndex, newStars: eventSnapshot.newStars, totalStars: eventSnapshot.totalStars);
    if (!_shouldContinue(guardSnapshot, eventSnapshot)) return;

    // animation has been run through completely and the event has thus been processed
    _pendingNewStarsEarnedEvent = null;
  }

  void _abortNewStarsAnimationAndSync() {
    // capture current event
    final eventSnapshot = _pendingNewStarsEarnedEvent;
    if (eventSnapshot == null) return;

    final worldIndex = _getWorldIndex(eventSnapshot.worldUuid);

    // stop any running animations so nothing resumes later
    _worldLevelGrids[worldIndex].cancelNewStarsInTileAnimation(levelUuid: eventSnapshot.levelUuid);
    _menuTopBar.cancelStarsCountAnimation();

    // sync UI to final values
    _worldLevelGrids[worldIndex].setStarsInTile(levelUuid: eventSnapshot.levelUuid, stars: eventSnapshot.levelStars);
    _menuTopBar.setStarsCount(index: worldIndex, totalStars: eventSnapshot.totalStars);

    // clear pending event
    _pendingNewStarsEarnedEvent = null;
  }
}
