import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  // Ví dụ một số mật khẩu phổ biến và hash của chúng
  final passwords = ['admin123', '123456', 'password', 'admin', 'mypham2024'];
  
  print('=== HASH PASSWORD EXAMPLES ===');
  
  for (final password in passwords) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    final hashedPassword = digest.toString();
    
    print('Password: $password');
    print('SHA256:   $hashedPassword');
    print('---');
  }
  
  print('\n=== FIREBASE COLLECTION STRUCTURE ===');
  print('Collection: admin_credentials');
  print('Document ID: admin');
  print('Fields:');
  print('{');
  print('  "username": "admin",');
  print('  "password": "ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f",');
  print('  "created_at": "${DateTime.now().toIso8601String()}",');
  print('  "updated_at": "${DateTime.now().toIso8601String()}"');
  print('}');
  
  print('\nCollection: access_codes');
  print('Example Document:');
  print('{');
  print('  "code": "STAFF1",');
  print('  "created_at": "${DateTime.now().toIso8601String()}",');
  print('  "created_by": "admin",');
  print('  "is_active": true,');
  print('  "used_by": null,');
  print('  "used_at": null');
  print('}');
}
