import 'package:cloud_firestore/cloud_firestore.dart';

class WhatsAppLog {
  final String? id;
  final String customerId;
  final String phoneNumber;
  final DateTime sentTime;
  final String? message; // Tin nhắn đã gửi (nếu có)
  final String? notes; // Ghi chú về cuộc trò chuyện
  final String status; // 'sent', 'opened', 'delivered', 'failed', etc.
  final String? platform; // 'iOS', 'Android', etc.
  final DateTime createdAt;

  WhatsAppLog({
    this.id,
    required this.customerId,
    required this.phoneNumber,
    required this.sentTime,
    this.message,
    this.notes,
    this.status = 'sent',
    this.platform,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'phoneNumber': phoneNumber,
      'sentTime': Timestamp.fromDate(sentTime),
      'message': message,
      'notes': notes,
      'status': status,
      'platform': platform,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory WhatsAppLog.fromMap(Map<String, dynamic> map, String id) {
    return WhatsAppLog(
      id: id,
      customerId: map['customerId'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      sentTime: map['sentTime'] is Timestamp
          ? (map['sentTime'] as Timestamp).toDate()
          : DateTime.parse(map['sentTime']),
      message: map['message'],
      notes: map['notes'],
      status: map['status'] ?? 'sent',
      platform: map['platform'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt']),
    );
  }

  WhatsAppLog copyWith({
    String? id,
    String? customerId,
    String? phoneNumber,
    DateTime? sentTime,
    String? message,
    String? notes,
    String? status,
    String? platform,
    DateTime? createdAt,
  }) {
    return WhatsAppLog(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      sentTime: sentTime ?? this.sentTime,
      message: message ?? this.message,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      platform: platform ?? this.platform,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
