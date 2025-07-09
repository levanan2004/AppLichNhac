import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/call_log.dart';
import '../utils/platform_call_handler.dart';

class CallService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Thực hiện cuộc gọi với xử lý platform-specific
  Future<CallResult> makeCall(String phoneNumber) async {
    try {
      final result = await PlatformCallHandler.makeCall(phoneNumber);
      return result;
    } catch (e) {
      debugPrint('Lỗi khi gọi điện thoại: $e');
      return CallResult.failure(e.toString());
    }
  }

  // Lưu lịch sử cuộc gọi với metadata platform-specific
  Future<String?> saveCallLog(CallLog callLog) async {
    try {
      debugPrint('🔄 Bắt đầu lưu call log cho customer: ${callLog.customerId}');
      
      // Kiểm tra Firebase đã khởi tạo chưa
      if (!Firebase.apps.isNotEmpty) {
        debugPrint('❌ Firebase chưa được khởi tạo');
        return null;
      }
      
      // Thêm metadata về platform
      final callLogData = callLog.toMap();
      callLogData['platform'] = defaultTargetPlatform.toString();
      callLogData['timestamp'] = FieldValue.serverTimestamp();
      
      debugPrint('📋 Call log data: $callLogData');
      
      // Trên iOS, không thể biết trạng thái thực tế của cuộc gọi
      // nên đặt status là 'initiated' thay vì 'completed'
      if (defaultTargetPlatform == TargetPlatform.iOS && 
          callLogData['status'] == 'completed') {
        callLogData['status'] = 'initiated';
        callLogData['notes'] = (callLogData['notes'] ?? '') + 
            ' [iOS: Trạng thái thực tế không xác định được]';
      }
      
      debugPrint('🔥 Attempting to write to Firestore...');
      final docRef = await _firestore
          .collection('call_logs')
          .add(callLogData);
      
      debugPrint('✅ Lưu call log thành công với ID: ${docRef.id}');
      return docRef.id;
    } on FirebaseException catch (e) {
      debugPrint('🔥 Firebase error khi lưu call log: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ Lỗi khi lưu lịch sử cuộc gọi: $e');
      return null;
    }
  }

  // Lấy lịch sử cuộc gọi của khách hàng
  Future<List<CallLog>> getCallLogsForCustomer(String customerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('call_logs')
          .where('customerId', isEqualTo: customerId)
          .orderBy('callTime', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CallLog.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Lỗi khi lấy lịch sử cuộc gọi: $e');
      return [];
    }
  }

  // Cập nhật lịch sử cuộc gọi
  Future<bool> updateCallLog(String callLogId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection('call_logs')
          .doc(callLogId)
          .update(updates);
      return true;
    } catch (e) {
      print('Lỗi khi cập nhật lịch sử cuộc gọi: $e');
      return false;
    }
  }

  // Xóa lịch sử cuộc gọi
  Future<bool> deleteCallLog(String callLogId) async {
    try {
      await _firestore
          .collection('call_logs')
          .doc(callLogId)
          .delete();
      return true;
    } catch (e) {
      print('Lỗi khi xóa lịch sử cuộc gọi: $e');
      return false;
    }
  }

  // Stream lịch sử cuộc gọi real-time
  Stream<List<CallLog>> getCallLogsStream(String customerId) {
    return _firestore
        .collection('call_logs')
        .where('customerId', isEqualTo: customerId)
        .orderBy('callTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CallLog.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Kiểm tra khả năng gọi điện trên platform hiện tại
  Future<bool> canMakePhoneCalls() async {
    return await PlatformCallHandler.hasCallPermission();
  }

  // Lấy tổng số cuộc gọi theo trạng thái
  Future<Map<String, int>> getCallStatistics(String customerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('call_logs')
          .where('customerId', isEqualTo: customerId)
          .get();

      final Map<String, int> stats = {
        'total': 0,
        'completed': 0,
        'missed': 0,
        'busy': 0,
      };

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        stats['total'] = (stats['total'] ?? 0) + 1;
        final status = data['status'] ?? 'completed';
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('Lỗi khi lấy thống kê cuộc gọi: $e');
      return {'total': 0, 'completed': 0, 'missed': 0, 'busy': 0};
    }
  }
}
