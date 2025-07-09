import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';

class NotificationDatabaseService {
  static final NotificationDatabaseService _instance = NotificationDatabaseService._internal();
  factory NotificationDatabaseService() => _instance;
  NotificationDatabaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add notification to database
  Future<String> addNotification(AppNotification notification) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('notifications')
          .add(notification.toMap());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add notification: $e');
    }
  }

  /// Get all notifications (unread first)
  Stream<List<AppNotification>> getAllNotifications() {
    return _firestore
        .collection('notifications')
        .orderBy('isRead', descending: false)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AppNotification.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  /// Get unread notifications count
  Stream<int> getUnreadCount() {
    return _firestore
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final batch = _firestore.batch();
      
      final unreadNotifications = await _firestore
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();
      
      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Delete old notifications (older than 30 days)
  Future<void> deleteOldNotifications() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final oldNotifications = await _firestore
          .collection('notifications')
          .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();
      
      final batch = _firestore.batch();
      
      for (var doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete old notifications: $e');
    }
  }

  /// Check if notification with specific ID exists
  Future<bool> checkNotificationExists(String notificationId) async {
    try {
      final doc = await _firestore
          .collection('notifications')
          .doc(notificationId)
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking notification existence: $e');
      return false;
    }
  }

  /// Create customer reminder notification
  Future<String> createCustomerReminderNotification({
    required String customerId,
    required String customerName,
    required String service,
    required int reminderDays,
    bool isOverdue = false,
  }) async {
    String title = isOverdue ? 'Khách hàng quá hạn' : 'Nhắc nhở chăm sóc khách hàng';
    String body = '$customerName - $service';
    
    if (isOverdue) {
      body += ' (Quá hạn ${reminderDays} ngày)';
    } else {
      body += ' (${reminderDays} ngày)';
    }

    final notification = AppNotification(
      id: '',
      title: title,
      body: body,
      type: isOverdue ? NotificationType.overdueReminder : NotificationType.customerReminder,
      priority: isOverdue ? NotificationPriority.urgent : NotificationPriority.normal,
      customerId: customerId,
      customerName: customerName,
      reminderDays: reminderDays,
      createdAt: DateTime.now(),
      data: {
        'service': service,
        'isOverdue': isOverdue,
      },
    );

    return await addNotification(notification);
  }

  /// Create customer reminder notification with custom ID
  Future<String> createCustomerReminderNotificationWithId({
    required String notificationId,
    required String customerId,
    required String customerName,
    required String service,
    required int reminderDays,
    bool isOverdue = false,
  }) async {
    String title = isOverdue ? 'Khách hàng quá hạn' : 'Nhắc nhở chăm sóc khách hàng';
    String body = '$customerName - $service';
    
    if (isOverdue) {
      body += ' (Quá hạn ${reminderDays} ngày)';
    } else {
      body += ' (${reminderDays} ngày)';
    }

    final notification = AppNotification(
      id: notificationId,
      title: title,
      body: body,
      type: isOverdue ? NotificationType.overdueReminder : NotificationType.customerReminder,
      priority: isOverdue ? NotificationPriority.urgent : NotificationPriority.normal,
      customerId: customerId,
      customerName: customerName,
      reminderDays: reminderDays,
      createdAt: DateTime.now(),
      data: {
        'service': service,
        'isOverdue': isOverdue,
      },
    );

    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .set(notification.toMap());
      
      return notificationId;
    } catch (e) {
      throw Exception('Failed to add notification with ID: $e');
    }
  }

  /// Get notifications for specific customer
  Stream<List<AppNotification>> getCustomerNotifications(String customerId) {
    return _firestore
        .collection('notifications')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AppNotification.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  /// Get today's due notifications
  Stream<List<AppNotification>> getTodaysDueNotifications() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('notifications')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
        .where('type', isEqualTo: NotificationType.customerReminder.name)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AppNotification.fromMap(doc.id, doc.data());
      }).toList();
    });
  }
}
