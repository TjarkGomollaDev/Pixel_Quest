import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/extensions/build_context.dart';
import 'package:pixel_adventure/splash/developer_logo.dart';
import 'package:pixel_adventure/splash/splash_content.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // background image
        Positioned.fill(
          child: Image.asset(
            'assets/images/Splash/Splash_Background.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.none,
          ),
        ),
        // foreground image
        Positioned.fill(
          child: Image.asset(
            'assets/images/Splash/Splash_Foreground.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.none,
          ),
        ),
        // blur layer
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
            child: Container(color: AppTheme.screenBlur),
          ),
        ),
        // content
        Positioned(top: context.sizeOf.height * 0.25, left: 0, right: 0, child: const SplashContent()),
        // developer logo
        Positioned(left: context.paddingOf.left, bottom: 26, child: const DeveloperLogo()),
      ],
    );
  }
}
