import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width < 1100 &&
      MediaQuery.of(context).size.width >= 650;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  // Padding cho mobile
  static EdgeInsets getMobilePadding() => EdgeInsets.all(16.w);
  
  // Padding cho tablet
  static EdgeInsets getTabletPadding() => EdgeInsets.all(24.w);

  // Card margin cho mobile vs tablet
  static EdgeInsets getCardMargin(BuildContext context) =>
      isMobile(context) 
        ? EdgeInsets.only(bottom: 12.h)
        : EdgeInsets.only(bottom: 16.h);

  // Font size tùy theo màn hình
  static double getTitleFontSize(BuildContext context) =>
      isMobile(context) ? 18.sp : 20.sp;

  static double getSubtitleFontSize(BuildContext context) =>
      isMobile(context) ? 14.sp : 16.sp;

  static double getBodyFontSize(BuildContext context) =>
      isMobile(context) ? 12.sp : 14.sp;

  // Border radius tùy theo màn hình
  static double getBorderRadius(BuildContext context) =>
      isMobile(context) ? 12.r : 16.r;

  // Icon size
  static double getIconSize(BuildContext context) =>
      isMobile(context) ? 20.w : 24.w;

  // Avatar size
  static double getAvatarRadius(BuildContext context) =>
      isMobile(context) ? 20.r : 24.r;

  // Button height
  static double getButtonHeight(BuildContext context) =>
      isMobile(context) ? 48.h : 56.h;

  // List tile content padding
  static EdgeInsets getListTilePadding(BuildContext context) =>
      isMobile(context) 
        ? EdgeInsets.all(12.w) 
        : EdgeInsets.all(16.w);
}
