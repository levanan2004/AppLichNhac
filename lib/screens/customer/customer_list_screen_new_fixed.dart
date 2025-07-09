import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/customer.dart';
import '../../models/reminder.dart';
import '../../services/customer_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/notification_icon.dart';
import '../../widgets/customer_avatar.dart';
import 'add_customer_screen.dart';
import 'customer_detail_screen.dart';
import '../auth/role_selection_screen.dart';
import '../auth/admin_dashboard_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final CustomerService _customerService = CustomerService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'urgent'; // 'upcoming', 'name', 'urgent'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lịch nhắc khách hàng',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          const NotificationIcon(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'logout') {
                await _logout();
              } else if (value == 'admin') {
                await _goToAdmin();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'admin',
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Quản trị'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Đăng xuất'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search and Filter Section
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(color: Colors.green),
              child: Column(
                children: [
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm khách hàng...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.green,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Sort options
                  Row(
                    children: [
                      const Text(
                        'Lọc & sắp xếp:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _sortBy,
                            onChanged: (value) {
                              setState(() {
                                _sortBy = value!;
                              });
                            },
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Colors.black),
                            items: const [
                              DropdownMenuItem(
                                value: 'urgent',
                                child: Text('Ưu tiên'),
                              ),
                              DropdownMenuItem(
                                value: 'upcoming',
                                child: Text('Ngày nhắc gần nhất'),
                              ),
                              DropdownMenuItem(
                                value: 'name',
                                child: Text('Tên A-Z'),
                              ),
                              DropdownMenuItem(
                                value: 'completed_today',
                                child: Text('Lịch vừa nhắc hôm nay'),
                              ),
                              DropdownMenuItem(
                                value: 'created_today',
                                child: Text('Lịch vừa thêm hôm nay'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Customer List
            Expanded(
              child: StreamBuilder<List<Customer>>(
                stream: _customerService.getCustomers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Lỗi: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final customers = snapshot.data ?? [];

                  // Filter customers based on sort type first
                  List<Customer> typeFilteredCustomers = customers;
                  
                  if (_sortBy == 'completed_today') {
                    typeFilteredCustomers = customers.where((customer) => 
                        customer.completedTodayReminders.isNotEmpty).toList();
                  } else if (_sortBy == 'created_today') {
                    typeFilteredCustomers = customers.where((customer) => 
                        customer.createdTodayReminders.isNotEmpty).toList();
                  }

                  // Then filter by search query
                  final filteredCustomers = typeFilteredCustomers.where((customer) {
                    if (_searchQuery.isEmpty) return true;
                    return customer.name.toLowerCase().contains(_searchQuery) ||
                        customer.phone.toLowerCase().contains(_searchQuery) ||
                        customer.address.toLowerCase().contains(_searchQuery);
                  }).toList();

                  // Sort customers
                  _sortCustomers(filteredCustomers);

                  if (filteredCustomers.isEmpty) {
                    String emptyMessage = 'Không có khách hàng nào';
                    if (_sortBy == 'completed_today') {
                      emptyMessage = 'Không có khách hàng nào có lịch vừa nhắc hôm nay';
                    } else if (_sortBy == 'created_today') {
                      emptyMessage = 'Không có khách hàng nào có lịch vừa thêm hôm nay';
                    } else if (_searchQuery.isNotEmpty) {
                      emptyMessage = 'Không tìm thấy khách hàng nào';
                    }
                    
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            emptyMessage,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index];
                      return _buildCustomerCard(customer);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    final nearestReminder = _getNearestPendingReminder(customer);
    final urgentCount = _getUrgentRemindersCount(customer);
    final hasUrgentReminders = urgentCount > 0;

    Color borderColor = Colors.transparent;
    double borderWidth = 0;
    
    if (_sortBy == 'completed_today' && customer.completedTodayReminders.isNotEmpty) {
      borderColor = Colors.green;
      borderWidth = 2;
    } else if (_sortBy == 'created_today' && customer.createdTodayReminders.isNotEmpty) {
      borderColor = Colors.blue;
      borderWidth = 2;
    } else if (hasUrgentReminders) {
      borderColor = Colors.red;
      borderWidth = 2;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: borderWidth > 0
            ? BorderSide(color: borderColor, width: borderWidth)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CustomerAvatar(
          avatarUrl: customer.avatarUrl,
          customerName: customer.name,
          radius: 24,
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer.phone.isNotEmpty)
              Text(
                'SĐT: ${customer.phone}',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            if (customer.address.isNotEmpty)
              Text(
                'Địa chỉ: ${customer.address}',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            const SizedBox(height: 4),
            // Show reminder info based on filter type
            if (_sortBy == 'completed_today' && customer.completedTodayReminders.isNotEmpty)
              Text(
                'Đã nhắc hôm nay: ${customer.completedTodayReminders.length} lịch',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              )
            else if (_sortBy == 'created_today' && customer.createdTodayReminders.isNotEmpty)
              Text(
                'Thêm hôm nay: ${customer.createdTodayReminders.length} lịch',
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              )
            else if (nearestReminder != null)
              Text(
                'Nhắc nhở: ${_formatDate(nearestReminder.reminderDate)}',
                style: TextStyle(
                  color: _isReminderOverdue(nearestReminder)
                      ? Colors.red
                      : Colors.orange,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              const Text(
                'Không có nhắc nhở',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_sortBy == 'completed_today' && customer.completedTodayReminders.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${customer.completedTodayReminders.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (_sortBy == 'created_today' && customer.createdTodayReminders.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${customer.createdTodayReminders.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (hasUrgentReminders)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$urgentCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerDetailScreen(customer: customer),
            ),
          );

          // Nếu khách hàng bị xóa, refresh danh sách
          if (result == 'deleted') {
            setState(() {
              // Trigger rebuild để StreamBuilder reload data
            });
          }
        },
      ),
    );
  }

  Reminder? _getNearestPendingReminder(Customer customer) {
    final pendingReminders = customer.reminders
        .where((reminder) => !reminder.isCompleted)
        .toList();

    if (pendingReminders.isEmpty) return null;

    pendingReminders.sort((a, b) => a.reminderDate.compareTo(b.reminderDate));
    return pendingReminders.first;
  }

  int _getUrgentRemindersCount(Customer customer) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return customer.reminders
        .where(
          (reminder) =>
              !reminder.isCompleted &&
              reminder.reminderDate.isBefore(
                today.add(const Duration(days: 1)),
              ),
        )
        .length;
  }

  bool _isReminderOverdue(Reminder reminder) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminderDate = DateTime(
      reminder.reminderDate.year,
      reminder.reminderDate.month,
      reminder.reminderDate.day,
    );

    return reminderDate.isBefore(today);
  }

  void _sortCustomers(List<Customer> customers) {
    switch (_sortBy) {
      case 'urgent':
        customers.sort((a, b) {
          final aUrgentCount = _getUrgentRemindersCount(a);
          final bUrgentCount = _getUrgentRemindersCount(b);

          if (aUrgentCount != bUrgentCount) {
            return bUrgentCount.compareTo(aUrgentCount); // More urgent first
          }

          // If same urgency, sort by nearest reminder
          final aNearestReminder = _getNearestPendingReminder(a);
          final bNearestReminder = _getNearestPendingReminder(b);

          if (aNearestReminder == null && bNearestReminder == null) {
            return a.name.compareTo(b.name);
          }
          if (aNearestReminder == null) return 1;
          if (bNearestReminder == null) return -1;

          return aNearestReminder.reminderDate.compareTo(
            bNearestReminder.reminderDate,
          );
        });
        break;

      case 'upcoming':
        customers.sort((a, b) {
          final aNearestReminder = _getNearestPendingReminder(a);
          final bNearestReminder = _getNearestPendingReminder(b);

          if (aNearestReminder == null && bNearestReminder == null) {
            return a.name.compareTo(b.name);
          }
          if (aNearestReminder == null) return 1;
          if (bNearestReminder == null) return -1;

          return aNearestReminder.reminderDate.compareTo(
            bNearestReminder.reminderDate,
          );
        });
        break;

      case 'name':
        customers.sort((a, b) => a.name.compareTo(b.name));
        break;

      case 'completed_today':
        customers.sort((a, b) {
          // Sort by number of completed reminders today (more first)
          final aCompletedCount = a.completedTodayReminders.length;
          final bCompletedCount = b.completedTodayReminders.length;
          
          if (aCompletedCount != bCompletedCount) {
            return bCompletedCount.compareTo(aCompletedCount);
          }
          
          // If same count, sort by most recent completion time
          final aLatestCompleted = a.completedTodayReminders.isNotEmpty
              ? a.completedTodayReminders
                  .map((r) => r.completedAt!)
                  .reduce((a, b) => a.isAfter(b) ? a : b)
              : DateTime(2000);
          final bLatestCompleted = b.completedTodayReminders.isNotEmpty
              ? b.completedTodayReminders
                  .map((r) => r.completedAt!)
                  .reduce((a, b) => a.isAfter(b) ? a : b)
              : DateTime(2000);
              
          return bLatestCompleted.compareTo(aLatestCompleted);
        });
        break;

      case 'created_today':
        customers.sort((a, b) {
          // Sort by number of created reminders today (more first)
          final aCreatedCount = a.createdTodayReminders.length;
          final bCreatedCount = b.createdTodayReminders.length;
          
          if (aCreatedCount != bCreatedCount) {
            return bCreatedCount.compareTo(aCreatedCount);
          }
          
          // If same count, sort by most recent creation time
          final aLatestCreated = a.createdTodayReminders.isNotEmpty
              ? a.createdTodayReminders
                  .map((r) => r.createdAt)
                  .reduce((a, b) => a.isAfter(b) ? a : b)
              : DateTime(2000);
          final bLatestCreated = b.createdTodayReminders.isNotEmpty
              ? b.createdTodayReminders
                  .map((r) => r.createdAt)
                  .reduce((a, b) => a.isAfter(b) ? a : b)
              : DateTime(2000);
              
          return bLatestCreated.compareTo(aLatestCreated);
        });
        break;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));

    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Hôm nay';
    } else if (dateOnly == yesterday) {
      return 'Hôm qua';
    } else if (dateOnly == tomorrow) {
      return 'Ngày mai';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _goToAdmin() async {
    final userType = await _authService.getUserType();
    if (userType == 'admin') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ admin mới có thể truy cập'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
