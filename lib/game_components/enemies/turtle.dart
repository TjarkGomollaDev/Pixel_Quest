import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/game_components/level/player.dart';
import 'package:pixel_adventure/game_components/utils.dart';
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

class Turtle extends SpriteAnimationGroupComponent with HasGameReference<PixelAdventure>, CollisionCallbacks {
  final bool isLeft;

  Turtle({required this.isLeft, required super.position, required super.size, required Player player}) : _player = player;

  // actual hitbox
  final RectangleHitbox hitbox = RectangleHitbox(position: Vector2(10, 9), size: Vector2(29, 23));

  // player ref
  final Player _player;

  // animation settings
  final double _stepTime = 0.05;
  final Vector2 _textureSize = Vector2(44, 26);
  final String _path = 'Enemies/Turtle/';
  final String _pathEnd = ' (44x26).png';

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
      hitbox.debugColor = AppTheme.debugColorEnemieHitbox;
    }

    // general
    priority = PixelAdventure.enemieLayerLevel;
    hitbox.collisionType = CollisionType.passive;
    add(hitbox);
  }

  void _loadAllSpriteAnimations() {
    final loadAnimation = spriteAnimationWrapper<TurtleState>(game, _path, _pathEnd, _stepTime, _textureSize);

    // list of all animations
    animations = {for (var state in TurtleState.values) state: loadAnimation(state)};

    // set current animation state
    current = TurtleState.idleSpikesOut;

    if (!isLeft) flipHorizontallyAroundCenter();
  }

  void _startTimer() => _spikeTimer = Timer(_toggleDuration, onTick: _toggleSpikes, repeat: true);

  void _toggleSpikes() => _spikesAreOut ? _spikesIn() : _spikesOut()
    ..whenComplete(() => _spikesAreOut = !_spikesAreOut);

  Future<void> _spikesOut() async {
    current = TurtleState.spikesOut;
    await animationTickers![TurtleState.spikesOut]!.completed;
    current = TurtleState.idleSpikesOut;
  }

  Future<void> _spikesIn() async {
    current = TurtleState.spikesIn;
    await animationTickers![TurtleState.spikesIn]!.completed;
    current = TurtleState.idleSpikesIn;
  }

  void collidedWithPlayer(Vector2 collisionPoint) {
    if (_gotStomped) return;
    if (!_spikesAreOut && _player.velocity.y > 0 && collisionPoint.y < position.y + hitbox.position.y + game.toleranceEnemieCollision) {
      _gotStomped = true;
      _player.bounceUp();
      current = TurtleState.hit;
      animationTickers![TurtleState.hit]!.completed.whenComplete(() => removeFromParent());
    } else {
      _player.collidedWithEnemy();
    }
  }
}
