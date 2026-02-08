import 'package:flutter/material.dart';
import 'package:pixel_quest/app_theme.dart';
import 'package:pixel_quest/l10n/app_localizations.dart';
import 'package:pixel_quest/splash/widgets/animated_stars.dart';
import 'package:pixel_quest/splash/widgets/developer_logo.dart';
import 'package:pixel_quest/splash/widgets/splash_content.dart';

class SplashScreen extends StatefulWidget {
  final AppLocalizations l10n;

  const SplashScreen({super.key, required this.l10n});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final GlobalKey<DeveloperLogoState> _developerLogoKey = .new();
  final GlobalKey<AnimatedStarsState> _starsKey = .new();

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
          child: Image.asset('assets/images/Splash/Splash_Background2.png', fit: .cover, filterQuality: .none),
        ),
        // foreground image
        Positioned.fill(
          child: Image.asset('assets/images/Splash/Splash_Foreground.png', fit: .cover, filterQuality: .none),
        ),
        // blur layer
        Positioned.fill(
          child: BackdropFilter(
            filter: .blur(sigmaX: 6.0, sigmaY: 6.0),
            child: Container(color: AppTheme.screenBlur),
          ),
        ),
        // content
        Center(
          child: SplashContent(starsKey: _starsKey, l10n: widget.l10n),
        ),
        // developer logo
        Positioned(
          left: 0,
          bottom: 20,
          child: SafeArea(
            bottom: false,
            minimum: .only(left: 40),
            child: DeveloperLogo(key: _developerLogoKey),
          ),
        ),
      ],
    );
  }
}
