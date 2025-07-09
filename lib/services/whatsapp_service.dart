import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import '../models/whatsapp_log.dart';

class WhatsAppResult {
  final bool isSuccess;
  final String? error;

  WhatsAppResult.success() : isSuccess = true, error = null;
  WhatsAppResult.failure(this.error) : isSuccess = false;
}

class WhatsAppService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mở WhatsApp chat với số điện thoại
  Future<WhatsAppResult> openWhatsAppChat(String phoneNumber, {String? message}) async {
    try {
      debugPrint('🔄 Đang mở WhatsApp chat với số: $phoneNumber');
      
      // Format số điện thoại (loại bỏ ký tự đặc biệt)
      String formattedPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Đảm bảo số điện thoại bắt đầu bằng mã quốc gia
      if (!formattedPhone.startsWith('+')) {
        if (formattedPhone.startsWith('0')) {
          formattedPhone = '+84${formattedPhone.substring(1)}';
        } else if (formattedPhone.startsWith('84')) {
          formattedPhone = '+$formattedPhone';
        } else {
          formattedPhone = '+84$formattedPhone';
        }
      }
      
      debugPrint('📱 Formatted phone: $formattedPhone');
      
      // Tạo WhatsApp link
      final link = WhatsAppUnilink(
        phoneNumber: formattedPhone,
        text: message ?? 'Xin chào! Tôi liên hệ từ ứng dụng quản lý khách hàng.',
      );
      
      final url = link.toString();
      debugPrint('🔗 WhatsApp URL: $url');
      
      // Kiểm tra và mở WhatsApp
      debugPrint('🔍 Checking if can launch WhatsApp URL...');
      final canLaunch = await canLaunchUrl(Uri.parse(url));
      debugPrint('✅ Can launch WhatsApp: $canLaunch');
      
      if (canLaunch) {
        debugPrint('🚀 Launching WhatsApp...');
        final launched = await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        debugPrint('✅ WhatsApp launched: $launched');
        
        if (launched) {
          debugPrint('✅ Đã mở WhatsApp thành công');
          return WhatsAppResult.success();
        } else {
          debugPrint('❌ Failed to launch WhatsApp despite canLaunch=true');
          return WhatsAppResult.failure('Không thể khởi chạy WhatsApp');
        }
      } else {
        debugPrint('❌ Cannot launch WhatsApp URL');
        // Thử fallback sang phone call
        debugPrint('🔄 Trying fallback to phone call...');
        final phoneUrl = 'tel:$formattedPhone';
        debugPrint('📞 Phone URL: $phoneUrl');
        
        if (await canLaunchUrl(Uri.parse(phoneUrl))) {
          await launchUrl(Uri.parse(phoneUrl));
          return WhatsAppResult.failure('WhatsApp không khả dụng, đã mở ứng dụng gọi điện');
        }
        
        return WhatsAppResult.failure('Không thể mở WhatsApp hoặc ứng dụng gọi điện. Vui lòng kiểm tra WhatsApp đã được cài đặt.');
      }
    } catch (e) {
      debugPrint('❌ Exception khi mở WhatsApp: $e');
      return WhatsAppResult.failure('Lỗi khi mở WhatsApp: $e');
    }
  }

  // Mở WhatsApp Business với fallback sang WhatsApp thường
  Future<WhatsAppResult> openWhatsAppBusinessOnly(String phoneNumber, {String? message}) async {
    try {
      debugPrint('🔄 Đang mở WhatsApp Business (có fallback) với số: $phoneNumber');
      
      // Ưu tiên sử dụng Android Intent nếu đang trên Android
      if (defaultTargetPlatform == TargetPlatform.android) {
        debugPrint('🤖 Đang trên Android, sử dụng Intent...');
        return await openWhatsAppBusinessWithIntent(phoneNumber, message: message);
      }
      
      // Fallback cho iOS hoặc platform khác
      debugPrint('🍎 Không phải Android, sử dụng URL scheme...');
      return await openWhatsAppBusinessChat(phoneNumber, message: message);
      
    } catch (e) {
      debugPrint('❌ Exception khi mở WhatsApp Business: $e');
      return await openWhatsAppChat(phoneNumber, message: message);
    }
  }

  // Mở WhatsApp Business chat với fallback
  Future<WhatsAppResult> openWhatsAppBusinessChat(String phoneNumber, {String? message}) async {
    try {
      debugPrint('🔄 Đang mở WhatsApp Business chat với số: $phoneNumber');
      
      // Format số điện thoại
      String formattedPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      if (!formattedPhone.startsWith('+')) {
        if (formattedPhone.startsWith('0')) {
          formattedPhone = '+84${formattedPhone.substring(1)}';
        } else if (formattedPhone.startsWith('84')) {
          formattedPhone = '+$formattedPhone';
        } else {
          formattedPhone = '+84$formattedPhone';
        }
      }
      
      // Tạo WhatsApp Business URL
      final text = Uri.encodeComponent(message ?? 'Xin chào! Tôi liên hệ từ ứng dụng quản lý khách hàng.');
      final url = 'whatsapp-business://send?phone=$formattedPhone&text=$text';
      
      debugPrint('🔗 WhatsApp Business URL: $url');
      
      debugPrint('🔍 Checking if can launch WhatsApp Business...');
      final canLaunch = await canLaunchUrl(Uri.parse(url));
      debugPrint('✅ Can launch WhatsApp Business: $canLaunch');
      
      if (canLaunch) {
        debugPrint('🚀 Launching WhatsApp Business...');
        final launched = await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        debugPrint('✅ WhatsApp Business launched: $launched');
        
        if (launched) {
          debugPrint('✅ Đã mở WhatsApp Business thành công');
          return WhatsAppResult.success();
        } else {
          debugPrint('❌ Failed to launch WhatsApp Business, fallback to regular WhatsApp');
          return await openWhatsAppChat(phoneNumber, message: message);
        }
      } else {
        debugPrint('❌ Không thể mở WhatsApp Business, thử mở WhatsApp thường');
        // Fallback về WhatsApp thường
        return await openWhatsAppChat(phoneNumber, message: message);
      }
    } catch (e) {
      debugPrint('❌ Lỗi khi mở WhatsApp Business: $e');
      // Fallback về WhatsApp thường
      return await openWhatsAppChat(phoneNumber, message: message);
    }
  }

  // Mở CHÍNH XÁC WhatsApp Business - KHÔNG fallback
  Future<WhatsAppResult> openWhatsAppBusinessStrict(String phoneNumber, {String? message}) async {
    try {
      debugPrint('🔄 Đang mở WhatsApp Business STRICT (không fallback) với số: $phoneNumber');
      
      // Format số điện thoại
      String formattedPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      if (!formattedPhone.startsWith('+')) {
        if (formattedPhone.startsWith('0')) {
          formattedPhone = '+84${formattedPhone.substring(1)}';
        } else if (formattedPhone.startsWith('84')) {
          formattedPhone = '+$formattedPhone';
        } else {
          formattedPhone = '+84$formattedPhone';
        }
      }
      
      debugPrint('📱 Formatted phone: $formattedPhone');
      
      // Thử Android Intent dành riêng cho WhatsApp Business
      final text = Uri.encodeComponent(message ?? 'Xin chào! Tôi liên hệ từ ứng dụng quản lý khách hàng.');
      final intentUrl = 'intent://send/?phone=$formattedPhone&text=$text#Intent;scheme=whatsapp;package=com.whatsapp.w4b;end';
      
      debugPrint('🔗 WhatsApp Business Intent URL: $intentUrl');
      
      final canLaunch = await canLaunchUrl(Uri.parse(intentUrl));
      debugPrint('✅ Can launch WhatsApp Business Intent: $canLaunch');
      
      if (canLaunch) {
        debugPrint('🚀 Launching WhatsApp Business...');
        final launched = await launchUrl(
          Uri.parse(intentUrl),
          mode: LaunchMode.externalApplication,
        );
        debugPrint('✅ WhatsApp Business launched: $launched');
        
        if (launched) {
          debugPrint('✅ Đã mở WhatsApp Business thành công');
          return WhatsAppResult.success();
        } else {
          debugPrint('❌ Failed to launch WhatsApp Business despite canLaunch=true');
          return WhatsAppResult.failure('Không thể khởi chạy WhatsApp Business');
        }
      } else {
        debugPrint('❌ Cannot launch WhatsApp Business Intent - STRICT MODE');
        return WhatsAppResult.failure('WhatsApp Business không được cài đặt hoặc không khả dụng');
      }
    } catch (e) {
      debugPrint('❌ Exception khi mở WhatsApp Business STRICT: $e');
      return WhatsAppResult.failure('Lỗi khi mở WhatsApp Business: $e');
    }
  }

  // Mở WhatsApp Business bằng Android Intent (chính xác nhất)
  Future<WhatsAppResult> openWhatsAppBusinessWithIntent(String phoneNumber, {String? message}) async {
    try {
      debugPrint('🔄 Đang mở WhatsApp Business bằng Android Intent với số: $phoneNumber');
      
      // Format số điện thoại
      String formattedPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      if (!formattedPhone.startsWith('+')) {
        if (formattedPhone.startsWith('0')) {
          formattedPhone = '+84${formattedPhone.substring(1)}';
        } else if (formattedPhone.startsWith('84')) {
          formattedPhone = '+$formattedPhone';
        } else {
          formattedPhone = '+84$formattedPhone';
        }
      }
      
      debugPrint('📱 Formatted phone: $formattedPhone');
      
      final text = message ?? 'Xin chào! Tôi liên hệ từ ứng dụng quản lý khách hàng.';
      
      // Kiểm tra platform trước
      if (defaultTargetPlatform != TargetPlatform.android) {
        debugPrint('❌ Android Intent chỉ hoạt động trên Android, fallback...');
        return await openWhatsAppBusinessChat(phoneNumber, message: message);
      }
      
      try {
        // Tạo Android Intent cho WhatsApp Business
        final intent = AndroidIntent(
          action: 'android.intent.action.SEND',
          package: 'com.whatsapp.w4b', // Package chính xác của WhatsApp Business
          type: 'text/plain',
          arguments: <String, dynamic>{
            'android.intent.extra.TEXT': text,
            'jid': '$formattedPhone@s.whatsapp.net', // WhatsApp JID format
          },
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        
        debugPrint('🔗 Android Intent: WhatsApp Business package=com.whatsapp.w4b');
        debugPrint('📞 Phone: $formattedPhone');
        debugPrint('💬 Message: $text');
        
        await intent.launch();
        debugPrint('✅ Đã mở WhatsApp Business thành công bằng Android Intent');
        return WhatsAppResult.success();
        
      } catch (intentError) {
        debugPrint('❌ Android Intent failed: $intentError');
        
        // Thử cách 2: Intent đơn giản hơn
        try {
          final simpleIntent = AndroidIntent(
            action: 'android.intent.action.VIEW',
            data: 'https://wa.me/$formattedPhone?text=${Uri.encodeComponent(text)}',
            package: 'com.whatsapp.w4b',
            flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
          );
          
          debugPrint('🔄 Thử Android Intent đơn giản...');
          await simpleIntent.launch();
          debugPrint('✅ Đã mở WhatsApp Business thành công bằng Intent đơn giản');
          return WhatsAppResult.success();
          
        } catch (simpleIntentError) {
          debugPrint('❌ Simple Android Intent cũng failed: $simpleIntentError');
          
          // Fallback về method cũ
          debugPrint('🔄 Fallback về URL launcher...');
          return await openWhatsAppBusinessChat(phoneNumber, message: message);
        }
      }
      
    } catch (e) {
      debugPrint('❌ Exception khi mở WhatsApp Business bằng Intent: $e');
      // Fallback về method cũ
      return await openWhatsAppBusinessChat(phoneNumber, message: message);
    }
  }

  // Lưu lịch sử tin nhắn WhatsApp
  Future<String?> saveWhatsAppLog(WhatsAppLog whatsappLog) async {
    try {
      debugPrint('🔄 Bắt đầu lưu WhatsApp log cho customer: ${whatsappLog.customerId}');
      
      // Kiểm tra Firebase đã khởi tạo chưa
      if (!Firebase.apps.isNotEmpty) {
        debugPrint('❌ Firebase chưa được khởi tạo');
        return null;
      }
      
      // Thêm metadata về platform
      final whatsappLogData = whatsappLog.toMap();
      whatsappLogData['platform'] = defaultTargetPlatform.toString();
      whatsappLogData['timestamp'] = FieldValue.serverTimestamp();
      
      debugPrint('📋 WhatsApp log data: $whatsappLogData');
      
      debugPrint('🔥 Attempting to write to Firestore...');
      final docRef = await _firestore
          .collection('whatsapp_logs')
          .add(whatsappLogData);
      
      debugPrint('✅ WhatsApp log saved successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Lỗi khi lưu WhatsApp log: $e');
      return null;
    }
  }

  // Lấy lịch sử WhatsApp của khách hàng
  Future<List<WhatsAppLog>> getWhatsAppLogsForCustomer(String customerId) async {
    try {
      debugPrint('🔄 Đang lấy WhatsApp logs cho customer: $customerId');
      
      final querySnapshot = await _firestore
          .collection('whatsapp_logs')
          .where('customerId', isEqualTo: customerId)
          .orderBy('sentAt', descending: true)
          .get();
      
      final logs = querySnapshot.docs
          .map((doc) => WhatsAppLog.fromMap(doc.data(), doc.id))
          .toList();
      
      debugPrint('✅ Đã lấy ${logs.length} WhatsApp logs');
      return logs;
    } catch (e) {
      debugPrint('❌ Lỗi khi lấy WhatsApp logs: $e');
      return [];
    }
  }

  // Tạo tin nhắn mặc định cho khách hàng
  String createCustomerMessage(String customerName) {
    return 'Xin chào $customerName! Tôi liên hệ từ VIP CSKH để tư vấn và hỗ trợ bạn.';
  }
}