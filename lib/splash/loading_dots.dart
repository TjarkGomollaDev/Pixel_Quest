import 'package:flutter/material.dart';

class LoadingDots extends StatefulWidget {
  final TextStyle textStyle;
  final double dotSpacing;
  final double jumpHeight;
  final Duration duration;

  const LoadingDots({
    super.key,
    required this.textStyle,
    this.dotSpacing = 2,
    this.jumpHeight = 8,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration * 3)..repeat();

    _animations = List.generate(3, (i) {
      final start = i / 3;
      final end = (i + 1) / 3;
      return TweenSequence([
        TweenSequenceItem(
          tween: Tween(begin: 0.0, end: widget.jumpHeight).chain(CurveTween(curve: Curves.easeOut)),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween(begin: widget.jumpHeight, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
          weight: 50,
        ),
      ]).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.linear),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.textStyle.fontSize! * 1.5,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.dotSpacing / 2),
                child: Transform.translate(
                  offset: Offset(0, -_animations[i].value),
                  child: Text('.', style: widget.textStyle),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
