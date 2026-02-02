import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_quest/app_theme.dart';
import 'package:pixel_quest/data/audio/audio_center.dart';
import 'package:pixel_quest/game/collision/collision.dart';
import 'package:pixel_quest/game/collision/entity_collision.dart';
import 'package:pixel_quest/game/hud/mini%20map/entity_on_mini_map.dart';
import 'package:pixel_quest/game/level/player/player.dart';
import 'package:pixel_quest/game/utils/animation_state.dart';
import 'package:pixel_quest/game/utils/camera_culling.dart';
import 'package:pixel_quest/game/utils/grid.dart';
import 'package:pixel_quest/game/utils/load_sprites.dart';
import 'package:pixel_quest/game/game_settings.dart';
import 'package:pixel_quest/game/game.dart';

enum _TurtleState implements AnimationState {
  idleSpikesIn('Idle Spikes in', 14),
  idleSpikesOut('Idle Spikes out', 14),
  spikesIn('Spikes in', 8, loop: false),
  spikesOut('Spikes out', 8, loop: false),
  hit('Hit', 5, loop: false);

  @override
  final String fileName;
  @override
  final int amount;
  @override
  final bool loop;

  const _TurtleState(this.fileName, this.amount, {this.loop = true});
}

/// A stationary turtle enemy that periodically toggles its spikes in and out.
///
/// While spikes are out, the turtle hurts the player on contact; when spikes are in,
/// it can be stomped from above.
class Turtle extends PositionComponent
    with FixedGridOriginalSizeGroupAnimation, EntityCollision, EntityOnMiniMap, HasGameReference<PixelQuest> {
  // constructor parameters
  final bool _isLeft;
  double _delay;
  final Player _player;

  Turtle({required bool isLeft, required double delay, required Player player, required super.position})
    : _isLeft = isLeft,
      _delay = delay,
      _player = player,
      super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2(48, 32);

  // actual hitbox
  final RectangleHitbox _hitbox = RectangleHitbox(position: Vector2(10, 13), size: Vector2(29, 19));

  // animation settings
  static final Vector2 _textureSize = Vector2(44, 26);
  static const String _path = 'Enemies/Turtle/';
  static const String _pathEnd = ' (44x26).png';

  // activation frame
  static const int _spikesOutActivationFrame = 5;
  static const int _spikesInActivationFrame = 6;

  // timer
  late Timer _spikeTimer;
  bool _spikesAreOut = true;
  final double _toggleDuration = 3; // [Adjustable]

  // got stomped
  bool _gotStomped = false;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllSpriteAnimations();
    _startTimer();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (!_gotStomped) {
      if (_delay > 0) {
        _delay -= dt;
        return super.update(dt);
      }
      _spikeTimer.update(dt);
    }
    super.update(dt);
  }

  @override
  void onEntityCollision(CollisionSide collisionSide) {
    if (_gotStomped) return;
    if (!_spikesAreOut && collisionSide == CollisionSide.top) {
      _gotStomped = true;
      _player.bounceUp();

      // play hit animation and then remove from level
      game.audioCenter.playSound(Sfx.enemieHit, SfxType.game);
      animationGroupComponent.animationTickers![_TurtleState.spikesOut]?.onComplete?.call();
      animationGroupComponent.animationTickers![_TurtleState.spikesIn]?.onComplete?.call();
      animationGroupComponent.current = _TurtleState.hit;
      animationGroupComponent.animationTickers![_TurtleState.hit]!.completed.whenComplete(() => removeFromParent());
    } else {
      _player.collidedWithEnemy(collisionSide);
    }
  }

  @override
  ShapeHitbox get entityHitbox => _hitbox;

  void _initialSetup() {
    // debug
    if (GameSettings.customDebugMode) {
      debugMode = true;
      debugColor = AppTheme.debugColorEnemie;
      _hitbox.debugColor = AppTheme.debugColorEnemieHitbox;
    }

    // general
    priority = GameSettings.enemieLayerLevel;
    _hitbox.collisionType = CollisionType.passive;
    add(_hitbox);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<_TurtleState>(game, _path, _pathEnd, GameSettings.stepTime, _textureSize);
    final animations = {for (final state in _TurtleState.values) state: loadAnimation(state)};
    addAnimationGroupComponent(textureSize: _textureSize, animations: animations, current: _TurtleState.idleSpikesOut);
    if (!_isLeft) flipHorizontallyAroundCenter();
  }

  void _startTimer() {
    _spikeTimer = Timer(_toggleDuration, onTick: _toggleSpikes, repeat: true);
  }

  void _toggleSpikes() => _spikesAreOut ? unawaited(_spikesIn()) : unawaited(_spikesOut());

  Future<void> _spikesOut() async {
    animationGroupComponent.current = _TurtleState.spikesOut;
    final ticker = animationGroupComponent.animationTickers![_TurtleState.spikesOut]!;
    ticker.onFrame = (frame) {
      if (frame >= _spikesOutActivationFrame) {
        _spikesAreOut = true;
        ticker.onFrame = null;
      } else if (frame == _spikesOutActivationFrame - 1) {
        game.audioCenter.playSoundIf(Sfx.popIn, game.isEntityInVisibleWorldRectX(_hitbox), SfxType.game);
      }
    };
    await ticker.completed;
    if (_gotStomped) return;
    animationGroupComponent.current = _TurtleState.idleSpikesOut;
  }

  Future<void> _spikesIn() async {
    animationGroupComponent.current = _TurtleState.spikesIn;
    final ticker = animationGroupComponent.animationTickers![_TurtleState.spikesIn]!;
    ticker.onFrame = (frame) {
      if (frame >= _spikesInActivationFrame) {
        _spikesAreOut = false;
        ticker.onFrame = null;
      } else if (frame == _spikesInActivationFrame - 2) {
        game.audioCenter.playSoundIf(Sfx.popOut, game.isEntityInVisibleWorldRectX(_hitbox), SfxType.game);
      }
    };
    if (_gotStomped) return;
    await ticker.completed;
    if (_gotStomped) return;
    animationGroupComponent.current = _TurtleState.idleSpikesIn;
  }
}
