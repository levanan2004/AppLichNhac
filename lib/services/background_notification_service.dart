import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';
import '../models/reminder.dart';
import 'notification_database_service.dart';

class BackgroundNotificationService {
  static final BackgroundNotificationService _instance = BackgroundNotificationService._internal();
  factory BackgroundNotificationService() => _instance;
  BackgroundNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationDatabaseService _notificationDbService = NotificationDatabaseService();
  Timer? _timer;

  /// Start periodic check for due reminders
  void startPeriodicCheck() {
    // Check every 30 seconds for due reminders
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkDueReminders();
    });
    
    print('Background notification service started');
  }

  /// Stop periodic check
  void stopPeriodicCheck() {
    _timer?.cancel();
    _timer = null;
    print('Background notification service stopped');
  }

  /// Check for reminders that are due and create notifications
  Future<void> _checkDueReminders() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Get all customers
      final snapshot = await _firestore.collection('customers').get();
      
      for (final doc in snapshot.docs) {
        try {
          final customer = Customer.fromMap(doc.data(), doc.id);
          
          // Check each reminder
          for (int i = 0; i < customer.reminders.length; i++) {
            final reminder = customer.reminders[i];
            
            // Skip completed reminders
            if (reminder.isCompleted) continue;
            
            final reminderDate = DateTime(
              reminder.reminderDate.year,
              reminder.reminderDate.month,
              reminder.reminderDate.day,
            );
            
            // Check if reminder is due today
            if (reminderDate.isAtSameMomentAs(today)) {
              await _createNotificationIfNotExists(customer, reminder, i + 1);
            }
          }
        } catch (e) {
          print('Error processing customer ${doc.id}: $e');
        }
      }
    } catch (e) {
      print('Error checking due reminders: $e');
    }
  }

  /// Create notification if it doesn't exist yet
  Future<void> _createNotificationIfNotExists(
    Customer customer, 
    Reminder reminder, 
    int reminderDays
  ) async {
    try {
      // Create unique notification ID based on customer and reminder date
      final notificationId = '${customer.id}_${reminder.reminderDate.millisecondsSinceEpoch}';
      
      // Check if notification already exists
      final exists = await _notificationDbService.checkNotificationExists(notificationId);
      
      if (!exists) {
        // Create notification in database
        await _notificationDbService.createCustomerReminderNotificationWithId(
          notificationId: notificationId,
          customerId: customer.id!,
          customerName: customer.name,
          service: reminder.description,
          reminderDays: reminderDays,
        );
        
        print('Auto-created notification for ${customer.name} - ${reminder.description}');
      }
    } catch (e) {
      print('Error creating notification for ${customer.name}: $e');
    }
  }

  /// Manual check for testing
  Future<void> checkNow() async {
    print('Running manual check for due reminders...');
    await _checkDueReminders();
    print('Manual check completed');
  }
}
