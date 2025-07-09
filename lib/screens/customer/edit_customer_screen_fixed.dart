import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import '../../models/customer.dart';
import '../../models/reminder.dart';
import '../../services/customer_service.dart';
import '../../services/image_service.dart';

class EditCustomerScreen extends StatefulWidget {
  final Customer customer;

  const EditCustomerScreen({super.key, required this.customer});

  @override
  State<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _serviceController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final CustomerService _customerService = CustomerService();
  final ImageService _imageService = ImageService();

  bool _isLoading = false;
  List<ReminderInput> _reminders = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final customer = widget.customer;
    _nameController.text = customer.name;
    _phoneController.text = customer.phone;
    _addressController.text = customer.address;
    _serviceController.text = customer.serviceCompleted;
    _amountController.text = customer.amountSpent.toString();
    _notesController.text = customer.notes ?? '';

    // Chuyển đổi reminders hiện tại thành ReminderInput
    _reminders = customer.reminders
        .map(
          (reminder) => ReminderInput(
            date: reminder.reminderDate,
            description: reminder.description,
            detailedDescription: reminder.detailedDescription,
            imageUrl: reminder.imageUrl,
            isCompleted: reminder.isCompleted,
          ),
        )
        .toList();

    if (_reminders.isEmpty) {
      _reminders.add(ReminderInput());
    }
  }

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
      _reminders.add(
        ReminderInput(description: 'Lịch nhắc ${_reminders.length + 1}'),
      );
    });
  }

  void _removeReminder(int index) {
    if (_reminders.length > 1) {
      setState(() {
        _reminders.removeAt(index);
      });
    }
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final validReminders = _reminders.where((r) => r.isValid).toList();
      final reminderObjects = validReminders
          .map((r) => r.toReminder())
          .toList();

      final updatedCustomer = Customer(
        id: widget.customer.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        serviceCompleted: _serviceController.text.trim(),
        amountSpent: double.tryParse(_amountController.text) ?? 0.0,
        reminders: reminderObjects,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        avatarUrl: widget.customer.avatarUrl, // Giữ nguyên avatarUrl
        createdAt: widget.customer.createdAt,
        updatedAt: DateTime.now(),
      );

      await _customerService.updateCustomer(updatedCustomer);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cập nhật thông tin khách hàng thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi khi cập nhật: $e'),
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
      appBar: AppBar(
        title: const Text('Sửa thông tin khách hàng'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveCustomer,
              child: const Text(
                'Lưu',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
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

              // Ảnh đại diện
              _buildSectionTitle('Ảnh đại diện'),
              const SizedBox(height: 8),
              _buildAvatarSection(),

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
                  final amount = double.tryParse(value);
                  if (amount == null || amount < 0) {
                    return 'Số tiền không hợp lệ';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Lịch nhắc
              _buildSectionTitle('Lịch nhắc'),
              const SizedBox(height: 8),
              ..._buildReminderInputs(),
              const SizedBox(height: 16),
              _buildAddReminderButton(),

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
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.green),
        ),
      ),
      maxLines: maxLines,
    );
  }

  Widget _buildAvatarSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // Avatar hiển thị
          GestureDetector(
            onTap: () => _showEditAvatarOptions(context),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Colors.green.shade100,
              backgroundImage:
                  widget.customer.avatarUrl != null &&
                      widget.customer.avatarUrl!.isNotEmpty
                  ? NetworkImage(widget.customer.avatarUrl!)
                  : null,
              child:
                  widget.customer.avatarUrl == null ||
                      widget.customer.avatarUrl!.isEmpty
                  ? Text(
                      widget.customer.name.isNotEmpty
                          ? widget.customer.name[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          // Thông tin và nút chỉnh sửa
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ảnh đại diện khách hàng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.customer.avatarUrl != null &&
                          widget.customer.avatarUrl!.isNotEmpty
                      ? 'Đã có ảnh đại diện'
                      : 'Chưa có ảnh đại diện',
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        widget.customer.avatarUrl != null &&
                            widget.customer.avatarUrl!.isNotEmpty
                        ? Colors.green
                        : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _showEditAvatarOptions(context),
                  icon: Icon(
                    widget.customer.avatarUrl != null &&
                            widget.customer.avatarUrl!.isNotEmpty
                        ? Icons.edit
                        : Icons.add_a_photo,
                    size: 18,
                  ),
                  label: Text(
                    widget.customer.avatarUrl != null &&
                            widget.customer.avatarUrl!.isNotEmpty
                        ? 'Thay đổi'
                        : 'Thêm ảnh',
                    style: const TextStyle(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
            color: reminder.isCompleted
                ? Colors.green.shade300
                : reminder.isValid
                ? Colors.green.shade300
                : Colors.grey.shade300,
            width: reminder.isCompleted || reminder.isValid ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  reminder.isCompleted ? Icons.check_circle : Icons.schedule,
                  color: reminder.isCompleted ? Colors.green : Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reminder.description.isNotEmpty
                        ? reminder.description
                        : 'Lịch nhắc ${index + 1}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: reminder.isCompleted ? Colors.green : Colors.green,
                      decoration: reminder.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                if (reminder.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'HOÀN THÀNH',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                if (_reminders.length > 1)
                  IconButton(
                    onPressed: () => _removeReminder(index),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Trường mô tả chi tiết
            if (!reminder.isCompleted) ...[
              TextFormField(
                initialValue: reminder.detailedDescription ?? '',
                onChanged: (value) {
                  reminder.detailedDescription = value.isNotEmpty
                      ? value
                      : null;
                },
                decoration: InputDecoration(
                  labelText: 'Mô tả chi tiết',
                  hintText: 'Nhập mô tả chi tiết cho lịch nhắc này...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(
                    Icons.description,
                    color: Colors.green,
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
            ],
            InkWell(
              onTap: reminder.isCompleted
                  ? null
                  : () => _selectDate(context, reminder),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: reminder.isCompleted
                      ? Colors.grey.shade100
                      : Colors.white,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: reminder.isCompleted ? Colors.grey : Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        reminder.date != null
                            ? DateFormat('dd/MM/yyyy').format(reminder.date!)
                            : 'Chọn ngày nhắc',
                        style: TextStyle(
                          fontSize: 14,
                          color: reminder.isCompleted
                              ? Colors.grey
                              : reminder.date != null
                              ? Colors.black
                              : Colors.grey,
                          decoration: reminder.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Thêm CircleAvatar cho ảnh reminder
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.image, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Hình ảnh:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: reminder.isCompleted
                      ? null
                      : () => _showImageOptions(context, index),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage:
                        reminder.imageUrl != null &&
                            reminder.imageUrl!.isNotEmpty
                        ? NetworkImage(reminder.imageUrl!)
                        : null,
                    child:
                        reminder.imageUrl == null || reminder.imageUrl!.isEmpty
                        ? Icon(
                            Icons.add_a_photo,
                            color: reminder.isCompleted
                                ? Colors.grey
                                : Colors.grey.shade600,
                            size: 20,
                          )
                        : null,
                  ),
                ),
              ],
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
        style: TextStyle(color: Colors.green, fontSize: 14),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.green),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, ReminderInput reminder) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: reminder.date ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2034, 12, 31),
    );
    if (picked != null) {
      setState(() {
        reminder.date = picked;
      });
    }
  }

  // Hiển thị options cho avatar
  Future<void> _showEditAvatarOptions(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Chức năng sửa ảnh đại diện sẽ được cập nhật trong version tiếp theo',
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Hiển thị options cho ảnh reminder
  Future<void> _showImageOptions(
    BuildContext context,
    int reminderIndex,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Chức năng sửa ảnh reminder sẽ được cập nhật trong version tiếp theo',
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
