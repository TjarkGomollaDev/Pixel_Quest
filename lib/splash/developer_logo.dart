import 'package:flutter/widgets.dart';
import 'package:pixel_adventure/app_theme.dart';
import 'package:pixel_adventure/extensions/int_double_extensions.dart';

class DeveloperLogo extends StatelessWidget {
  const DeveloperLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: AppTheme.black,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              border: BoxBorder.all(color: AppTheme.ingameText),
              borderRadius: BorderRadius.circular(50).copyWith(bottomLeft: Radius.zero),
            ),
            child: Center(
              child: Text(
                'by',
                style: TextStyle(fontFamily: 'Pixel Font', fontSize: 8, color: AppTheme.ingameText),
              ),
            ),
          ),
          6.widthSizedBox,
          Text(
            'tj.studios',
            style: TextStyle(fontFamily: 'Pixel Font', fontSize: 8, color: AppTheme.ingameText),
          ),
        ],
      ),
    );
  }
}
