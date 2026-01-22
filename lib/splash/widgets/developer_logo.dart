import 'package:flutter/widgets.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/splash/flutter%20extensions/int_double_extensions.dart';
import 'package:shimmer/shimmer.dart';

class DeveloperLogo extends StatefulWidget {
  const DeveloperLogo({super.key});

  @override
  State<DeveloperLogo> createState() => DeveloperLogoState();
}

class DeveloperLogoState extends State<DeveloperLogo> {
  bool _shimmerEnabled = false;

  void startShimmer() => setState(() => _shimmerEnabled = true);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: AppTheme.black,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: BoxBorder.all(color: AppTheme.white),
              borderRadius: BorderRadius.circular(50).copyWith(bottomLeft: Radius.zero),
            ),
            child: Center(
              child: Text(
                'by',
                style: TextStyle(fontFamily: 'Pixel Font', fontSize: 8, color: AppTheme.white),
              ),
            ),
          ),
          6.widthSizedBox,
          Shimmer.fromColors(
            baseColor: AppTheme.white,
            highlightColor: AppTheme.whiteShimmer,
            period: Duration(milliseconds: 1000),
            loop: 1,
            enabled: _shimmerEnabled,
            child: Text(
              'tj.studios',
              style: TextStyle(fontFamily: 'Pixel Font', fontSize: 8, color: AppTheme.white),
            ),
          ),
        ],
      ),
    );
  }
}
