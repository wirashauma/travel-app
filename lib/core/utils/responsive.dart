import 'package:flutter/material.dart';

/// Responsive utility for adaptive layouts
class Responsive {
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static bool isSmallScreen(BuildContext context) =>
      screenWidth(context) < 360;

  static bool isMediumScreen(BuildContext context) =>
      screenWidth(context) >= 360 && screenWidth(context) < 414;

  static bool isLargeScreen(BuildContext context) =>
      screenWidth(context) >= 414;

  /// Adaptive value based on screen width
  static double adaptive(BuildContext context,
      {required double sm, required double md, required double lg}) {
    if (isSmallScreen(context)) return sm;
    if (isMediumScreen(context)) return md;
    return lg;
  }

  /// Adaptive padding
  static EdgeInsets horizontalPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: adaptive(context, sm: 16, md: 20, lg: 24),
    );
  }

  /// Adaptive font scale
  static double fontScale(BuildContext context) {
    final width = screenWidth(context);
    if (width < 360) return 0.85;
    if (width < 414) return 1.0;
    return 1.1;
  }
}
