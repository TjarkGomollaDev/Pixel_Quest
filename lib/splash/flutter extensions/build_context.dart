import 'package:flutter/material.dart';

extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  Size get sizeOf => MediaQuery.sizeOf(this);
  EdgeInsets get paddingOf => MediaQuery.paddingOf(this);
}
