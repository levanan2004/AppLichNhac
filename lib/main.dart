import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/background_notification_service.dart';
import 'utils/platform_optimizations.dart';
import 'utils/firebase_health_checker.dart';
import './app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Đảm bảo system encoding được thiết lập đúng
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Initialize platform-specific optimizations
  PlatformOptimizations.initialize();

  try {
    // Initialize Firebase TRƯỚC KHI start app
    print('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');

    // Kiểm tra Firebase health
    print('🔍 Checking Firebase health...');
    final healthResults = await FirebaseHealthChecker.checkFirebaseHealth();
    print('📊 Health check results: $healthResults');
    
    // Test write permissions
    await FirebaseHealthChecker.testCallLogWrite();
    await FirebaseHealthChecker.testCustomerUpdate();

    // Initialize Notification Service
    try {
      await NotificationService().initialize();
      print('✅ Notification service initialized');
    } catch (e) {
      print('⚠️ Notification service error: $e');
    }

    // Subscribe to staff reminders topic
    try {
      await NotificationService().subscribeToStaffTopic();
      print('✅ Subscribed to staff topic');
    } catch (e) {
      print('⚠️ Subscribe error: $e');
    }

    // Start background notification service
    BackgroundNotificationService().startPeriodicCheck();

  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }

  // Start app AFTER Firebase is initialized
  runApp(const MyApp());
}
