import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlatformOptimizations {
  // Detect platform
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  
  // iOS specific optimizations
  static void setupIOSOptimizations() {
    if (isIOS) {
      // Set preferred orientations for iOS
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      
      // iOS specific status bar style
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
          statusBarColor: Colors.transparent,
        ),
      );
    }
  }
  
  // Android specific optimizations
  static void setupAndroidOptimizations() {
    if (isAndroid) {
      // Android specific status bar style
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
      
      // Enable edge-to-edge
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
      );
    }
  }
  
  // Initialize all platform optimizations
  static void initialize() {
    setupIOSOptimizations();
    setupAndroidOptimizations();
  }
  
  // Get safe area padding for different platforms
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    
    if (isIOS) {
      return EdgeInsets.only(
        top: mediaQuery.padding.top,
        bottom: mediaQuery.padding.bottom,
      );
    } else if (isAndroid) {
      return EdgeInsets.only(
        top: mediaQuery.padding.top,
        bottom: mediaQuery.viewInsets.bottom > 0 ? 0 : mediaQuery.padding.bottom,
      );
    }
    
    return EdgeInsets.zero;
  }
  
  // Platform-specific haptic feedback
  static void provideFeedback() {
    if (isIOS) {
      HapticFeedback.lightImpact();
    } else if (isAndroid) {
      HapticFeedback.selectionClick();
    }
  }
  
  // Platform-specific scroll physics
  static ScrollPhysics getScrollPhysics() {
    if (isIOS) {
      return const BouncingScrollPhysics();
    } else if (isAndroid) {
      return const ClampingScrollPhysics();
    }
    return const ClampingScrollPhysics();
  }
}
