import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class PlatformCallHandler {
  
  /// Kiểm tra xem platform hiện tại có hỗ trợ gọi điện không
  static bool get isCallSupported {
    return defaultTargetPlatform == TargetPlatform.iOS || 
           defaultTargetPlatform == TargetPlatform.android;
  }

  /// Kiểm tra và yêu cầu quyền gọi điện
  static Future<bool> requestCallPermission() async {
    if (!isCallSupported) return false;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Android cần quyền CALL_PHONE
        final status = await Permission.phone.request();
        return status == PermissionStatus.granted;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS không cần request permission riêng cho gọi điện
        // Chỉ cần kiểm tra có thể launch URL tel:
        return true;
      }
    } catch (e) {
      debugPrint('Lỗi khi yêu cầu quyền gọi điện: $e');
    }
    
    return false;
  }

  /// Kiểm tra trạng thái quyền gọi điện
  static Future<bool> hasCallPermission() async {
    if (!isCallSupported) return false;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.phone.status;
        return status == PermissionStatus.granted;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS: kiểm tra có thể launch tel: URL
        final testUri = Uri(scheme: 'tel', path: '123');
        return await canLaunchUrl(testUri);
      }
    } catch (e) {
      debugPrint('Lỗi khi kiểm tra quyền gọi điện: $e');
    }
    
    return false;
  }

  /// Tạo URI gọi điện phù hợp với platform
  static Uri createCallUri(String phoneNumber) {
    // Làm sạch số điện thoại
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+\-\s()]'), '');
    
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS: sử dụng telprompt để hiển thị dialog xác nhận
      return Uri(scheme: 'telprompt', path: cleanNumber);
    } else {
      // Android và các platform khác: sử dụng tel
      return Uri(scheme: 'tel', path: cleanNumber);
    }
  }

  /// Thực hiện cuộc gọi với xử lý platform-specific
  static Future<CallResult> makeCall(String phoneNumber) async {
    try {
      if (!isCallSupported) {
        return CallResult.failure('Platform không hỗ trợ gọi điện');
      }

      // Kiểm tra quyền
      final hasPermission = await hasCallPermission();
      if (!hasPermission) {
        final granted = await requestCallPermission();
        if (!granted) {
          return CallResult.failure('Không có quyền gọi điện');
        }
      }

      // Tạo URI và thực hiện cuộc gọi
      final callUri = createCallUri(phoneNumber);
      
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
        return CallResult.success();
      } else {
        return CallResult.failure('Không thể mở ứng dụng gọi điện');
      }
    } catch (e) {
      debugPrint('Lỗi khi thực hiện cuộc gọi: $e');
      return CallResult.failure('Lỗi không xác định: $e');
    }
  }

  /// Format số điện thoại theo định dạng Việt Nam
  static String formatVietnamesePhoneNumber(String phoneNumber) {
    final clean = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    if (clean.length == 10 && clean.startsWith('0')) {
      // Format: 0xxx xxx xxx
      return '${clean.substring(0, 4)} ${clean.substring(4, 7)} ${clean.substring(7)}';
    } else if (clean.length == 11 && clean.startsWith('84')) {
      // Format: +84 xxx xxx xxx
      return '+84 ${clean.substring(2, 5)} ${clean.substring(5, 8)} ${clean.substring(8)}';
    }
    
    return phoneNumber; // Trả về số gốc nếu không match format
  }

  /// Validate số điện thoại Việt Nam
  static bool isValidVietnamesePhoneNumber(String phoneNumber) {
    final clean = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Số di động Việt Nam: 10 số bắt đầu bằng 0
    if (clean.length == 10 && clean.startsWith('0')) {
      final prefixes = ['03', '05', '07', '08', '09'];
      return prefixes.any((prefix) => clean.startsWith(prefix));
    }
    
    // Số quốc tế: 11 số bắt đầu bằng 84
    if (clean.length == 11 && clean.startsWith('84')) {
      final prefixes = ['843', '845', '847', '848', '849'];
      return prefixes.any((prefix) => clean.startsWith(prefix));
    }
    
    return false;
  }
}

/// Kết quả của cuộc gọi
class CallResult {
  final bool success;
  final String? error;

  CallResult._(this.success, this.error);

  factory CallResult.success() => CallResult._(true, null);
  factory CallResult.failure(String error) => CallResult._(false, error);

  bool get isSuccess => success;
  bool get isFailure => !success;
}
