import 'package:flutter/material.dart';

class AnimatedStars extends StatefulWidget {
  const AnimatedStars({super.key});

  @override
  State<AnimatedStars> createState() => AnimatedStarsState();
}

class AnimatedStarsState extends State<AnimatedStars> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    // three controllers – one for each star
    _controllers = List.generate(3, (i) => AnimationController(vsync: this, duration: const Duration(milliseconds: 280)));

    // bounce scale
    _animations = _controllers
        .map((c) => Tween<double>(begin: 1.0, end: 1.2).chain(CurveTween(curve: Curves.decelerate)).animate(c))
        .toList();
  }

  Future<void> startAnimation() async {
    for (int i = 0; i < _controllers.length; i++) {
      await _controllers[i].forward();
      await _controllers[i].reverse();
      await Future.delayed(const Duration(milliseconds: 40));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children:
          List.generate(3, (i) {
              final rotation = (i == 0)
                  ? -0.1
                  : (i == 2)
                  ? 0.1
                  : 0.0;
              final offset = (i == 1) ? const Offset(0, -5) : Offset.zero;
              return AnimatedBuilder(
                animation: _animations[i],
                builder: (context, child) {
                  return Transform.scale(
                    scale: _animations[i].value,
                    child: Transform.rotate(
                      angle: rotation,
                      child: Transform.translate(
                        offset: offset,
                        child: Image.asset(
                          fit: BoxFit.cover,
                          'assets/images/Other/Star (32x32).png',
                          width: 64,
                          height: 64,
                          filterQuality: FilterQuality.none,
                        ),
                      ),
                    ),
                  );
                },
              );
            }).expand((widget) sync* {
              yield widget;
              yield const SizedBox(width: 16);
            }).toList()
            ..removeLast(), //  remove last spacing
    );
  }
}
