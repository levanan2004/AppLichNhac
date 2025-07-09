import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/customer.dart';
import '../../models/reminder.dart';
import '../../services/customer_service.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _serviceController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final CustomerService _customerService = CustomerService();

  bool _isLoading = false;
  List<ReminderInput> _reminders = []; // Bắt đầu với danh sách rỗng

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _serviceController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addReminder() {
    setState(() {
      _reminders.add(ReminderInput(description: 'Lịch nhắc ${_reminders.length + 1}'));
    });
  }

  void _removeReminder(int index) {
    if (_reminders.length > 1) {
      setState(() {
        _reminders.removeAt(index);
      });
    }
  }

  void _addAutoReminders() {
    // Luôn luôn dùng ngày hiện tại làm mốc
    final baseDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo lịch nhắc tự động'),
        content: const Text(
          'Tạo lịch nhắc tự động cho khách hàng này?\n\n'
          'Sẽ tạo 6 lịch nhắc:\n'
          '- 3 ngày sau\n'
          '- 7 ngày sau\n'
          '- 15 ngày sau\n'
          '- 1 tháng sau\n'
          '- 3 tháng sau\n'
          '- 6 tháng sau',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generateAutoReminders(baseDate);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Tạo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _generateAutoReminders(DateTime baseDate) {
    setState(() {
      _reminders = [
        ReminderInput(
          description: 'Lịch nhắc 1 (CSKH sau 3 ngày)',
          date: baseDate.add(const Duration(days: 3)),
        ),
        ReminderInput(
          description: 'Lịch nhắc 2 (CSKH sau 7 ngày)',
          date: baseDate.add(const Duration(days: 7)),
        ),
        ReminderInput(
          description: 'Lịch nhắc 3 (CSKH sau 15 ngày)',
          date: baseDate.add(const Duration(days: 15)),
        ),
        ReminderInput(
          description: 'Lịch nhắc 4 (CSKH sau 1 tháng)',
          date: DateTime(baseDate.year, baseDate.month + 1, baseDate.day),
        ),
        ReminderInput(
          description: 'Lịch nhắc 5 (CSKH sau 3 tháng)',
          date: DateTime(baseDate.year, baseDate.month + 3, baseDate.day),
        ),
        ReminderInput(
          description: 'Lịch nhắc 6 (CSKH sau 6 tháng)',
          date: DateTime(baseDate.year, baseDate.month + 6, baseDate.day),
        ),
      ];
    });
  }

  void _clearAllReminders() {
    setState(() {
      _reminders = [];
    });
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    // Lọc ra những reminder hợp lệ (có đủ thông tin)
    final validReminders = _reminders
        .where((r) => r.date != null && r.description.isNotEmpty)
        .toList();

    setState(() {
      _isLoading = true;
    });

    try {
      // Tạo danh sách reminders từ input (có thể rỗng)
      List<Reminder> reminders = validReminders
          .map((r) => Reminder(
                reminderDate: r.date!,
                description: r.description,
                detailedDescription: r.detailedDescription, // Thêm mô tả chi tiết
              ))
          .toList();

      final customer = Customer(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        serviceCompleted: _serviceController.text.trim(),
        amountSpent: double.tryParse(_amountController.text) ?? 0.0,
        reminders: reminders,
        notes: _notesController.text.trim().isEmpty 
            ? null
            : _notesController.text.trim(),
      );

      await _customerService.addCustomer(customer);
      
      if (mounted) {
        Navigator.pop(context, true);
        final reminderCount = reminders.length;
        final message = reminderCount > 0 
            ? 'Đã thêm khách hàng ${customer.name} với $reminderCount lịch nhắc'
            : 'Đã thêm khách hàng ${customer.name}';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi thêm khách hàng: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F8),
      appBar: AppBar(
        title: const Text(
          'Thêm khách hàng',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thông tin cơ bản
              _buildSectionTitle('Thông tin cơ bản'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nameController,
                label: 'Tên khách hàng',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên khách hàng';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Số điện thoại',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số điện thoại';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                label: 'Địa chỉ',
                icon: Icons.location_on,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập địa chỉ';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Thông tin dịch vụ
              _buildSectionTitle('Thông tin dịch vụ'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _serviceController,
                label: 'Dịch vụ đã thực hiện',
                icon: Icons.spa,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập dịch vụ đã thực hiện';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _amountController,
                label: 'Số tiền đã chi tiêu (VNĐ)',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số tiền';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Số tiền không hợp lệ';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Lịch nhắc
              Row(
                children: [
                  _buildSectionTitle('Lịch nhắc'),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_reminders.where((r) => r.isValid).length} nhắc nhở',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Buttons để quản lý reminders
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addAutoReminders,
                      icon: const Icon(Icons.auto_awesome, color: Colors.green),
                      label: const Text(
                        'Tạo tự động',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _clearAllReminders,
                      icon: const Icon(Icons.clear_all, color: Colors.orange),
                      label: const Text(
                        'Xóa tất cả',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.orange),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._buildReminderInputs(),
              const SizedBox(height: 8),
              if (_reminders.isNotEmpty || _reminders.isEmpty) _buildAddReminderButton(),
              
              const SizedBox(height: 24),
              
              // Ghi chú
              _buildSectionTitle('Ghi chú'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _notesController,
                label: 'Ghi chú (tùy chọn)',
                icon: Icons.note,
                maxLines: 3,
              ),
              
              const SizedBox(height: 32),
              
              // Nút lưu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Lưu khách hàng',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32), // Thêm margin bottom cho button (20 + 12)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.green,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  List<Widget> _buildReminderInputs() {
    return _reminders.asMap().entries.map((entry) {
      int index = entry.key;
      ReminderInput reminder = entry.value;
      
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: reminder.isValid ? Colors.green.shade300 : Colors.grey.shade300,
            width: reminder.isValid ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reminder.description.isNotEmpty 
                        ? reminder.description 
                        : 'Lịch nhắc ${index + 1}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
                if (_reminders.length > 1)
                  IconButton(
                    onPressed: () => _removeReminder(index),
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Trường mô tả chi tiết
            TextFormField(
              initialValue: reminder.detailedDescription ?? '',
              onChanged: (value) {
                reminder.detailedDescription = value.isNotEmpty ? value : null;
              },
              decoration: InputDecoration(
                labelText: 'Mô tả chi tiết',
                hintText: 'Nhập mô tả chi tiết cho lịch nhắc này...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.description, color: Colors.green),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _selectDate(context, reminder),
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
                      reminder.date != null
                          ? DateFormat('dd/MM/yyyy').format(reminder.date!)
                          : 'Chọn ngày nhắc',
                      style: TextStyle(
                        color: reminder.date != null ? Colors.black : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildAddReminderButton() {
    return OutlinedButton.icon(
      onPressed: _addReminder,
      icon: const Icon(Icons.add, color: Colors.green),
      label: const Text(
        'Thêm lịch nhắc',
        style: TextStyle(
          color: Colors.green,
          fontSize: 14,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.green),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, ReminderInput reminder) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: reminder.date ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        reminder.date = picked;
      });
    }
  }
}
