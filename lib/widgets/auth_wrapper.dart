import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/auth_models.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/customer/customer_list_screen_new_fixed.dart';
import '../screens/auth/admin_dashboard_screen.dart';

class AppAuthWrapper extends StatefulWidget {
  const AppAuthWrapper({super.key});

  @override
  State<AppAuthWrapper> createState() => _AppAuthWrapperState();
}

class _AppAuthWrapperState extends State<AppAuthWrapper> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  AuthState? _authState;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      // Kiểm tra trạng thái đăng nhập hiện tại
      final authState = await _authService.getCurrentAuthState();
      setState(() {
        _authState = authState;
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking auth state: $e');
      setState(() {
        _isLoading = false;
        _authState = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              SizedBox(height: 16),
              Text(
                'Đang khởi tạo...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Kiểm tra trạng thái đăng nhập
    if (_authState == null) {
      // Chưa đăng nhập, hiển thị màn hình chọn vai trò
      return const RoleSelectionScreen();
    }

    // Đã đăng nhập, điều hướng theo vai trò
    switch (_authState!.role) {
      case UserRole.admin:
        return const AdminDashboardScreen();
      case UserRole.employee:
        return const CustomerListScreen();
    }
  }
}
