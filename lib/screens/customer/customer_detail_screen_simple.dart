import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/customer.dart';
import '../../models/reminder.dart';
import '../../services/customer_service.dart';
import 'edit_customer_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late Customer _customer;
  final CustomerService _customerService = CustomerService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
  }

  Future<void> _toggleReminderStatus(int reminderIndex) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedReminders = List<Reminder>.from(_customer.reminders);
      final reminder = updatedReminders[reminderIndex];

      // Tạo reminder mới với trạng thái đã thay đổi
      updatedReminders[reminderIndex] = Reminder(
        id: reminder.id,
        reminderDate: reminder.reminderDate,
        description: reminder.description,
        detailedDescription: reminder.detailedDescription, // Giữ lại mô tả chi tiết
        isCompleted: !reminder.isCompleted,
        createdAt: reminder.createdAt,
        completedAt: !reminder.isCompleted ? DateTime.now() : null,
      );

      // Tạo customer mới với reminders đã cập nhật
      final updatedCustomer = Customer(
        id: _customer.id,
        name: _customer.name,
        phone: _customer.phone,
        address: _customer.address,
        serviceCompleted: _customer.serviceCompleted,
        amountSpent: _customer.amountSpent,
        reminders: updatedReminders,
        notes: _customer.notes,
        createdAt: _customer.createdAt,
      );

      await _customerService.updateCustomer(updatedCustomer);

      setState(() {
        _customer = updatedCustomer;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              reminder.isCompleted
                  ? 'Đã bỏ đánh dấu hoàn thành'
                  : 'Đã đánh dấu hoàn thành',
            ),
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
            Navigator.pop(context, 'deleted');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã xóa khách hàng ${_customer.name}'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Lỗi khi xóa khách hàng'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi xóa khách hàng: $e'),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'edit') {
                _editCustomer();
              } else if (value == 'delete') {
                _deleteCustomer();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Sửa thông tin'),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin khách hàng
            _buildInfoSection(),

            const SizedBox(height: 24),

            // Dịch vụ đã thực hiện
            _buildServiceSection(),

            const SizedBox(height: 24),

            // Lịch nhắc
            _buildRemindersSection(),

            const SizedBox(height: 24),

            // Ghi chú
            if (_customer.notes != null && _customer.notes!.isNotEmpty)
              _buildNotesSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewReminder,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Thông tin khách hàng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.phone, 'Số điện thoại', _customer.phone),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on, 'Địa chỉ', _customer.address),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.spa, color: Colors.green, size: 24),
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
            _buildInfoRow(
              Icons.medical_services,
              'Dịch vụ',
              _customer.serviceCompleted,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.attach_money,
              'Số tiền đã chi',
              '${NumberFormat('#,###').format(_customer.amountSpent)} VNĐ',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersSection() {
    final pendingReminders = _customer.reminders
        .where((r) => !r.isCompleted)
        .toList();
    final completedReminders = _customer.reminders
        .where((r) => r.isCompleted)
        .toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Lịch nhắc',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_customer.reminders.length} lịch nhắc',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pending reminders
            if (pendingReminders.isNotEmpty) ...[
              const Text(
                'Cần xử lý:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              ...pendingReminders.map((reminder) {
                final index = _customer.reminders.indexOf(reminder);
                return _buildReminderItem(reminder, index, false);
              }),
            ],

            // Completed reminders
            if (completedReminders.isNotEmpty) ...[
              if (pendingReminders.isNotEmpty) const SizedBox(height: 16),
              const Text(
                'Đã hoàn thành:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              ...completedReminders.map((reminder) {
                final index = _customer.reminders.indexOf(reminder);
                return _buildReminderItem(reminder, index, true);
              }),
            ],

            if (_customer.reminders.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Chưa có lịch nhắc nào',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderItem(Reminder reminder, int index, bool isCompleted) {
    final isOverdue =
        !isCompleted && reminder.reminderDate.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.shade50
            : isOverdue
            ? Colors.red.shade50
            : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted
              ? Colors.green.shade200
              : isOverdue
              ? Colors.red.shade200
              : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isCompleted,
            onChanged: _isLoading
                ? null
                : (value) => _toggleReminderStatus(index),
            activeColor: Colors.green,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.description,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? Colors.grey : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy').format(reminder.reminderDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: isCompleted
                        ? Colors.grey
                        : isOverdue
                        ? Colors.red
                        : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isOverdue && !isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'QUÁ HẠN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note, color: Colors.green, size: 24),
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
            const SizedBox(height: 12),
            Text(
              _customer.notes!,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
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
    );
  }
}

class _AddReminderDialog extends StatefulWidget {
  @override
  State<_AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<_AddReminderDialog> {
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm lịch nhắc mới'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Mô tả lịch nhắc',
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
                  const Icon(Icons.calendar_today, color: Colors.green),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate != null
                        ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                        : 'Chọn ngày nhắc',
                    style: TextStyle(
                      color: _selectedDate != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_descriptionController.text.isNotEmpty &&
                _selectedDate != null) {
              final reminder = Reminder(
                reminderDate: _selectedDate!,
                description: _descriptionController.text,
              );
              Navigator.pop(context, reminder);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Thêm', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
