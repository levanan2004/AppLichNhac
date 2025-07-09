import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../models/customer.dart';
import '../../models/reminder.dart';
import '../../models/call_log.dart';
import '../../services/customer_service.dart';
import '../../services/call_service.dart';
import '../../services/image_service.dart';
import '../../widgets/customer_avatar.dart';
import 'edit_customer_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen>
    with TickerProviderStateMixin {
  late Customer _customer;
  final CustomerService _customerService = CustomerService();
  final CallService _callService = CallService();
  final ImageService _imageService = ImageService();
  bool _isLoading = false;

  late TabController _tabController;
  List<CallLog> _callLogs = [];
  bool _isLoadingCalls = false;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _tabController = TabController(length: 2, vsync: this);
    _loadCallLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCallLogs() async {
    if (_customer.id == null) return;

    setState(() {
      _isLoadingCalls = true;
    });

    try {
      final callLogs = await _callService.getCallLogsForCustomer(_customer.id!);
      setState(() {
        _callLogs = callLogs;
      });
    } catch (e) {
      print('Lỗi khi tải lịch sử cuộc gọi: $e');
    } finally {
      setState(() {
        _isLoadingCalls = false;
      });
    }
  }

  Future<void> _makeCall() async {
    try {
      final result = await _callService.makeCall(_customer.phone);

      if (result.isSuccess) {
        // Lưu lịch sử cuộc gọi với status phù hợp platform
        final callLog = CallLog(
          customerId: _customer.id!,
          phoneNumber: _customer.phone,
          callTime: DateTime.now(),
          status: _getCallStatusForPlatform(),
          notes: _getCallNotesForPlatform(),
        );

        await _callService.saveCallLog(callLog);

        // Reload lịch sử cuộc gọi
        _loadCallLogs();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getSuccessMessageForPlatform()),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.error ??
                    'Không thể thực hiện cuộc gọi. Vui lòng kiểm tra quyền truy cập.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi gọi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addCallNote(String callLogId) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm ghi chú cuộc gọi'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Ghi chú',
            hintText: 'Nhập ghi chú về cuộc gọi...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final success = await _callService.updateCallLog(callLogId, {
        'notes': result,
      });

      if (success) {
        _loadCallLogs();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã cập nhật ghi chú'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleReminderStatus(int reminderIndex) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedReminders = List<Reminder>.from(_customer.reminders);
      final reminder = updatedReminders[reminderIndex];

      updatedReminders[reminderIndex] = Reminder(
        id: reminder.id,
        reminderDate: reminder.reminderDate,
        description: reminder.description,
        detailedDescription: reminder.detailedDescription, // Giữ lại mô tả chi tiết
        imageUrl: reminder.imageUrl, // Giữ lại URL ảnh
        isCompleted: !reminder.isCompleted,
        createdAt: reminder.createdAt,
        completedAt: !reminder.isCompleted ? DateTime.now() : null,
      );

      final updatedCustomer = Customer(
        id: _customer.id,
        name: _customer.name,
        phone: _customer.phone,
        address: _customer.address,
        serviceCompleted: _customer.serviceCompleted,
        amountSpent: _customer.amountSpent,
        reminders: updatedReminders,
        notes: _customer.notes,
        avatarUrl: _customer.avatarUrl, // Giữ lại URL avatar
        createdAt: _customer.createdAt,
      );

      await _customerService.updateCustomer(updatedCustomer);

      setState(() {
        _customer = updatedCustomer;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật trạng thái nhắc nhở'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi cập nhật: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addNewReminder() async {
    final result = await showDialog<Reminder>(
      context: context,
      builder: (context) => _AddReminderDialog(),
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final updatedReminders = [..._customer.reminders, result];

        final updatedCustomer = Customer(
          id: _customer.id,
          name: _customer.name,
          phone: _customer.phone,
          address: _customer.address,
          serviceCompleted: _customer.serviceCompleted,
          amountSpent: _customer.amountSpent,
          reminders: updatedReminders,
          notes: _customer.notes,
          avatarUrl: _customer.avatarUrl, // Giữ lại URL avatar
          createdAt: _customer.createdAt,
        );

        await _customerService.updateCustomer(updatedCustomer);

        setState(() {
          _customer = updatedCustomer;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã thêm lịch nhắc mới'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi thêm lịch nhắc: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _editCustomer() async {
    final result = await Navigator.push<Customer>(
      context,
      MaterialPageRoute(
        builder: (context) => EditCustomerScreen(customer: _customer),
      ),
    );

    if (result != null) {
      setState(() {
        _customer = result;
      });
    }
  }

  Future<void> _deleteCustomer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa khách hàng "${_customer.name}"?\n\n'
          'Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && _customer.id != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final success = await _customerService.deleteCustomer(_customer.id!);

        if (mounted) {
          if (success) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã xóa khách hàng'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không thể xóa khách hàng'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi xóa: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F8),
      appBar: AppBar(
        title: Text(
          _customer.name,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Nút gọi điện thoại
          IconButton(
            onPressed: _makeCall,
            icon: const Icon(Icons.phone, color: Colors.white),
            tooltip: 'Gọi điện thoại',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editCustomer();
                  break;
                case 'delete':
                  _deleteCustomer();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Chỉnh sửa'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Xóa khách hàng'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Thông tin'),
            Tab(icon: Icon(Icons.phone), text: 'Lịch sử gọi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildInfoTab(), _buildCallHistoryTab()],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _addNewReminder,
              backgroundColor: Colors.green,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thông tin cơ bản
          _buildInfoCard(),
          const SizedBox(height: 16),
          // Dịch vụ đã thực hiện
          _buildServiceCard(),
          const SizedBox(height: 16),
          // Lịch nhắc nhở
          _buildRemindersCard(),
          if (_customer.notes != null && _customer.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildNotesCard(),
            const SizedBox(height: 16),
            _buildDistanceCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildCallHistoryTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.phone, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Lịch sử cuộc gọi (${_callLogs.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingCalls
              ? const Center(child: CircularProgressIndicator())
              : _callLogs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone_disabled, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Chưa có cuộc gọi nào',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _callLogs.length,
                  itemBuilder: (context, index) {
                    final callLog = _callLogs[index];
                    return _buildCallLogItem(callLog);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCallLogItem(CallLog callLog) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCallStatusColor(callLog.status),
          child: Icon(_getCallStatusIcon(callLog.status), color: Colors.white),
        ),
        title: Text(
          DateFormat('dd/MM/yyyy HH:mm').format(callLog.callTime),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Số điện thoại: ${callLog.phoneNumber}'),
            if (callLog.notes != null && callLog.notes!.isNotEmpty)
              Text('Ghi chú: ${callLog.notes}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.note_add),
          onPressed: () => _addCallNote(callLog.id!),
          tooltip: 'Thêm ghi chú',
        ),
      ),
    );
  }

  Color _getCallStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'missed':
        return Colors.red;
      case 'busy':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getCallStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.call;
      case 'missed':
        return Icons.call_missed;
      case 'busy':
        return Icons.call_end;
      default:
        return Icons.phone;
    }
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Thông tin khách hàng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Spacer(),
                // Avatar khách hàng với loading state và error handling
                CustomerAvatar(
                  avatarUrl: _customer.avatarUrl,
                  customerName: _customer.name,
                  radius: 30,
                  onTap: () => _showCustomerAvatarOptions(),
                  showBorder: true,
                  borderColor: Colors.green.shade300,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person, 'Tên', _customer.name),
            _buildInfoRow(Icons.phone, 'Số điện thoại', _customer.phone),
            _buildInfoRow(Icons.location_on, 'Địa chỉ', _customer.address),
            _buildInfoRow(
              Icons.calendar_today,
              'Ngày tạo',
              DateFormat('dd/MM/yyyy').format(_customer.createdAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.spa, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Dịch vụ đã thực hiện',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.spa, 'Dịch vụ', _customer.serviceCompleted),
            _buildInfoRow(
              Icons.attach_money,
              'Số tiền đã chi tiêu',
              '${NumberFormat('#,##0').format(_customer.amountSpent)} VNĐ',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Lịch nhắc nhở (${_customer.reminders.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_customer.reminders.isEmpty)
              const Center(
                child: Text(
                  'Chưa có lịch nhắc nhở nào',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ..._customer.reminders.asMap().entries.map((entry) {
                int index = entry.key;
                Reminder reminder = entry.value;
                return _buildReminderItem(reminder, index);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderItem(Reminder reminder, int index) {
    final isOverdue =
        reminder.reminderDate.isBefore(DateTime.now()) && !reminder.isCompleted;
    final isToday =
        DateFormat('yyyy-MM-dd').format(reminder.reminderDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: reminder.isCompleted
            ? Colors.green.shade50
            : isOverdue
            ? Colors.red.shade50
            : isToday
            ? Colors.orange.shade50
            : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: reminder.isCompleted
              ? Colors.green
              : isOverdue
              ? Colors.red
              : isToday
              ? Colors.orange
              : Colors.blue,
        ),
      ),
      child: Row(
        children: [
          Icon(
            reminder.isCompleted
                ? Icons.check_circle
                : isOverdue
                ? Icons.warning
                : isToday
                ? Icons.today
                : Icons.schedule,
            color: reminder.isCompleted
                ? Colors.green
                : isOverdue
                ? Colors.red
                : isToday
                ? Colors.orange
                : Colors.blue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.description,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    decoration: reminder.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                // Hiển thị mô tả chi tiết nếu có
                if (reminder.detailedDescription != null && reminder.detailedDescription!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reminder.detailedDescription!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                      decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy').format(reminder.reminderDate),
                  style: const TextStyle(color: Colors.grey),
                ),
                if (reminder.isCompleted && reminder.completedAt != null)
                  Text(
                    'Hoàn thành: ${DateFormat('dd/MM/yyyy HH:mm').format(reminder.completedAt!)}',
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (!reminder.isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isOverdue
                    ? Colors.red
                    : isToday
                    ? Colors.orange
                    : Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isOverdue
                    ? 'QUÁ HẠN'
                    : isToday
                    ? 'HÔM NAY'
                    : 'SẮP TỚI',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          IconButton(
            onPressed: _isLoading ? null : () => _toggleReminderStatus(index),
            icon: Icon(
              reminder.isCompleted
                  ? Icons.check_box
                  : Icons.check_box_outline_blank,
              color: reminder.isCompleted ? Colors.green : Colors.grey,
            ),
          ),
          // Thêm widget cho hình ảnh reminder
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showReminderImageOptions(reminder, index),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
                image: reminder.imageUrl != null && reminder.imageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(reminder.imageUrl!),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {
                          // Handle error quietly
                        },
                      )
                    : null,
              ),
              child: reminder.imageUrl == null || reminder.imageUrl!.isEmpty
                  ? const Icon(Icons.add_a_photo, color: Colors.grey, size: 20)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.note, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text(
                    'Ghi chú',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(_customer.notes!, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Hiển thị tùy chọn cho avatar khách hàng
  Future<void> _showCustomerAvatarOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Ảnh đại diện khách hàng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                if (_customer.avatarUrl != null && _customer.avatarUrl!.isNotEmpty) ...[
                  ListTile(
                    leading: const Icon(Icons.visibility, color: Colors.blue),
                    title: const Text('Xem ảnh đại diện'),
                    onTap: () {
                      Navigator.pop(context);
                      _showCustomerAvatarViewer(_customer.avatarUrl!);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit, color: Colors.orange),
                    title: const Text('Thay đổi ảnh đại diện'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndUploadCustomerAvatar();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Xóa ảnh đại diện'),
                    onTap: () {
                      Navigator.pop(context);
                      _deleteCustomerAvatar();
                    },
                  ),
                ] else ...[
                  ListTile(
                    leading: const Icon(Icons.add_a_photo, color: Colors.green),
                    title: const Text('Thêm ảnh đại diện'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndUploadCustomerAvatar();
                    },
                  ),
                ],
                
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  // Hiển thị ảnh avatar khách hàng fullscreen
  void _showCustomerAvatarViewer(String avatarUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.black,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Ảnh đại diện khách hàng',
                style: TextStyle(color: Colors.white),
              ),
            ),
            Container(
              height: 300,
              child: Center(
                child: Image.network(
                  avatarUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const CircularProgressIndicator(color: Colors.white);
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error, color: Colors.white, size: 48);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Chọn và upload avatar khách hàng
  Future<void> _pickAndUploadCustomerAvatar() async {
    try {
      // Hiển thị dialog chọn nguồn ảnh
      final imageFile = await _imageService.showImageSourceDialog(context);
      if (imageFile == null) {
        return; // User đã hủy
      }

      // Hiển thị loading
      setState(() {
        _isLoading = true;
      });

      // Hiển thị dialog loading với progress
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang upload ảnh...'),
            ],
          ),
        ),
      );

      // Đọc file thành bytes
      final imageBytes = await imageFile.readAsBytes();

      // Sử dụng updateCustomerAvatar để xóa ảnh cũ và upload ảnh mới
      final avatarUrl = await _imageService.updateCustomerAvatar(
        oldAvatarUrl: _customer.avatarUrl, // Xóa ảnh cũ nếu có
        newImageBytes: imageBytes,
        customerId: _customer.id!,
        originalFileName: imageFile.path.split('/').last,
      );

      // Đóng dialog loading
      if (mounted) Navigator.pop(context);

      if (avatarUrl != null) {
        // Thêm timestamp để force cache invalidation
        final timestampedUrl = '$avatarUrl?t=${DateTime.now().millisecondsSinceEpoch}';
        
        // Cập nhật customer với URL avatar mới
        final updatedCustomer = _customer.copyWith(avatarUrl: timestampedUrl);
        await _customerService.updateCustomer(updatedCustomer);

        setState(() {
          _customer = updatedCustomer;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đã cập nhật ảnh đại diện thành công!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Không thể upload ảnh. Vui lòng thử lại.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Đóng dialog loading nếu còn mở
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi khi upload ảnh: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Xóa avatar khách hàng
  Future<void> _deleteCustomerAvatar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa ảnh đại diện?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() {
          _isLoading = true;
        });

        // Xóa ảnh từ Storage
        if (_customer.avatarUrl != null && _customer.avatarUrl!.isNotEmpty) {
          await _imageService.deleteCustomerAvatar(_customer.avatarUrl!);
        }

        // Cập nhật customer với avatarUrl = null
        final updatedCustomer = _customer.copyWith(clearAvatarUrl: true);
        await _customerService.updateCustomer(updatedCustomer);

        setState(() {
          _customer = updatedCustomer;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa ảnh đại diện'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi xóa ảnh: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Hiển thị tùy chọn cho ảnh reminder
  Future<void> _showReminderImageOptions(Reminder reminder, int reminderIndex) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Ảnh nhắc nhở',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                if (reminder.imageUrl != null && reminder.imageUrl!.isNotEmpty) ...[
                  ListTile(
                    leading: const Icon(Icons.visibility, color: Colors.blue),
                    title: const Text('Xem ảnh'),
                    onTap: () {
                      Navigator.pop(context);
                      _showReminderImageViewer(reminder.imageUrl!);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit, color: Colors.orange),
                    title: const Text('Thay đổi ảnh'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndUploadReminderImage(reminder, reminderIndex);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Xóa ảnh'),
                    onTap: () {
                      Navigator.pop(context);
                      _deleteReminderImage(reminder, reminderIndex);
                    },
                  ),
                ] else ...[
                  ListTile(
                    leading: const Icon(Icons.add_a_photo, color: Colors.green),
                    title: const Text('Thêm ảnh'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndUploadReminderImage(reminder, reminderIndex);
                    },
                  ),
                ],
                
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  // Hiển thị ảnh reminder fullscreen
  void _showReminderImageViewer(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.black,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Ảnh nhắc nhở',
                style: TextStyle(color: Colors.white),
              ),
            ),
            Container(
              height: 300,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const CircularProgressIndicator(color: Colors.white);
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error, color: Colors.white, size: 48);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Chọn và upload ảnh reminder
  Future<void> _pickAndUploadReminderImage(Reminder reminder, int reminderIndex) async {
    try {
      // Hiển thị dialog chọn nguồn ảnh
      final imageFile = await _imageService.showImageSourceDialog(context);
      if (imageFile == null) {
        return; // User đã hủy
      }

      // Hiển thị loading
      setState(() {
        _isLoading = true;
      });

      // Hiển thị dialog loading với progress
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang upload ảnh nhắc nhở...'),
            ],
          ),
        ),
      );

      // Đọc file thành bytes
      final imageBytes = await imageFile.readAsBytes();

      // Sử dụng updateReminderImage để xóa ảnh cũ và upload ảnh mới
      final imageUrl = await _imageService.updateReminderImage(
        oldImageUrl: reminder.imageUrl, // Xóa ảnh cũ nếu có
        newImageBytes: imageBytes,
        customerId: _customer.id!,
        reminderId: reminder.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        originalFileName: imageFile.path.split('/').last,
      );

      // Đóng dialog loading
      if (mounted) Navigator.pop(context);

      if (imageUrl != null) {
        // Cập nhật reminder với URL ảnh mới
        final updatedReminders = List<Reminder>.from(_customer.reminders);
        updatedReminders[reminderIndex] = reminder.copyWith(imageUrl: imageUrl);

        final updatedCustomer = _customer.copyWith(reminders: updatedReminders);
        await _customerService.updateCustomer(updatedCustomer);

        setState(() {
          _customer = updatedCustomer;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đã cập nhật ảnh nhắc nhở thành công!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Không thể upload ảnh. Vui lòng thử lại.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Đóng dialog loading nếu còn mở
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi khi upload ảnh: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Xóa ảnh reminder
  Future<void> _deleteReminderImage(Reminder reminder, int reminderIndex) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa ảnh này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() {
          _isLoading = true;
        });

        // Xóa ảnh từ Storage
        if (reminder.imageUrl != null && reminder.imageUrl!.isNotEmpty) {
          await _imageService.deleteReminderImage(reminder.imageUrl!);
        }

        // Cập nhật reminder với imageUrl = null
        final updatedReminders = List<Reminder>.from(_customer.reminders);
        updatedReminders[reminderIndex] = reminder.copyWith(clearImageUrl: true);

        final updatedCustomer = _customer.copyWith(reminders: updatedReminders);
        await _customerService.updateCustomer(updatedCustomer);

        setState(() {
          _customer = updatedCustomer;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa ảnh nhắc nhở'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi xóa ảnh: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Helper methods for platform-specific call handling
  String _getCallStatusForPlatform() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'initiated'; // iOS không thể xác định trạng thái thực tế
    } else {
      return 'completed'; // Android có thể theo dõi tốt hơn
    }
  }

  String? _getCallNotesForPlatform() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'Cuộc gọi được khởi tạo từ iOS - trạng thái thực tế không xác định được';
    }
    return null;
  }

  String _getSuccessMessageForPlatform() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'Đã mở ứng dụng gọi điện. Lịch sử cuộc gọi đã được lưu.';
    } else {
      return 'Đang thực hiện cuộc gọi. Lịch sử cuộc gọi đã được lưu.';
    }
  }
}

class _AddReminderDialog extends StatefulWidget {
  @override
  State<_AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<_AddReminderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _detailedDescriptionController = TextEditingController(); // Thêm controller cho mô tả chi tiết
  DateTime? _selectedDate;

  @override
  void dispose() {
    _descriptionController.dispose();
    _detailedDescriptionController.dispose(); // Dispose controller mới
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm lịch nhắc nhở'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề nhắc nhở',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tiêu đề';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _detailedDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả chi tiết',
                hintText: 'Nhập mô tả chi tiết cho lịch nhắc...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate != null
                          ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                          : 'Chọn ngày nhắc',
                      style: TextStyle(
                        color: _selectedDate != null
                            ? Colors.black
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _saveReminder,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Lưu', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveReminder() {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      final reminder = Reminder(
        reminderDate: _selectedDate!,
        description: _descriptionController.text.trim(),
        detailedDescription: _detailedDescriptionController.text.trim().isNotEmpty 
            ? _detailedDescriptionController.text.trim() 
            : null, // Thêm mô tả chi tiết
        imageUrl: null, // Chưa có ảnh khi tạo mới
      );
      Navigator.pop(context, reminder);
    } else if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngày nhắc'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

Widget _buildDistanceCard() {
  return Container(
    margin: const EdgeInsets.only(bottom: 40),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: const [
            Icon(Icons.straighten, color: Colors.green),
            SizedBox(width: 8),
            Text(
              'Khoảng cách',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
