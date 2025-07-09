import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

void main() {
  print('=== HASH PASSWORD GENERATOR ===');
  print('Nhập mật khẩu admin bạn muốn:');

  final password = stdin.readLineSync() ?? '';

  if (password.isEmpty) {
    print('Mật khẩu không được để trống!');
    return;
  }

  // Hash password using SHA256
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  final hashedPassword = digest.toString();

  print('\n=== KẾT QUẢ ===');
  print('Mật khẩu gốc: $password');
  print('Mật khẩu đã hash (SHA256): $hashedPassword');

  print('\n=== HƯỚNG DẪN TẠO ADMIN TRÊN FIREBASE ===');
  print('1. Vào Firebase Console → Firestore Database');
  print('2. Tạo collection: admin_credentials');
  print('3. Tạo document với ID: admin');
  print('4. Thêm các fields:');
  print('   - username: admin (hoặc tên bạn muốn)');
  print('   - password: $hashedPassword');
  print('   - created_at: ${DateTime.now().toIso8601String()}');
  print('   - updated_at: ${DateTime.now().toIso8601String()}');

  print('\n=== TẠO MÃ TRUY CẬP NHÂN VIÊN ===');
  print('1. Tạo collection: access_codes');
  print('2. Tạo document (auto-generate ID)');
  print('3. Thêm fields cho mỗi mã:');
  print('   - code: STAFF1 (hoặc mã bạn muốn)');
  print('   - created_at: ${DateTime.now().toIso8601String()}');
  print('   - created_by: admin');
  print('   - is_active: true');
  print('   - used_by: null');
  print('   - used_at: null');

  print('\nHoàn tất! Bạn có thể sử dụng tài khoản admin này để đăng nhập.');
}
