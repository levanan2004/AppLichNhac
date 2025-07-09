import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  static const String _adminCollection = 'admin_credentials';
  static const String _accessCodesCollection = 'access_codes';
  
  // SharedPreferences keys
  static const String _keyIsAuthenticated = 'is_authenticated';
  static const String _keyUserType = 'user_type';
  static const String _keyEmployeeCode = 'employee_code';
  static const String _keyDeviceId = 'device_id';

  // Generate random access code
  String _generateAccessCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      6, (_) => chars.codeUnitAt(random.nextInt(chars.length))
    ));
  }

  // Get device ID
  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_keyDeviceId);
    
    if (deviceId == null) {
      try {
        final deviceInfo = await _deviceInfo.androidInfo;
        deviceId = '${deviceInfo.brand}_${deviceInfo.model}_${deviceInfo.id}';
      } catch (e) {
        // Fallback: generate random device ID
        deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
      }
      await prefs.setString(_keyDeviceId, deviceId);
    }
    
    return deviceId;
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsAuthenticated) ?? false;
  }

  // Get user type
  Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserType);
  }

  // Admin login
  Future<bool> adminLogin(String username, String password) async {
    try {
      final doc = await _firestore.collection(_adminCollection).doc('admin').get();
      
      if (doc.exists) {
        final credentials = AdminCredentials.fromMap(doc.data()!);
        
        // Debug: In ra giá trị để kiểm tra
        print('Input username: "$username"');
        print('Firebase username: "${credentials.username}"');
        print('Input password: "$password"');
        print('Firebase password: "${credentials.password}"');
        
        // So sánh trực tiếp username và password (không hash)
        if (credentials.username.trim() == username.trim() && 
            credentials.password.trim() == password.trim()) {
          // Save to local storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_keyIsAuthenticated, true);
          await prefs.setString(_keyUserType, 'admin');
          
          print('Login successful!');
          return true;
        } else {
          print('Login failed: credentials do not match');
        }
      } else {
        print('Admin document does not exist');
      }
      
      return false;
    } catch (e) {
      print('Error during admin login: $e');
      return false;
    }
  }

  // Employee login with access code
  Future<bool> employeeLogin(String accessCode) async {
    try {
      final deviceId = await _getDeviceId();
      
      // Find the access code
      final querySnapshot = await _firestore
          .collection(_accessCodesCollection)
          .where('code', isEqualTo: accessCode)
          .where('is_active', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return false; // Code not found or inactive
      }

      final codeDoc = querySnapshot.docs.first;
      final codeData = AccessCode.fromMap(codeDoc.data(), codeDoc.id);

      // Check if code is already used
      if (codeData.usedBy != null) {
        return false; // Code already used
      }

      // Mark code as used
      await _firestore.collection(_accessCodesCollection).doc(codeDoc.id).update({
        'used_by': deviceId,
        'used_at': DateTime.now().toIso8601String(),
      });

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsAuthenticated, true);
      await prefs.setString(_keyUserType, 'employee');
      await prefs.setString(_keyEmployeeCode, accessCode);
      
      return true;
    } catch (e) {
      print('Error during employee login: $e');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    // Xóa toàn bộ dữ liệu liên quan đến auth
    await prefs.remove(_keyIsAuthenticated);
    await prefs.remove(_keyUserType);
    await prefs.remove(_keyEmployeeCode);
    await prefs.remove(_keyDeviceId);
    // Nếu muốn xóa sạch mọi thứ (cẩn thận):
    // await prefs.clear();
  }

  // Create access code (Admin only)
  Future<String?> createAccessCode() async {
    try {
      final userType = await getUserType();
      if (userType != 'admin') {
        throw Exception('Unauthorized: Only admin can create access codes');
      }

      final code = _generateAccessCode();
      final accessCode = AccessCode(
        code: code,
        createdAt: DateTime.now(),
        createdBy: 'admin',
      );

      await _firestore.collection(_accessCodesCollection).add(accessCode.toMap());
      
      return code;
    } catch (e) {
      print('Error creating access code: $e');
      return null;
    }
  }

  // Get all access codes (Admin only)
  Stream<List<AccessCode>> getAccessCodes() {
    return _firestore
        .collection(_accessCodesCollection)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AccessCode.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Deactivate access code (Admin only)
  Future<bool> deactivateAccessCode(String codeId) async {
    try {
      final userType = await getUserType();
      if (userType != 'admin') {
        throw Exception('Unauthorized: Only admin can deactivate access codes');
      }

      await _firestore.collection(_accessCodesCollection).doc(codeId).update({
        'is_active': false,
      });

      return true;
    } catch (e) {
      print('Error deactivating access code: $e');
      return false;
    }
  }

  // Delete access code (Admin only)
  Future<bool> deleteAccessCode(String codeId) async {
    try {
      final userType = await getUserType();
      if (userType != 'admin') {
        throw Exception('Unauthorized: Only admin can delete access codes');
      }

      await _firestore.collection(_accessCodesCollection).doc(codeId).delete();

      return true;
    } catch (e) {
      print('Error deleting access code: $e');
      return false;
    }
  }

  // Initialize admin credentials (Run once)
  Future<void> initializeAdminCredentials({
    required String username,
    required String password,
  }) async {
    try {
      final credentials = AdminCredentials(
        username: username,
        password: password, // Lưu trực tiếp (không hash)
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_adminCollection)
          .doc('admin')
          .set(credentials.toMap());
      
      print('Admin credentials initialized successfully');
    } catch (e) {
      print('Error initializing admin credentials: $e');
    }
  }

  // Update admin credentials (Admin only)
  Future<bool> updateAdminCredentials({
    required String newUsername,
    required String newPassword,
  }) async {
    try {
      final userType = await getUserType();
      if (userType != 'admin') {
        throw Exception('Unauthorized: Only admin can update credentials');
      }
      
      await _firestore.collection(_adminCollection).doc('admin').update({
        'username': newUsername,
        'password': newPassword, // Lưu trực tiếp (không hash)
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error updating admin credentials: $e');
      return false;
    }
  }

  // Check if admin account exists
  Future<bool> hasAdminAccount() async {
    try {
      final doc = await _firestore.collection(_adminCollection).doc('admin').get();
      return doc.exists;
    } catch (e) {
      print('Error checking admin account: $e');
      return false;
    }
  }

  // Get current auth state
  Future<AuthState?> getCurrentAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isAuthenticated = prefs.getBool(_keyIsAuthenticated);
      final userType = prefs.getString(_keyUserType);
      // Kiểm tra đủ cả 2 key, thiếu key nào cũng trả về null
      if (isAuthenticated != true || userType == null) return null;

      String? userId;
      if (userType == 'admin') {
        userId = 'admin';
      } else {
        userId = prefs.getString(_keyEmployeeCode);
        if (userId == null) return null;
      }

      return AuthState(
        role: userType == 'admin' ? UserRole.admin : UserRole.employee,
        userId: userId,
        username: userType == 'admin' ? 'admin' : null,
        loginTime: DateTime.now(), // Có thể lưu loginTime vào prefs nếu cần
      );
    } catch (e) {
      print('Error getting current auth state: $e');
      return null;
    }
  }
}
