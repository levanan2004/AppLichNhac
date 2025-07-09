import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  customerReminder,
  overdueReminder,
  systemAlert,
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final String? customerId;
  final String? customerName;
  final int? reminderDays;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.priority = NotificationPriority.normal,
    this.customerId,
    this.customerName,
    this.reminderDays,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type.name,
      'priority': priority.name,
      'customerId': customerId,
      'customerName': customerName,
      'reminderDays': reminderDays,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'data': data,
    };
  }

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.customerReminder,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      customerId: map['customerId'],
      customerName: map['customerName'],
      reminderDays: map['reminderDays'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      data: map['data'],
    );
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    NotificationPriority? priority,
    String? customerId,
    String? customerName,
    int? reminderDays,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      reminderDays: reminderDays ?? this.reminderDays,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  /// Get icon based on notification type
  String get iconAsset {
    switch (type) {
      case NotificationType.customerReminder:
        return '👤';
      case NotificationType.overdueReminder:
        return '⚠️';
      case NotificationType.systemAlert:
        return '🔔';
    }
  }

  /// Get color based on priority
  String get priorityColor {
    switch (priority) {
      case NotificationPriority.low:
        return '#4CAF50'; // Green
      case NotificationPriority.normal:
        return '#2196F3'; // Blue
      case NotificationPriority.high:
        return '#FF9800'; // Orange
      case NotificationPriority.urgent:
        return '#F44336'; // Red
    }
  }
}
