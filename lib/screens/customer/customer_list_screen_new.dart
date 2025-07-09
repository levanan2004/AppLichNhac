import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../models/customer.dart';
import '../../services/customer_service.dart';
import '../../widgets/notification_icon.dart';
import 'add_customer_screen_new.dart';
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
  String _sortBy = 'urgent'; // 'name', 'urgent', 'newest'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F8),
      appBar: AppBar(
        title: Text(
          'Lịch nhắc khách hàng',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
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
              padding: EdgeInsets.all(16.w),
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm khách hàng...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // Sort Options
                  Row(
                    children: [
                      Text(
                        'Sắp xếp: ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14.sp,
                        ),
                      ),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _sortBy,
                          dropdownColor: Colors.green[400],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                          ),
                          underline: Container(),
                          items: const [
                            DropdownMenuItem(
                              value: 'urgent',
                              child: Text(
                                'Ưu tiên',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'newest',
                              child: Text(
                                'Mới nhất',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'name',
                              child: Text(
                                'Tên A-Z',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _sortBy = value!;
                            });
                          },
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64.sp,
                            color: Colors.red,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Lỗi: ${snapshot.error}',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  List<Customer> customers = snapshot.data ?? [];

                  // Filter customers based on search query
                  if (_searchQuery.isNotEmpty) {
                    customers = customers.where((customer) {
                      return customer.name.toLowerCase().contains(
                            _searchQuery,
                          ) ||
                          customer.phone.contains(_searchQuery) ||
                          customer.address.toLowerCase().contains(_searchQuery);
                    }).toList();
                  }

                  // Sort customers
                  customers = _sortCustomers(customers);

                  if (customers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64.sp,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Không tìm thấy khách hàng'
                                : 'Chưa có khách hàng nào',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Thử tìm kiếm với từ khóa khác'
                                : 'Nhấn nút + để thêm khách hàng mới',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
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
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
          );
          if (result == true) {
            // Refresh the list by rebuilding the StreamBuilder
            setState(() {});
          }
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  List<Customer> _sortCustomers(List<Customer> customers) {
    switch (_sortBy) {
      case 'urgent':
        customers.sort((a, b) {
          // Sort by priority: overdue -> today -> tomorrow -> soon -> others
          int priorityA = a.notificationPriority;
          int priorityB = b.notificationPriority;
          return priorityA.compareTo(priorityB);
        });
        break;
      case 'newest':
        customers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'name':
        customers.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
    return customers;
  }

  Widget _buildCustomerCard(Customer customer) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      color: customer.backgroundColor,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerDetailScreen(customer: customer),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with name and status
              Row(
                children: [
                  Icon(
                    customer.statusIcon,
                    color: customer.textColor,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      customer.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: customer.textColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: customer.badgeColor,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      customer.statusText,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Customer info
              _buildInfoRow(Icons.phone, customer.phone),
              _buildInfoRow(Icons.location_on, customer.address),
              _buildInfoRow(Icons.spa, customer.serviceCompleted),
              _buildInfoRow(
                Icons.attach_money,
                '${NumberFormat('#,###').format(customer.amountSpent)} VNĐ',
              ),

              SizedBox(height: 12.h),

              // Reminders summary
              if (customer.reminders.isNotEmpty) ...[
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16.sp,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Lịch nhắc: ${customer.reminders.length}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (customer.overdueReminders.isNotEmpty) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            '${customer.overdueReminders.length} quá hạn',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (customer.todayReminders.isNotEmpty) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            '${customer.todayReminders.length} hôm nay',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: Colors.grey.shade600),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
