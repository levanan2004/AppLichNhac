import 'package:cloud_firestore/cloud_firestore.dart';

class Reminder {
  final String? id;
  final DateTime reminderDate;
  final String description;
  final String? detailedDescription; // Thêm mô tả chi tiết
  final String? imageUrl; // Thêm URL hình ảnh
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;

  Reminder({
    this.id,
    required this.reminderDate,
    required this.description,
    this.detailedDescription, // Thêm mô tả chi tiết (optional)
    this.imageUrl, // Thêm URL hình ảnh (optional)
    this.isCompleted = false,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isDueToday {
    final today = DateTime.now();
    return today.year == reminderDate.year &&
        today.month == reminderDate.month &&
        today.day == reminderDate.day;
  }

  // Kiểm tra xem reminder có được hoàn thành hôm nay không (vừa nhắc hôm nay)
  bool get isCompletedToday {
    if (!isCompleted || completedAt == null) return false;
    final today = DateTime.now();
    final completedDate = completedAt!;
    return today.year == completedDate.year &&
        today.month == completedDate.month &&
        today.day == completedDate.day;
  }

  // Kiểm tra xem reminder có được tạo hôm nay không (vừa thêm hôm nay)
  bool get isCreatedToday {
    final today = DateTime.now();
    return today.year == createdAt.year &&
        today.month == createdAt.month &&
        today.day == createdAt.day;
  }

  bool get isOverdue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminderDay = DateTime(reminderDate.year, reminderDate.month, reminderDate.day);
    return reminderDay.isBefore(today) && !isCompleted;
  }

  int get daysUntilReminder {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminderDay = DateTime(reminderDate.year, reminderDate.month, reminderDate.day);
    return reminderDay.difference(today).inDays;
  }

  Map<String, dynamic> toMap() {
    return {
      'reminderDate': Timestamp.fromDate(reminderDate),
      'description': description,
      'detailedDescription': detailedDescription, // Thêm mô tả chi tiết
      'imageUrl': imageUrl, // Thêm URL hình ảnh
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map, String id) {
    return Reminder(
      id: id,
      reminderDate: (map['reminderDate'] as Timestamp).toDate(),
      description: map['description'] ?? '',
      detailedDescription: map['detailedDescription'], // Thêm mô tả chi tiết
      imageUrl: map['imageUrl'], // Thêm URL hình ảnh
      isCompleted: map['isCompleted'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      completedAt: map['completedAt'] != null 
          ? (map['completedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Reminder copyWith({
    String? id,
    DateTime? reminderDate,
    String? description,
    String? detailedDescription, // Thêm mô tả chi tiết
    String? imageUrl, // Thêm URL hình ảnh
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    bool clearImageUrl = false, // Thêm flag để clear imageUrl
  }) {
    return Reminder(
      id: id ?? this.id,
      reminderDate: reminderDate ?? this.reminderDate,
      description: description ?? this.description,
      detailedDescription: detailedDescription ?? this.detailedDescription, // Thêm mô tả chi tiết
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl), // Sử dụng flag
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

// Class hỗ trợ để nhập liệu reminder khi thêm/sửa khách hàng
class ReminderInput {
  DateTime? date;
  String description;
  String? detailedDescription; // Mô tả chi tiết
  String? imageUrl; // URL hình ảnh
  bool isCompleted;

  ReminderInput({
    this.date,
    this.description = '',
    this.detailedDescription,
    this.imageUrl,
    this.isCompleted = false,
  });

  // Kiểm tra tính hợp lệ
  bool get isValid => description.isNotEmpty && date != null;

  // Convert to Reminder object
  Reminder toReminder() {
    return Reminder(
      reminderDate: date ?? DateTime.now(),
      description: description,
      detailedDescription: detailedDescription,
      imageUrl: imageUrl, // Thêm URL hình ảnh
      isCompleted: isCompleted,
    );
  }

  // Create from Reminder object
  factory ReminderInput.fromReminder(Reminder reminder) {
    return ReminderInput(
      date: reminder.reminderDate,
      description: reminder.description,
      detailedDescription: reminder.detailedDescription,
      imageUrl: reminder.imageUrl, // Thêm URL hình ảnh
      isCompleted: reminder.isCompleted,
    );
  }
}
