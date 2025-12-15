import 'package:flutter/material.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/splash/flutter%20extensions/int_double_extensions.dart';
import 'package:pixel_adventure/splash/widgets/loading_dots.dart';
import 'animated_stars.dart';

class SplashContent extends StatelessWidget {
  final GlobalKey<AnimatedStarsState> starsKey;

  const SplashContent({super.key, required this.starsKey});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // stars
        AnimatedStars(key: starsKey),
        16.heightSizedBox,
        //  game title
        Image.asset('assets/images/Splash/Splash_Title.png', height: 68, filterQuality: FilterQuality.none),
        34.heightSizedBox,
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
                        'Loading Game',
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
