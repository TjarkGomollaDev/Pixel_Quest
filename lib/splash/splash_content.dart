import 'package:flutter/material.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/extensions/int_double_extensions.dart';
import 'package:pixel_adventure/splash/loading_dots.dart';
import 'package:shimmer/shimmer.dart';
import 'animated_stars.dart';

class SplashContent extends StatefulWidget {
  const SplashContent({super.key});

  @override
  State<SplashContent> createState() => _SplashContentState();
}

class _SplashContentState extends State<SplashContent> {
  final GlobalKey<AnimatedStarsState> _starsKey = GlobalKey<AnimatedStarsState>();
  bool _startShimmer = false;

  @override
  void initState() {
    super.initState();
    _startAnimations();
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    await _starsKey.currentState?.startAnimation();
    setState(() => _startShimmer = true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // stars
        AnimatedStars(key: _starsKey),
        20.heightSizedBox,
        // game title
        Shimmer.fromColors(
          baseColor: AppTheme.ingameText,
          highlightColor: AppTheme.ingameTextShimmer,
          period: Duration(milliseconds: 1600),
          loop: 1,
          enabled: _startShimmer,
          child: Text(
            'PIXEL QUEST',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Pixel Font', fontSize: 38, letterSpacing: 2),
          ),
        ),
        24.heightSizedBox,
        // loading container
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: AppTheme.tileBlur),
            child: Builder(
              builder: (context) {
                final screenHeight = MediaQuery.of(context).size.height;
                final offsetY = screenHeight * 0.002; // correction, as the font has a slight vertical offset
                return Transform.translate(
                  offset: Offset(0, offsetY),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Loading World',
                        style: TextStyle(fontFamily: 'Pixel Font', fontSize: 12, color: AppTheme.ingameText),
                      ),
                      8.widthSizedBox,
                      LoadingDots(
                        textStyle: TextStyle(fontFamily: 'Pixel Font', fontSize: 12, color: AppTheme.ingameText),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
