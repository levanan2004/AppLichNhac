import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/customer.dart';
import 'notification_service.dart';

class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  
  static const String _collection = 'customers';

  // Lấy tất cả khách hàng
  Stream<List<Customer>> getCustomers() {
    return _firestore
        .collection(_collection)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Customer.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Backward compatibility
  Stream<List<Customer>> getAllCustomers() => getCustomers();

  // Lấy khách hàng theo ID
  Future<Customer?> getCustomer(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Customer.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      print('Error getting customer: $e');
    }
    return null;
  }

  // Thêm khách hàng mới
  Future<String?> addCustomer(Customer customer) async {
    try {
      final docRef = await _firestore.collection(_collection).add(customer.toMap());
      
      // Lên lịch thông báo cho khách hàng mới (chỉ schedule, không tạo database notification ngay)
      await _scheduleCustomerNotifications(customer.copyWith(id: docRef.id));
      
      return docRef.id;
    } catch (e) {
      print('Error adding customer: $e');
      return null;
    }
  }

  // Cập nhật khách hàng
  Future<bool> updateCustomer(Customer customer) async {
    try {
      if (customer.id == null) {
        print('❌ Customer ID is null, cannot update');
        return false;
      }
      
      print('🔄 Updating customer ${customer.id} with ${customer.reminders.length} reminders');
      
      // Kiểm tra Firebase đã khởi tạo chưa
      if (Firebase.apps.isEmpty) {
        print('❌ Firebase chưa được khởi tạo');
        return false;
      }
      
      final updateData = customer.copyWith(updatedAt: DateTime.now()).toMap();
      print('📋 Update data keys: ${updateData.keys.join(', ')}');
      print('📋 Reminders count in data: ${(updateData['reminders'] as List?)?.length ?? 0}');
      
      await _firestore
          .collection(_collection)
          .doc(customer.id)
          .update(updateData);
      
      print('✅ Customer updated successfully in Firestore');
      
      // Cập nhật lại lịch thông báo
      await _scheduleCustomerNotifications(customer);
      
      return true;
    } on FirebaseException catch (e) {
      print('🔥 Firebase error khi update customer: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('❌ Error updating customer: $e');
      return false;
    }
  }

  // Xóa khách hàng
  Future<bool> deleteCustomer(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      
      // Hủy các thông báo đã lên lịch
      await _cancelCustomerNotifications(id);
      
      return true;
    } catch (e) {
      print('Error deleting customer: $e');
      return false;
    }
  }

  // Lên lịch thông báo cho tất cả reminders của khách hàng
  Future<void> _scheduleCustomerNotifications(Customer customer) async {
    if (customer.id == null) return;
    
    final now = DateTime.now();
    
    // Hủy các thông báo cũ trước
    await _cancelCustomerNotifications(customer.id!);
    
    // Lên lịch thông báo cho từng reminder chưa hoàn thành
    for (int i = 0; i < customer.reminders.length; i++) {
      final reminder = customer.reminders[i];
      
      // Chỉ lên lịch cho reminders chưa hoàn thành và chưa qua ngày
      if (!reminder.isCompleted && reminder.reminderDate.isAfter(now)) {
        await _notificationService.scheduleReminderNotification(
          customerId: customer.id!,
          customerName: customer.name,
          service: reminder.description,
          reminderDate: reminder.reminderDate,
          reminderDays: i + 1, // Index + 1 for display
        );
        
        print('Scheduled reminder for ${customer.name}: ${reminder.description} on ${reminder.reminderDate.toString().substring(0, 10)}');
      }
    }
  }

  // Hủy các thông báo đã lên lịch
  Future<void> _cancelCustomerNotifications(String customerId) async {
    await _notificationService.cancelAllCustomerNotifications(customerId);
  }

  // Lấy khách hàng có reminder hôm nay
  Future<List<Customer>> getCustomersDueToday() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final customers = snapshot.docs
          .map((doc) => Customer.fromMap(doc.data(), doc.id))
          .where((customer) => customer.todayReminders.isNotEmpty)
          .toList();
      
      return customers;
    } catch (e) {
      print('Error getting customers due today: $e');
      return [];
    }
  }

  // Lấy khách hàng có reminder quá hạn
  Future<List<Customer>> getOverdueCustomers() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final customers = snapshot.docs
          .map((doc) => Customer.fromMap(doc.data(), doc.id))
          .where((customer) => customer.overdueReminders.isNotEmpty)
          .toList();
      
      return customers;
    } catch (e) {
      print('Error getting overdue customers: $e');
      return [];
    }
  }

  // Lấy khách hàng có reminder sắp tới
  Future<List<Customer>> getUpcomingCustomers({int days = 7}) async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final now = DateTime.now();
      final endDate = now.add(Duration(days: days));
      
      final customers = snapshot.docs
          .map((doc) => Customer.fromMap(doc.data(), doc.id))
          .where((customer) => 
              customer.reminders.any((reminder) => 
                  !reminder.isCompleted &&
                  reminder.reminderDate.isAfter(now) &&
                  reminder.reminderDate.isBefore(endDate)))
          .toList();
      
      return customers;
    } catch (e) {
      print('Error getting upcoming customers: $e');
      return [];
    }
  }

  // Lấy khách hàng có reminder được hoàn thành hôm nay (vừa nhắc hôm nay)
  Future<List<Customer>> getCustomersCompletedToday() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final customers = snapshot.docs
          .map((doc) => Customer.fromMap(doc.data(), doc.id))
          .where((customer) => customer.completedTodayReminders.isNotEmpty)
          .toList();
      
      return customers;
    } catch (e) {
      print('Error getting customers completed today: $e');
      return [];
    }
  }

  // Lấy khách hàng có reminder được tạo hôm nay (vừa thêm hôm nay)
  Future<List<Customer>> getCustomersCreatedToday() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final customers = snapshot.docs
          .map((doc) => Customer.fromMap(doc.data(), doc.id))
          .where((customer) => customer.createdTodayReminders.isNotEmpty)
          .toList();
      
      return customers;
    } catch (e) {
      print('Error getting customers created today: $e');
      return [];
    }
  }

  // Tìm kiếm khách hàng
  Future<List<Customer>> searchCustomers(String query) async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final customers = snapshot.docs
          .map((doc) => Customer.fromMap(doc.data(), doc.id))
          .where((customer) => 
              customer.name.toLowerCase().contains(query.toLowerCase()) ||
              customer.phone.contains(query) ||
              customer.address.toLowerCase().contains(query.toLowerCase()) ||
              customer.serviceCompleted.toLowerCase().contains(query.toLowerCase()))
          .toList();
      
      return customers;
    } catch (e) {
      print('Error searching customers: $e');
      return [];
    }
  }
}
