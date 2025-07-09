import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/customer.dart';
import '../../models/reminder.dart';
import '../../services/customer_service.dart';
import '../../widgets/notification_icon.dart';
import '../../widgets/customer_avatar.dart';
import 'add_customer_screen.dart';
import 'customer_detail_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final CustomerService _customerService = CustomerService();
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
        actions: [const NotificationIcon()],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search and Filter Section
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.green.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  // Search bar với design đẹp hơn
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
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
                        hintText: 'Tìm kiếm theo tên, SĐT, địa chỉ...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Container(
                          padding: const EdgeInsets.all(12),
                          child: const Icon(
                            Icons.search,
                            color: Colors.green,
                            size: 24,
                          ),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filter chips với design đẹp
                  Row(
                    children: [
                      const Icon(
                        Icons.filter_list,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Lọc:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip(
                                'urgent',
                                'Ưu tiên',
                                Icons.notification_important,
                                Colors.red.shade400,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'upcoming',
                                'Sắp tới',
                                Icons.schedule,
                                Colors.orange.shade400,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'name',
                                'Tên A-Z',
                                Icons.sort_by_alpha,
                                Colors.blue.shade400,
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

                  // Filter customers
                  final filteredCustomers = customers.where((customer) {
                    if (_searchQuery.isEmpty) return true;
                    return customer.name.toLowerCase().contains(_searchQuery) ||
                        customer.phone.toLowerCase().contains(_searchQuery) ||
                        customer.address.toLowerCase().contains(_searchQuery);
                  }).toList();

                  // Sort customers
                  _sortCustomers(filteredCustomers);

                  // Tính toán stats
                  final urgentCount = customers
                      .where((c) => _getUrgentRemindersCount(c) > 0)
                      .length;
                  final upcomingCount = customers
                      .where((c) => _getNearestPendingReminder(c) != null)
                      .length;

                  return Column(
                    children: [
                      // Stats bar
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _buildStatItem(
                              'Tổng số',
                              '${customers.length}',
                              Icons.people,
                              Colors.blue,
                            ),
                            _buildStatDivider(),
                            _buildStatItem(
                              'Cần nhắc',
                              '$urgentCount',
                              Icons.notification_important,
                              Colors.red,
                            ),
                            _buildStatDivider(),
                            _buildStatItem(
                              'Có lịch',
                              '$upcomingCount',
                              Icons.schedule,
                              Colors.orange,
                            ),
                          ],
                        ),
                      ),

                      // Customer list
                      Expanded(
                        child: filteredCustomers.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: filteredCustomers.length,
                                itemBuilder: (context, index) {
                                  final customer = filteredCustomers[index];
                                  return _buildCustomerCard(customer);
                                },
                              ),
                      ),
                    ],
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasUrgentReminders
            ? const BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CustomerAvatar(
          avatarUrl: customer.avatarUrl,
          customerName: customer.name,
          radius: 24,
          backgroundColor: hasUrgentReminders ? Colors.red.shade100 : Colors.green.shade100,
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
            // Show reminder info
            if (nearestReminder != null)
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
            if (hasUrgentReminders)
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerDetailScreen(customer: customer),
            ),
          );
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

  // Tạo filter chip đẹp mắt
  Widget _buildFilterChip(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _sortBy == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget hiển thị stats item
  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // Divider giữa các stats
  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.shade300,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  // Widget hiển thị khi không có dữ liệu
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'Không tìm thấy khách hàng nào'
                : 'Chưa có khách hàng nào',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Thử tìm kiếm với từ khóa khác'
                : 'Hãy thêm khách hàng đầu tiên của bạn',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
