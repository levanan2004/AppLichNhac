import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';
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

  // Mở CHÍNH XÁC WhatsApp Business - không fallback
  Future<WhatsAppResult> openWhatsAppBusinessOnly(String phoneNumber, {String? message}) async {
    try {
      debugPrint('🔄 Đang mở WhatsApp Business ONLY với số: $phoneNumber');
      
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
        debugPrint('❌ Cannot launch WhatsApp Business Intent');
        return WhatsAppResult.failure('WhatsApp Business không được cài đặt hoặc không khả dụng');
      }
    } catch (e) {
      debugPrint('❌ Exception khi mở WhatsApp Business: $e');
      return WhatsAppResult.failure('Lỗi khi mở WhatsApp Business: $e');
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
