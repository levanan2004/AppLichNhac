import 'package:cloud_firestore/cloud_firestore.dart';

class CallLog {
  final String? id;
  final String customerId;
  final String phoneNumber;
  final DateTime callTime;
  final String? duration; // Thoi gian goi (neu co)
  final String? notes; // Ghi chu ve cuoc goi
  final String status; // 'completed', 'missed', 'busy', 'initiated', etc.
  final String? platform; // 'iOS', 'Android', etc.
  final DateTime createdAt;

  CallLog({
    this.id,
    required this.customerId,
    required this.phoneNumber,
    required this.callTime,
    this.duration,
    this.notes,
    this.status = 'completed',
    this.platform,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'phoneNumber': phoneNumber,
      'callTime': Timestamp.fromDate(callTime),
      'duration': duration,
      'notes': notes,
      'status': status,
      'platform': platform,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory CallLog.fromMap(Map<String, dynamic> map, String id) {
    return CallLog(
      id: id,
      customerId: map['customerId'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      callTime: map['callTime'] is Timestamp
          ? (map['callTime'] as Timestamp).toDate()
          : DateTime.parse(map['callTime']),
      duration: map['duration'],
      notes: map['notes'],
      status: map['status'] ?? 'completed',
      platform: map['platform'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt']),
    );
  }

  CallLog copyWith({
    String? id,
    String? customerId,
    String? phoneNumber,
    DateTime? callTime,
    String? duration,
    String? notes,
    String? status,
    String? platform,
    DateTime? createdAt,
  }) {
    return CallLog(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      callTime: callTime ?? this.callTime,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      platform: platform ?? this.platform,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
