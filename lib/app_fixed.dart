import 'package:flutter/material.dart';
import 'screens/customer/customer_list_screen.dart';
import 'screens/customer/add_customer_screen.dart';
import 'screens/test/notification_test_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nhắc lịch chăm sóc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFFFF6F8),
        // Không chỉ định fontFamily để Flutter sử dụng font mặc định
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 20),
          titleMedium: TextStyle(fontSize: 18),
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
          bodySmall: TextStyle(fontSize: 12),
        ),
        cardTheme: const CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(100, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const CustomerListScreen(),
      routes: {
        '/add': (context) => const AddCustomerScreen(),
        '/test': (context) => const NotificationTestScreen(),
      },
    );
  }
}
