import 'dart:async';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/data/audio/audio_center.dart';
import 'package:pixel_adventure/data/static/metadata/world_metadata.dart';
import 'package:pixel_adventure/game/animations/spotlight.dart';
import 'package:pixel_adventure/game/events/game_event_bus.dart';
import 'package:pixel_adventure/game/game_router.dart';
import 'package:pixel_adventure/game/menu/components/character_bio.dart';
import 'package:pixel_adventure/game/menu/components/menu_dummy_character.dart';
import 'package:pixel_adventure/game/background/background_parallax.dart';
import 'package:pixel_adventure/game/utils/button.dart';
import 'package:pixel_adventure/game/utils/dots_indicator.dart';
import 'package:pixel_adventure/game/utils/dummy_character.dart';
import 'package:pixel_adventure/game/utils/input_blocker.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game/utils/visible_components.dart';
import 'package:pixel_adventure/game/game_settings.dart';
import 'package:pixel_adventure/game/menu/components/level_grid.dart';
import 'package:pixel_adventure/game/menu/components/menu_top_bar.dart';
import 'package:pixel_adventure/game/game.dart';

/// Menu that renders the selectable worlds + level grids.
///
/// Builds and switches all menu visuals (background/foreground/title/grid),
/// handles world navigation UI, and reacts to game events to keep the menu
/// state and animations in sync.
class MenuPage extends World with HasGameReference<PixelQuest>, HasTimeScale {
  // static content
  late final MenuTopBar _menuTopBar;
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

  // spotlight and dummy character
  late final Spotlight _spotlight;
  late final InputBlocker _inputBlockerSpotlight;
  late final CharacterBio _characterBio;
  late final MenuDummyCharacter _dummy;

  // spacing
  static const double _levelGridChangeWorldBtnsSpacing = 22; // [Adjustable]
  static const double _levelGridDotsIndicatorSpacing = 14; // [Adjustable]

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
    _setUpDotsIndicator();
    _setUpSpotlight();
    _setUpInputBlocker();
    _setUpCharacterBio();
    _setUpDummyCharacter();
    return super.onLoad();
  }

  @override
  void onMount() {
    _menuActive = true;
    _resume();
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
    _pause();
    game.audioCenter.stopBackgroundMusic();
    super.onRemove();
  }

  void dispose() {
    _removeSubscription();
  }

  void _addSubscription() {
    _sub = game.eventBus.listenMany((on) {
      on<GameLifecycleChanged>((event) {
        if (_menuActive && event.lifecycle == Lifecycle.paused) return _pause();
        if (_menuActive && event.lifecycle == Lifecycle.resumed) return _resume();
      });
      on<NewStarsEarned>((event) {
        _pendingNewStarsEarnedEvent = event;
      });
      on<InventoryStateChanged>((event) {
        if (event.action == PageAction.opend) return unawaited(_openInventory());
        if (event.action == PageAction.closed) return unawaited(_closeInventory());
      });
      on<InventoryChangedCharacter>((event) {
        _dummy.setCharacter(event.character);
      });
    });
  }

  void _removeSubscription() {
    _sub?.cancel();
    _sub = null;
  }

  void _setUpCurrentWorldIndex() =>
      _currentWorldIndex = game.staticCenter.allWorlds().getIndexByUUID(game.storageCenter.highestUnlockedWorld.uuid);

  void _setUpWorldBackgrounds() {
    for (final world in game.staticCenter.allWorlds()) {
      final background = BackgroundParallax.scene(
        scene: world.backgroundScene,
        position: Vector2.zero(),
        size: game.size,
        show: world.index == _currentWorldIndex,
      );
      add(background);
      _worldBackgrounds.add(background);
    }
  }

  void _setUpWorldForegrounds() async {
    for (final world in game.staticCenter.allWorlds()) {
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
    for (final world in game.staticCenter.allWorlds()) {
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
    for (final world in game.staticCenter.allWorlds()) {
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

  void _setUpSpotlight() {
    _spotlight = Spotlight(
      targetCenter: Vector2(
        game.size.x / 2 - 16 * GameSettings.tileSize + DummyCharacter.gridSize.x / 2,
        7 * GameSettings.tileSize + DummyCharacter.gridSize.y / 2,
      ),
    );
    add(_spotlight);
  }

  void _setUpInputBlocker() {
    _inputBlockerSpotlight = InputBlocker(size: game.size, priority: 99);
    add(_inputBlockerSpotlight);
  }

  void _setUpCharacterBio() {
    _characterBio = CharacterBio(
      position: _spotlight.targetCenter + Vector2(-Spotlight.playerTargetRadius + 22, Spotlight.playerTargetRadius + 32),
      show: false,
    )..priority = GameSettings.spotlightAnimationContentLayer;
    add(_characterBio);
  }

  void _setUpDummyCharacter() {
    _dummy = MenuDummyCharacter(defaultPosition: _spotlight.targetCenter, characterBio: _characterBio);
    add(_dummy);
  }

  void _changeWorld(int direction) async {
    if (_isChangingWorld) return;
    final oldIndex = _currentWorldIndex;
    final newIndex = _currentWorldIndex + direction;

    // index out of range
    if (newIndex < 0 || newIndex >= game.staticCenter.allWorlds().length) return;

    _currentWorldIndex = newIndex;
    _updateVisibleWorld(oldIndex, newIndex);
  }

  Future<void> _updateVisibleWorld(int oldIndex, int newIndex) async {
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

  int _getWorldIndex(String worldUuid) {
    if (worldUuid == game.staticCenter.allWorlds()[_currentWorldIndex].uuid) return _currentWorldIndex;

    // fallback
    return game.staticCenter.allWorlds().getIndexByUUID(worldUuid);
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

  void _pause() {
    timeScale = 0;
    _dummy.stop();
  }

  void _resume() {
    timeScale = 1;
    _dummy.start();
  }

  Future<void> _openInventory() async {
    _inputBlockerSpotlight.enable();
    await _spotlight.focusOnTarget();
    game.router.pushNamed(RouteNames.inventory);
    _characterBio.animatedShow();
  }

  Future<void> _closeInventory() async {
    _characterBio.hide();
    await _spotlight.expandToFull();
    _inputBlockerSpotlight.disable();
  }
}
