import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'reminder.dart';

class Customer {
  final String? id;
  final String name;
  final String phone;
  final String address;
  final String serviceCompleted;
  final double amountSpent;
  final List<Reminder> reminders;
  final String? notes;
  final String? avatarUrl; // Thêm URL ảnh đại diện
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.serviceCompleted,
    required this.amountSpent,
    required this.reminders,
    this.notes,
    this.avatarUrl, // Thêm ảnh đại diện (optional)
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Lấy reminder gần nhất chưa hoàn thành
  Reminder? get nextReminder {
    final uncompletedReminders = reminders
        .where((r) => !r.isCompleted)
        .toList()
      ..sort((a, b) => a.reminderDate.compareTo(b.reminderDate));
    
    return uncompletedReminders.isNotEmpty ? uncompletedReminders.first : null;
  }

  // Lấy tất cả reminder hôm nay chưa hoàn thành
  List<Reminder> get todayReminders {
    return reminders.where((r) => r.isDueToday && !r.isCompleted).toList();
  }

  // Lấy tất cả reminder quá hạn chưa hoàn thành
  List<Reminder> get overdueReminders {
    return reminders.where((r) => r.isOverdue).toList();
  }

  // Lấy tất cả reminder được hoàn thành hôm nay (vừa nhắc hôm nay)
  List<Reminder> get completedTodayReminders {
    return reminders.where((r) => r.isCompletedToday).toList();
  }

  // Lấy tất cả reminder được tạo hôm nay (vừa thêm hôm nay)
  List<Reminder> get createdTodayReminders {
    return reminders.where((r) => r.isCreatedToday).toList();
  }

  // Kiểm tra xem có reminder nào cần thông báo không
  bool get hasUrgentReminders {
    return todayReminders.isNotEmpty || overdueReminders.isNotEmpty;
  }

  // Trả về màu nền cho card dựa trên reminder gần nhất
  Color get backgroundColor {
    if (overdueReminders.isNotEmpty) {
      return const Color(0xFFFFEBEE); // Đỏ nhạt cho quá hạn
    } else if (todayReminders.isNotEmpty) {
      return const Color(0xFFFFF3E0); // Cam nhạt cho hôm nay
    } else if (nextReminder != null && nextReminder!.daysUntilReminder == 1) {
      return const Color(0xFFF3E5F5); // Tím nhạt cho ngày mai
    } else if (nextReminder != null && nextReminder!.daysUntilReminder <= 3) {
      return const Color(0xFFE8F5E8); // Xanh lá nhạt cho sắp đến hẹn
    }
    return Colors.white; // Trắng cho bình thường
  }

  // Trả về màu chữ cho text
  Color get textColor {
    if (overdueReminders.isNotEmpty) {
      return const Color(0xFFD32F2F);
    } else if (todayReminders.isNotEmpty) {
      return const Color(0xFFE65100);
    } else if (nextReminder != null && nextReminder!.daysUntilReminder == 1) {
      return const Color(0xFF7B1FA2);
    } else if (nextReminder != null && nextReminder!.daysUntilReminder <= 3) {
      return const Color(0xFF388E3C);
    }
    return const Color(0xFF424242);
  }

  // Trả về icon cho trạng thái
  IconData get statusIcon {
    if (overdueReminders.isNotEmpty) {
      return Icons.warning;
    } else if (todayReminders.isNotEmpty) {
      return Icons.today;
    } else if (nextReminder != null && nextReminder!.daysUntilReminder == 1) {
      return Icons.schedule;
    } else if (nextReminder != null && nextReminder!.daysUntilReminder <= 3) {
      return Icons.notifications_active;
    }
    return Icons.person;
  }

  // Trả về text mô tả trạng thái
  String get statusText {
    if (overdueReminders.isNotEmpty) {
      return 'Quá hạn ${overdueReminders.length} lịch nhắc';
    } else if (todayReminders.isNotEmpty) {
      return 'Hôm nay có ${todayReminders.length} lịch nhắc';
    } else if (nextReminder != null) {
      final days = nextReminder!.daysUntilReminder;
      if (days == 1) {
        return 'Ngày mai có lịch nhắc';
      } else if (days <= 3) {
        return 'Còn $days ngày có lịch nhắc';
      } else {
        return 'Còn $days ngày có lịch nhắc';
      }
    }
    return 'Không có lịch nhắc';
  }

  // Trả về màu cho badge/chip
  Color get badgeColor {
    if (overdueReminders.isNotEmpty) {
      return const Color(0xFFD32F2F);
    } else if (todayReminders.isNotEmpty) {
      return const Color(0xFFE65100);
    } else if (nextReminder != null && nextReminder!.daysUntilReminder == 1) {
      return const Color(0xFF7B1FA2);
    } else if (nextReminder != null && nextReminder!.daysUntilReminder <= 3) {
      return const Color(0xFF388E3C);
    }
    return const Color(0xFF757575);
  }

  // Priority cho notification (1 = cao nhất, 5 = thấp nhất)
  int get notificationPriority {
    if (overdueReminders.isNotEmpty) return 1;
    if (todayReminders.isNotEmpty) return 2;
    if (nextReminder != null && nextReminder!.daysUntilReminder == 1) return 3;
    if (nextReminder != null && nextReminder!.daysUntilReminder <= 3) return 4;
    return 5;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'serviceCompleted': serviceCompleted,
      'amountSpent': amountSpent,
      'reminders': reminders.map((r) => r.toMap()).toList(),
      'notes': notes,
      'avatarUrl': avatarUrl, // Thêm URL ảnh đại diện
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map, String id) {
    List<dynamic> remindersData = map['reminders'] ?? [];
    List<Reminder> remindersList = remindersData
        .asMap()
        .entries
        .map((entry) => Reminder.fromMap(
              Map<String, dynamic>.from(entry.value),
              '${id}_reminder_${entry.key}',
            ))
        .toList();

    return Customer(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      serviceCompleted: map['serviceCompleted'] ?? '',
      amountSpent: (map['amountSpent'] ?? 0.0).toDouble(),
      reminders: remindersList,
      notes: map['notes'],
      avatarUrl: map['avatarUrl'], // Thêm URL ảnh đại diện
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? serviceCompleted,
    double? amountSpent,
    List<Reminder>? reminders,
    String? notes,
    String? avatarUrl, // Thêm ảnh đại diện
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearAvatarUrl = false, // Thêm flag để clear avatarUrl
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      serviceCompleted: serviceCompleted ?? this.serviceCompleted,
      amountSpent: amountSpent ?? this.amountSpent,
      reminders: reminders ?? this.reminders,
      notes: notes ?? this.notes,
      avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl), // Sử dụng flag
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, phone: $phone, reminders: ${reminders.length})';
  }
}
