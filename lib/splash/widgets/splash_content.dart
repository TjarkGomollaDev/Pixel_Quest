import 'package:flutter/material.dart';
import 'package:pixel_quest/app_theme.dart';
import 'package:pixel_quest/l10n/app_localizations.dart';
import 'package:pixel_quest/splash/flutter%20extensions/int_double_extensions.dart';
import 'package:pixel_quest/splash/widgets/loading_dots.dart';
import 'animated_stars.dart';

class SplashContent extends StatelessWidget {
  // constructor parameters
  final GlobalKey<AnimatedStarsState> starsKey;
  final AppLocalizations l10n;

  const SplashContent({super.key, required this.starsKey, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // stars
        AnimatedStars(key: starsKey),
        26.heightSizedBox,
        //  game title
        Image.asset('assets/images/Splash/Splash_Title.png', height: 68, filterQuality: FilterQuality.none),
        52.heightSizedBox,
        // loading container
        Container(
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
                    Text(l10n.loadingGame, style: AppTheme.splashText),
                    8.widthSizedBox,
                    LoadingDots(textStyle: AppTheme.splashText),
                  ],
                ),
              );
            },
          ),
        ),
        16.heightSizedBox,
      ],
    );
  }
}
