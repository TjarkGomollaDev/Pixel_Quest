import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/extensions/build_context.dart';
import 'package:pixel_adventure/splash/animated_stars.dart';
import 'package:pixel_adventure/splash/developer_logo.dart';
import 'package:pixel_adventure/splash/splash_content.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final GlobalKey<DeveloperLogoState> _developerLogoKey = GlobalKey<DeveloperLogoState>();
  final GlobalKey<AnimatedStarsState> _starsKey = GlobalKey<AnimatedStarsState>();

  @override
  void initState() {
    super.initState();
    _runAnimationSequence();
  }

  Future<void> _runAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    await _starsKey.currentState?.startAnimation();
    _developerLogoKey.currentState?.startShimmer();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // background image
        Positioned.fill(
          child: Image.asset('assets/images/Splash/Splash_Background.png', fit: BoxFit.cover, filterQuality: FilterQuality.none),
        ),
        // foreground image
        Positioned.fill(
          child: Image.asset('assets/images/Splash/Splash_Foreground.png', fit: BoxFit.cover, filterQuality: FilterQuality.none),
        ),
        // blur layer
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
            child: Container(color: AppTheme.screenBlur),
          ),
        ),
        // content
        Positioned(
          top: context.sizeOf.height * 0.25,
          left: 0,
          right: 0,
          child: SplashContent(starsKey: _starsKey),
        ),
        // developer logo
        Positioned(
          left: 0,
          bottom: 20,
          child: SafeArea(
            bottom: false,
            minimum: EdgeInsets.only(left: 40),
            child: DeveloperLogo(key: _developerLogoKey),
          ),
        ),
      ],
    );
  }
}
