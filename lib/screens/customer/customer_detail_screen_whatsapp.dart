import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/customer.dart';
import '../../models/reminder.dart';
import '../../services/customer_service.dart';
import '../../services/whatsapp_service.dart';
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
  final WhatsAppService _whatsappService = WhatsAppService();
  // ignore: unused_field
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
  }

  Future<void> _openWhatsApp() async {
    try {
      final message = _whatsappService.createCustomerMessage(_customer.name);

      // Mở WhatsApp Business
      final result = await _whatsappService.openWhatsAppBusinessChat(
        _customer.phone,
        message: message,
      );

      if (result.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã mở WhatsApp Business thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Không thể mở WhatsApp Business'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi mở WhatsApp Business: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
          // Nút gọi điện (mở WhatsApp)
          IconButton(
            onPressed: _openWhatsApp,
            icon: const Icon(Icons.phone, color: Colors.white),
            tooltip: 'Gọi điện',
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
                const Icon(Icons.info, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Thông tin khách hàng',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
            const SizedBox(height: 12),
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
                const Icon(Icons.spa, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Dịch vụ đã thực hiện',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.check_circle,
              'Trạng thái',
              _customer.serviceCompleted.isNotEmpty
                  ? _customer.serviceCompleted
                  : 'Chưa xác định',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.monetization_on,
              'Số tiền đã chi',
              NumberFormat.currency(
                locale: 'vi_VN',
                symbol: 'đ',
              ).format(_customer.amountSpent),
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
                const Icon(Icons.notifications, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Lịch nhắc (${_customer.reminders.length})',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lịch nhắc chưa hoàn thành
            if (pendingReminders.isNotEmpty) ...[
              const Text(
                'Cần thực hiện:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...pendingReminders.asMap().entries.map((entry) {
                final index = _customer.reminders.indexOf(entry.value);
                return _buildReminderItem(entry.value, index, false);
              }),
              const SizedBox(height: 16),
            ],

            // Lịch nhắc đã hoàn thành
            if (completedReminders.isNotEmpty) ...[
              const Text(
                'Đã hoàn thành:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...completedReminders.asMap().entries.map((entry) {
                final index = _customer.reminders.indexOf(entry.value);
                return _buildReminderItem(entry.value, index, true);
              }),
            ],

            if (_customer.reminders.isEmpty)
              const Center(
                child: Text(
                  'Chưa có lịch nhắc nào',
                  style: TextStyle(fontStyle: FontStyle.italic),
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
            onChanged: (value) => _toggleReminderStatus(index),
            activeColor: Colors.green,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.description,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  'Ngày: ${DateFormat('dd/MM/yyyy').format(reminder.reminderDate)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (isCompleted && reminder.completedAt != null)
                  Text(
                    'Hoàn thành: ${DateFormat('dd/MM/yyyy HH:mm').format(reminder.completedAt!)}',
                    style: const TextStyle(fontSize: 12, color: Colors.green),
                  ),
              ],
            ),
          ),
          if (isOverdue && !isCompleted)
            const Icon(Icons.warning, color: Colors.red, size: 20),
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
                const Icon(Icons.note, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Ghi chú 2',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(_customer.notes!, style: const TextStyle(fontSize: 14)),
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
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
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
              labelText: 'Mô tả',
              hintText: 'Nhập nội dung nhắc nhở...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today),
                  const SizedBox(width: 8),
                  Text(
                    _selectedDate != null
                        ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                        : 'Chọn ngày nhắc nhở',
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
            if (_descriptionController.text.trim().isNotEmpty &&
                _selectedDate != null) {
              final reminder = Reminder(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                reminderDate: _selectedDate!,
                description: _descriptionController.text.trim(),
                isCompleted: false,
                createdAt: DateTime.now(),
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
