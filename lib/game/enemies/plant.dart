import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/data/audio/audio_center.dart';
import 'package:pixel_adventure/game/collision/collision.dart';
import 'package:pixel_adventure/game/collision/entity_collision.dart';
import 'package:pixel_adventure/game/enemies/plant_bullet.dart';
import 'package:pixel_adventure/game/hud/mini%20map/entity_on_mini_map.dart';
import 'package:pixel_adventure/game/level/player/player.dart';
import 'package:pixel_adventure/game/utils/animation_state.dart';
import 'package:pixel_adventure/game/utils/camera_culling.dart';
import 'package:pixel_adventure/game/utils/grid.dart';
import 'package:pixel_adventure/game/utils/load_sprites.dart';
import 'package:pixel_adventure/game/game_settings.dart';
import 'package:pixel_adventure/game/game.dart';

enum _PlantState implements AnimationState {
  idle('Idle', 11),
  attack('Attack', 8, loop: false),
  hit('Hit', 5, loop: false);

  @override
  final String fileName;
  @override
  final int amount;
  @override
  final bool loop;

  const _PlantState(this.fileName, this.amount, {this.loop = true});
}

/// A stationary enemy that periodically shoots projectiles.
///
/// The Plant plays an attack animation, spawns a bullet at the right moment,
/// and can optionally fire a second shot shortly after the first.
class Plant extends PositionComponent
    with FixedGridOriginalSizeGroupAnimation, EntityCollision, EntityOnMiniMap, HasGameReference<PixelQuest> {
  // constructor parameters
  final bool _isLeft;
  final bool _doubleShot;
  double _delay;
  final Player _player;

  Plant({required bool isLeft, required bool doubleShot, required double delay, required Player player, required super.position})
    : _isLeft = isLeft,
      _doubleShot = doubleShot,
      _delay = delay,
      _player = player,
      super(size: gridSize);

  // size
  static final Vector2 gridSize = Vector2.all(48);

  // actual hitbox
  final _hitbox = RectangleHitbox(position: Vector2(18, 18), size: Vector2(20, 30));

  // animation settings
  static final Vector2 _textureSize = Vector2(44, 42);
  static const String _path = 'Enemies/Plant/';
  static const String _pathEnd = ' (44x42).png';

  // start sound frame
  static const int _startShotSoundFrame = 6;

  // attack
  double _timeSinceLastAttack = 0;
  bool _isAttacking = false;
  final _timeUntilNextAttack = 5; // [Adjustable]
  final _delayBetweenDoubleShot = Duration(milliseconds: 500); // [Adjustable]

  // got stomped
  bool _gotStomped = false;

  @override
  FutureOr<void> onLoad() {
    _initialSetup();
    _loadAllSpriteAnimations();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (!_gotStomped) {
      if (_delay > 0) {
        _delay -= dt;
        return super.update(dt);
      }
      if (!_isAttacking) {
        _timeSinceLastAttack += dt;
        if (_timeSinceLastAttack >= _timeUntilNextAttack) unawaited(_startAttack());
      }
    }
    super.update(dt);
  }

  @override
  void onEntityCollision(CollisionSide collisionSide) {
    if (_gotStomped) return;

    // since only top collision is taken into account, we can also run through the plant, which can also trigger the top collision,
    // that's why there is an extra check to ensure that the player is really above the plant
    if (collisionSide == CollisionSide.top && _player.hitboxAbsoluteBottom <= position.y + _hitbox.position.y + 5) {
      _gotStomped = true;
      _player.bounceUp();

      // play hit animation and then remove from level
      game.audioCenter.playSound(Sfx.enemieHit, SfxType.game);
      animationGroupComponent.animationTickers![_PlantState.attack]?.onComplete?.call();
      animationGroupComponent.current = _PlantState.hit;
      animationGroupComponent.animationTickers![_PlantState.hit]!.completed.whenComplete(() => removeFromParent());
    }

    // the plant itself can not kill the player, only its bullet
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
    final loadAnimation = spriteAnimationWrapper<_PlantState>(game, _path, _pathEnd, GameSettings.stepTime, _textureSize);
    final animations = {for (final state in _PlantState.values) state: loadAnimation(state)};
    addAnimationGroupComponent(textureSize: _textureSize, animations: animations, current: _PlantState.idle);
    if (!_isLeft) flipHorizontallyAroundCenter();
  }

  Future<void> _startAttack() async {
    // start attack modus
    _isAttacking = true;

    // first attack
    if (!await _attack()) return;

    // second attack
    if (_doubleShot) {
      await Future.delayed(_delayBetweenDoubleShot);
      if (!await _attack()) return;
    }

    // end attack modus
    _isAttacking = false;
    _timeSinceLastAttack = 0;
  }

  Future<bool> _attack() async {
    if (_gotStomped) return false;
    animationGroupComponent.current = _PlantState.attack;

    // the sound should start during the attack animation, not before or after
    final ticker = animationGroupComponent.animationTickers![_PlantState.attack]!;
    ticker.onFrame = (frame) {
      if (frame == _startShotSoundFrame) {
        game.audioCenter.playSoundIf(Sfx.plantShot, game.isEntityInVisibleWorldRectX(_hitbox), SfxType.game);
        ticker.onFrame = null;
      }
    };
    await ticker.completed;

    if (_gotStomped) return false;
    _spawnBullet();
    animationGroupComponent.current = _PlantState.idle;
    return true;
  }

  void _spawnBullet() {
    final bulletOffset = Vector2(
      _isLeft
          ? _hitbox.position.x - PlantBullet.hitboxOffset.x - PlantBullet.hitboxRadius * 2
          : -_hitbox.position.x - PlantBullet.hitboxOffset.x,
      _hitbox.position.y - PlantBullet.hitboxOffset.y,
    );
    final bulletPosition = position + bulletOffset;
    final bullet = PlantBullet(isLeft: _isLeft, player: _player, position: bulletPosition);
    game.world.add(bullet);
  }
}
