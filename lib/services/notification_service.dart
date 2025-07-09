import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'notification_database_service.dart';
import '../models/notification.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  final NotificationDatabaseService _notificationDbService = NotificationDatabaseService();

  /// Initialize notifications
  Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();
    
    // Initialize local notifications
    await _initializeLocalNotifications();
    
    // Initialize Firebase messaging
    await _initializeFirebaseMessaging();
    
    // Request permissions
    await _requestPermissions();
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }
  
  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    
    const AndroidNotificationChannel customerReminderChannel = AndroidNotificationChannel(
      'customer_reminder_channel',
      'Customer Reminders',
      description: 'Notifications for customer care reminders',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );
    
    const AndroidNotificationChannel testChannel = AndroidNotificationChannel(
      'test_channel',
      'Test Notifications',
      description: 'Channel for testing notifications',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(customerReminderChannel);
        
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(testChannel);
  }

  /// Initialize Firebase messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle notification when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpened);
  }

  /// Request permissions for notifications
  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      // Request iOS permissions
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );
      
      print('iOS Permission status: ${settings.authorizationStatus}');
      
      // Request local notification permissions for iOS
      final bool? result = await _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      
      print('iOS Local Notification Permission: $result');
    } else if (Platform.isAndroid) {
      // Request Android 13+ permissions
      if (await Permission.notification.isDenied) {
        final status = await Permission.notification.request();
        print('Android Notification Permission: $status');
      }
      
      // Request exact alarm permission for Android 12+
      if (await Permission.scheduleExactAlarm.isDenied) {
        final status = await Permission.scheduleExactAlarm.request();
        print('Android Exact Alarm Permission: $status');
      }
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');
    
    // Show local notification when app is in foreground
    _showLocalNotification(
      title: message.notification?.title ?? 'Thông báo',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );

    // Save notification to database
    _saveNotificationToDatabase(message);
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    
    // Handle customer reminder notifications
    if (response.payload != null && response.payload!.startsWith('customer_reminder:')) {
      _handleCustomerReminderTapped(response.payload!);
    }
    
    // Navigate to specific screen based on payload
    // You can add navigation logic here
  }
  
  /// Handle customer reminder notification tapped
  Future<void> _handleCustomerReminderTapped(String payload) async {
    try {
      // Parse payload: "customer_reminder:customerId:reminderDays:timestamp"
      final parts = payload.split(':');
      if (parts.length >= 4) {
        final customerId = parts[1];
        final reminderDays = int.tryParse(parts[2]) ?? 0;
        final timestamp = int.tryParse(parts[3]) ?? 0;
        
        // Kiểm tra xem notification này đã tồn tại chưa dựa trên timestamp
        final notificationId = '${customerId}_${timestamp}';
        final exists = await _notificationDbService.checkNotificationExists(notificationId);
        
        if (!exists) {
          // Lấy thông tin customer để tạo notification
          await _notificationDbService.createCustomerReminderNotificationWithId(
            notificationId: notificationId,
            customerId: customerId,
            customerName: 'Khách hàng', // Tên sẽ được cập nhật trong database service
            service: 'Chăm sóc khách hàng',
            reminderDays: reminderDays,
          );
          
          print('Created notification in database for customer ID: $customerId (user tapped)');
        } else {
          print('Notification already exists for customer ID: $customerId, timestamp: $timestamp');
        }
      }
    } catch (e) {
      print('Error handling customer reminder tap: $e');
    }
  }

  /// Handle notification opened app
  void _handleNotificationOpened(RemoteMessage message) {
    print('Notification opened app: ${message.notification?.title}');
    // Handle navigation when app is opened from notification
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = 
        AndroidNotificationDetails(
          'customer_reminder_channel',
          'Customer Reminders',
          channelDescription: 'Notifications for customer care reminders',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Show immediate notification for testing
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Channel for testing notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Schedule reminder notification
  Future<void> scheduleReminderNotification({
    required String customerId,
    required String customerName,
    required String service,
    required DateTime reminderDate,
    required int reminderDays,
  }) async {
    final String title = 'Nhắc nhở chăm sóc khách hàng';
    final String body = '$customerName - $service (${reminderDays} ngày)';
    
    const AndroidNotificationDetails androidDetails = 
        AndroidNotificationDetails(
          'customer_reminder_channel',
          'Customer Reminders',
          channelDescription: 'Scheduled reminders for customer care',
          importance: Importance.high,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      customerId.hashCode + reminderDays, // Unique ID
      title,
      body,
      tz.TZDateTime.from(reminderDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: 
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'customer_reminder:$customerId:$reminderDays:${reminderDate.millisecondsSinceEpoch}',
    );
    
    print('Scheduled local notification for $customerName on ${reminderDate.toString().substring(0, 10)}');
    print('Notification will be created in database only when reminder time arrives');
  }
  /// Cancel scheduled notification
  Future<void> cancelReminderNotification(String customerId, int reminderDays) async {
    await _localNotifications.cancel(customerId.hashCode + reminderDays);
  }

  /// Cancel all notifications for a customer
  Future<void> cancelAllCustomerNotifications(String customerId) async {
    // Hủy tất cả notifications có thể có (tối đa 90 ngày - chu kỳ lớn nhất có thể)
    for (int i = 1; i <= 90; i++) {
      await _localNotifications.cancel(customerId.hashCode + i);
    }
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Subscribe to topic (for broadcasting to all staff)
  Future<void> subscribeToStaffTopic() async {
    await _firebaseMessaging.subscribeToTopic('staff_reminders');
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromStaffTopic() async {
    await _firebaseMessaging.unsubscribeFromTopic('staff_reminders');
  }

  /// Lưu notification vào database
  Future<void> _saveNotificationToDatabase(RemoteMessage message) async {
    try {
      final notification = AppNotification(
        id: '',
        title: message.notification?.title ?? 'Thông báo',
        body: message.notification?.body ?? '',
        type: _getNotificationTypeFromData(message.data),
        priority: _getNotificationPriorityFromData(message.data),
        customerId: message.data['customerId'],
        customerName: message.data['customerName'],
        reminderDays: int.tryParse(message.data['reminderDays'] ?? ''),
        createdAt: DateTime.now(),
        data: message.data,
      );

      await _notificationDbService.addNotification(notification);
    } catch (e) {
      print('Error saving notification to database: $e');
    }
  }

  /// Xác định priority từ data
  NotificationPriority _getNotificationPriorityFromData(Map<String, dynamic> data) {
    final priority = data['priority'] ?? '';
    switch (priority) {
      case 'urgent':
        return NotificationPriority.urgent;
      case 'high':
        return NotificationPriority.high;
      case 'low':
        return NotificationPriority.low;
      default:
        return NotificationPriority.normal;
    }
  }

  /// Show success notification when customer is added
  Future<void> showCustomerAddedNotification({
    required String customerName,
  }) async {
    await showImmediateNotification(
      title: 'Thêm khách hàng thành công',
      body: 'Đã thêm $customerName vào danh sách khách hàng',
      payload: 'customer_added:success',
    );
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  print('Background message: ${message.notification?.title}');
  
  // Lưu notification vào database khi app chạy background
  try {
    final notificationDbService = NotificationDatabaseService();
    final notification = AppNotification(
      id: '',
      title: message.notification?.title ?? 'Thông báo',
      body: message.notification?.body ?? '',
      type: _getNotificationTypeFromData(message.data),
      priority: _getNotificationPriorityFromData(message.data),
      customerId: message.data['customerId'],
      customerName: message.data['customerName'],
      reminderDays: int.tryParse(message.data['reminderDays'] ?? ''),
      createdAt: DateTime.now(),
      data: message.data,
    );

    await notificationDbService.addNotification(notification);
  } catch (e) {
    print('Error saving background notification to database: $e');
  }
}

/// Helper functions for background handler
NotificationType _getNotificationTypeFromData(Map<String, dynamic> data) {
  final type = data['type'] ?? '';
  switch (type) {
    case 'overdueReminder':
      return NotificationType.overdueReminder;
    case 'systemAlert':
      return NotificationType.systemAlert;
    default:
      return NotificationType.customerReminder;
  }
}

NotificationPriority _getNotificationPriorityFromData(Map<String, dynamic> data) {
  final priority = data['priority'] ?? '';
  switch (priority) {
    case 'urgent':
      return NotificationPriority.urgent;
    case 'high':
      return NotificationPriority.high;
    case 'low':
      return NotificationPriority.low;
    default:
      return NotificationPriority.normal;
  }
}
