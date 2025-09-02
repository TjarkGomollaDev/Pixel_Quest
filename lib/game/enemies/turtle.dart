import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game/level/player.dart';
import 'package:pixel_adventure/game/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum TurtleState implements AnimationState {
  idleSpikesIn('Idle Spikes in', 14),
  idleSpikesOut('Idle Spikes out', 14),
  spikesIn('Spikes in', 8, loop: false),
  spikesOut('Spikes out', 8, loop: false),
  hit('Hit', 5, loop: false);

  @override
  final String name;
  @override
  final int amount;
  @override
  final bool loop;

  const TurtleState(this.name, this.amount, {this.loop = true});
}

class Turtle extends PositionComponent
    with FixedGridOriginalSizeGroupAnimation, PlayerCollision, HasGameReference<PixelAdventure>, CollisionCallbacks {
  // constructor parameters
  final bool _isLeft;
  final Player _player;

  Turtle({required bool isLeft, required Player player, required super.position})
    : _isLeft = isLeft,
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

  // timer
  late Timer _spikeTimer;
  bool _spikesAreOut = true;
  final double _toggleDuration = 2; // [Adjustable]

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
    if (!_gotStomped) _spikeTimer.update(dt);
    super.update(dt);
  }

  void _initialSetup() {
    // debug
    if (game.customDebug) {
      debugMode = true;
      debugColor = AppTheme.debugColorEnemie;
      _hitbox.debugColor = AppTheme.debugColorEnemieHitbox;
    }

    // general
    priority = PixelAdventure.enemieLayerLevel;
    _hitbox.collisionType = CollisionType.passive;
    add(_hitbox);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<TurtleState>(game, _path, _pathEnd, PixelAdventure.stepTime, _textureSize);
    final animations = {for (var state in TurtleState.values) state: loadAnimation(state)};
    addAnimationGroupComponent(textureSize: _textureSize, animations: animations, current: TurtleState.idleSpikesOut);
    if (!_isLeft) flipHorizontallyAroundCenter();
  }

  void _startTimer() => _spikeTimer = Timer(_toggleDuration, onTick: _toggleSpikes, repeat: true);

  void _toggleSpikes() => _spikesAreOut ? _spikesIn() : _spikesOut()
    ..whenComplete(() => _spikesAreOut = !_spikesAreOut);

  Future<void> _spikesOut() async {
    animationGroupComponent.current = TurtleState.spikesOut;
    await animationGroupComponent.animationTickers![TurtleState.spikesOut]!.completed;
    animationGroupComponent.current = TurtleState.idleSpikesOut;
  }

  Future<void> _spikesIn() async {
    animationGroupComponent.current = TurtleState.spikesIn;
    await animationGroupComponent.animationTickers![TurtleState.spikesIn]!.completed;
    animationGroupComponent.current = TurtleState.idleSpikesIn;
  }

  @override
  void onPlayerCollisionStart(Vector2 intersectionPoint) {
    if (_gotStomped) return;
    if (!_spikesAreOut && _player.velocity.y > 0 && intersectionPoint.y < position.y + _hitbox.position.y + game.toleranceEnemieCollision) {
      _gotStomped = true;
      _player.bounceUp();
      animationGroupComponent.current = TurtleState.hit;
      animationGroupComponent.animationTickers![TurtleState.hit]!.completed.whenComplete(() => removeFromParent());
    } else {
      _player.collidedWithEnemy();
    }
  }
}
