import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../services/customer_service.dart';
import '../../services/background_notification_service.dart';
import '../../models/customer.dart';
import '../../models/reminder.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final NotificationService _notificationService = NotificationService();
  final CustomerService _customerService = CustomerService();
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _loadFCMToken();
  }

  void _loadFCMToken() async {
    String? token = await _notificationService.getFCMToken();
    setState(() {
      _fcmToken = token;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // FCM Token Display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FCM Token:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _fcmToken ?? 'Loading...',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Test Buttons
            ElevatedButton(
              onPressed: _testLocalNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Test Local Notification'),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _testScheduledNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Test Scheduled Notification (5 seconds)'),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _addTestCustomer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Test Customer with Reminders'),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _testBackgroundService,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Test Background Service Now'),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _addTestCustomerToday,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Test Customer (Due Today)'),
            ),
            
            const SizedBox(height: 20),
            
            // Due Reminders
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [                    const Text(
                      'Khach hang can nhac nho hom nay & qua han:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: StreamBuilder<List<Customer>>(
                          stream: _customerService.getAllCustomers(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            
                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            }
                            
                            final allCustomers = snapshot.data ?? [];
                            
                            // Filter customers that have urgent reminders
                            final urgentCustomers = allCustomers.where((customer) => 
                                _hasUrgentReminders(customer)).toList();
                            
                            if (urgentCustomers.isEmpty) {
                              return const Center(
                                child: Text('Khong co khach hang can nhac nho'),
                              );
                            }
                            
                            return ListView.builder(
                              itemCount: urgentCustomers.length,
                              itemBuilder: (context, index) {
                                final customer = urgentCustomers[index];
                                final urgentReminders = _getUrgentReminders(customer);
                                
                                return Card(
                                  color: _isCustomerOverdue(customer) ? Colors.red.shade50 : Colors.orange.shade50,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _isCustomerOverdue(customer) ? Colors.red : Colors.orange,
                                      child: Text(
                                        customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      customer.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('SDT: ${customer.phone}'),
                                        Text('Dia chi: ${customer.address}'),
                                        Text('Nhac nho: ${urgentReminders.length} can xu ly'),
                                      ],
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _isCustomerOverdue(customer) ? Colors.red : Colors.orange,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _isCustomerOverdue(customer) ? 'QUA HAN' : 'HOM NAY',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _testLocalNotification() async {
    // Test local notification ngay lap tuc
    await _notificationService.showImmediateNotification(
      title: 'Test Local Notification',
      body: 'Day la thong bao test ngay lap tuc!',
      payload: 'test_immediate_notification',
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Local notification sent immediately!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _testScheduledNotification() async {
    // Test scheduled notification
    await _notificationService.scheduleReminderNotification(
      customerId: 'test-scheduled',
      customerName: 'Test Customer',
      service: 'Test Service',
      reminderDate: DateTime.now().add(const Duration(seconds: 5)),
      reminderDays: 30,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scheduled notification will appear in 5 seconds'),
      ),
    );
  }

  void _addTestCustomer() async {
    try {
      final testCustomer = Customer(
        name: 'Khach hang test ${DateTime.now().millisecond}',
        phone: '0123456789',
        address: '123 Duong Test, Quan Test, TP Test',
        serviceCompleted: 'Cham soc da mat co ban',
        amountSpent: 500000,
        reminders: [
          Reminder(
            reminderDate: DateTime.now().add(const Duration(days: 3)),
            description: 'Nhac nho sau 3 ngay',
          ),
          Reminder(
            reminderDate: DateTime.now().add(const Duration(days: 7)),
            description: 'Nhac nho sau 7 ngay',
          ),
          Reminder(
            reminderDate: DateTime.now().add(const Duration(days: 30)),
            description: 'Nhắc nhở sau 30 ngày',
          ),
        ],
        notes: 'Khách hàng test - sẽ có thông báo sau 3, 7, 30 ngày',
      );
      
      await _customerService.addCustomer(testCustomer);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm khách hàng test với lịch nhắc (3, 7, 30 ngày)!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addTestCustomerToday() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Tạo customer test với reminder hôm nay
      final testCustomer = Customer(
        name: 'Test Customer Today',
        phone: '0901234567',
        address: '123 Test Street',
        serviceCompleted: 'Massage mặt',
        amountSpent: 500000,
        notes: 'Test customer with reminder due today',
        createdAt: now,
        updatedAt: now,
        reminders: [
          Reminder(
            reminderDate: today, // Hôm nay
            description: 'Chăm sóc da định kỳ',
            isCompleted: false,
          ),
        ],
      );

      await _customerService.addCustomer(testCustomer);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm test customer với reminder hôm nay! Chạy Background Service để test.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _testBackgroundService() async {
    try {
      final backgroundService = BackgroundNotificationService();
      await backgroundService.checkNow();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã chạy background service! Kiểm tra notifications.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error testing background service: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper methods để kiểm tra trạng thái khách hàng
  bool _hasUrgentReminders(Customer customer) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return customer.reminders.any((reminder) => 
        !reminder.isCompleted && 
        reminder.reminderDate.isBefore(today.add(const Duration(days: 1))));
  }

  bool _isCustomerOverdue(Customer customer) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return customer.reminders.any((reminder) => 
        !reminder.isCompleted && 
        reminder.reminderDate.isBefore(today));
  }

  List<Reminder> _getUrgentReminders(Customer customer) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return customer.reminders.where((reminder) => 
        !reminder.isCompleted && 
        reminder.reminderDate.isBefore(today.add(const Duration(days: 1)))).toList();
  }
}
