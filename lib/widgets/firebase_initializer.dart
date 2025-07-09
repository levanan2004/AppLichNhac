import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseInitializer extends StatefulWidget {
  final Widget child;
  
  const FirebaseInitializer({
    super.key,
    required this.child,
  });

  @override
  State<FirebaseInitializer> createState() => _FirebaseInitializerState();
}

class _FirebaseInitializerState extends State<FirebaseInitializer> {
  bool _isInitialized = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkFirebaseState();
  }

  void _checkFirebaseState() async {
    try {
      // Check if Firebase is already initialized
      if (Firebase.apps.isNotEmpty) {
        setState(() {
          _isInitialized = true;
        });
        return;
      }
      
      // Wait a bit for background initialization
      await Future.delayed(const Duration(seconds: 2));
      
      // Check again
      if (Firebase.apps.isNotEmpty) {
        setState(() {
          _isInitialized = true;
        });
      } else {
        setState(() {
          _isInitialized = true; // Continue anyway
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isInitialized = true; // Continue anyway
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFFFFF6F8),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo hoặc icon app
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.notifications_active,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Customer Reminder',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Đang khởi tạo ứng dụng...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      print('Firebase init warning: $_errorMessage');
    }

    return widget.child;
  }
}
