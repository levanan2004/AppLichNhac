import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/customer.dart';
import '../../models/reminder.dart';
import '../../services/customer_service.dart';
import '../../services/image_service.dart';
import '../../widgets/customer_avatar.dart';

class EditCustomerScreen extends StatefulWidget {
  final Customer customer;

  const EditCustomerScreen({
    super.key,
    required this.customer,
  });

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
  late Customer _currentCustomer; // Lưu customer hiện tại với avatar có thể thay đổi

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final customer = widget.customer;
    _currentCustomer = customer; // Khởi tạo customer hiện tại
    _nameController.text = customer.name;
    _phoneController.text = customer.phone;
    _addressController.text = customer.address;
    _serviceController.text = customer.serviceCompleted;
    _amountController.text = customer.amountSpent.toString();
    _notesController.text = customer.notes ?? '';

    // Chuyển đổi reminders hiện tại thành ReminderInput
    _reminders = customer.reminders
        .map((reminder) => ReminderInput(
              date: reminder.reminderDate,
              description: reminder.description,
              detailedDescription: reminder.detailedDescription,
              imageUrl: reminder.imageUrl,
              isCompleted: reminder.isCompleted,
            ))
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

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final validReminders = _reminders.where((r) => r.isValid).toList();
      final reminderObjects = validReminders.map((r) => r.toReminder()).toList();

      final updatedCustomer = Customer(
        id: widget.customer.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        serviceCompleted: _serviceController.text.trim(),
        amountSpent: double.tryParse(_amountController.text) ?? 0.0,
        reminders: reminderObjects,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        avatarUrl: _currentCustomer.avatarUrl, // Sử dụng avatarUrl hiện tại (có thể đã thay đổi)
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
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
          CustomerAvatar(
            avatarUrl: _currentCustomer.avatarUrl,
            customerName: _currentCustomer.name,
            radius: 35,
            onTap: () => _showEditAvatarOptions(context),
          ),
          const SizedBox(width: 16),
          // Thông tin và nút chỉnh sửa
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ảnh đại diện khách hàng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentCustomer.avatarUrl != null && _currentCustomer.avatarUrl!.isNotEmpty
                      ? 'Đã có ảnh đại diện'
                      : 'Chưa có ảnh đại diện',
                  style: TextStyle(
                    fontSize: 14,
                    color: _currentCustomer.avatarUrl != null && _currentCustomer.avatarUrl!.isNotEmpty
                        ? Colors.green
                        : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _showEditAvatarOptions(context),
                  icon: Icon(
                    _currentCustomer.avatarUrl != null && _currentCustomer.avatarUrl!.isNotEmpty
                        ? Icons.edit
                        : Icons.add_a_photo,
                    size: 18,
                  ),
                  label: Text(
                    _currentCustomer.avatarUrl != null && _currentCustomer.avatarUrl!.isNotEmpty
                        ? 'Thay đổi'
                        : 'Thêm ảnh',
                    style: const TextStyle(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (reminder.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
            ],
            InkWell(
              onTap: reminder.isCompleted ? null : () => _selectDate(context, reminder),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: reminder.isCompleted ? Colors.grey.shade100 : Colors.white,
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
                          decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: reminder.isCompleted ? null : () => _showImageOptions(context, index),
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
                        ? Icon(
                            Icons.add_a_photo,
                            color: reminder.isCompleted ? Colors.grey : Colors.grey.shade600,
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
                
                if (_currentCustomer.avatarUrl != null && _currentCustomer.avatarUrl!.isNotEmpty) ...[
                  ListTile(
                    leading: const Icon(Icons.visibility, color: Colors.blue),
                    title: const Text('Xem ảnh đại diện'),
                    onTap: () {
                      Navigator.pop(context);
                      _showAvatarViewer(_currentCustomer.avatarUrl!);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit, color: Colors.orange),
                    title: const Text('Thay đổi ảnh đại diện'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndUploadAvatar();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Xóa ảnh đại diện'),
                    onTap: () {
                      Navigator.pop(context);
                      _deleteAvatar();
                    },
                  ),
                ] else ...[
                  ListTile(
                    leading: const Icon(Icons.add_a_photo, color: Colors.green),
                    title: const Text('Thêm ảnh đại diện'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndUploadAvatar();
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

  // Hiển thị ảnh avatar fullscreen
  void _showAvatarViewer(String avatarUrl) {
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

  // Chọn và upload avatar
  Future<void> _pickAndUploadAvatar() async {
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
              Text('Đang upload ảnh đại diện...'),
            ],
          ),
        ),
      );

      // Đọc file thành bytes
      final imageBytes = await imageFile.readAsBytes();

      // Sử dụng updateCustomerAvatar để xóa ảnh cũ và upload ảnh mới
      final avatarUrl = await _imageService.updateCustomerAvatar(
        oldAvatarUrl: _currentCustomer.avatarUrl, // Xóa ảnh cũ nếu có
        newImageBytes: imageBytes,
        customerId: _currentCustomer.id!,
        originalFileName: imageFile.path.split('/').last,
      );

      // Đóng dialog loading
      if (mounted) Navigator.pop(context);

      if (avatarUrl != null) {
        // Thêm timestamp để force cache invalidation
        final timestampedUrl = '$avatarUrl?t=${DateTime.now().millisecondsSinceEpoch}';
        
        // Cập nhật customer với URL avatar mới
        setState(() {
          _currentCustomer = _currentCustomer.copyWith(avatarUrl: timestampedUrl);
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

  // Xóa avatar
  Future<void> _deleteAvatar() async {
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
        if (_currentCustomer.avatarUrl != null && _currentCustomer.avatarUrl!.isNotEmpty) {
          await _imageService.deleteCustomerAvatar(_currentCustomer.avatarUrl!);
        }

        // Cập nhật customer với avatarUrl = null
        setState(() {
          _currentCustomer = _currentCustomer.copyWith(clearAvatarUrl: true);
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

  // Hiển thị options cho ảnh reminder
  Future<void> _showImageOptions(BuildContext context, int reminderIndex) async {
    final reminder = _reminders[reminderIndex];
    
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
                      _pickAndUploadReminderImage(reminderIndex);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Xóa ảnh'),
                    onTap: () {
                      Navigator.pop(context);
                      _deleteReminderImage(reminderIndex);
                    },
                  ),
                ] else ...[
                  ListTile(
                    leading: const Icon(Icons.add_a_photo, color: Colors.green),
                    title: const Text('Thêm ảnh'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndUploadReminderImage(reminderIndex);
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
  Future<void> _pickAndUploadReminderImage(int reminderIndex) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Hiển thị dialog chọn nguồn ảnh
      final imageFile = await _imageService.showImageSourceDialog(context);
      if (imageFile == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Đọc file thành bytes
      final imageBytes = await imageFile.readAsBytes();

      // Sử dụng updateReminderImage để xóa ảnh cũ và upload ảnh mới
      final imageUrl = await _imageService.updateReminderImage(
        oldImageUrl: _reminders[reminderIndex].imageUrl, // Xóa ảnh cũ nếu có
        newImageBytes: imageBytes,
        customerId: _currentCustomer.id!,
        reminderId: DateTime.now().millisecondsSinceEpoch.toString(),
        originalFileName: imageFile.path.split('/').last,
      );

      if (imageUrl != null) {
        // Cập nhật reminder với URL ảnh mới
        setState(() {
          _reminders[reminderIndex].imageUrl = imageUrl;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã cập nhật ảnh nhắc nhở'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể upload ảnh'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi upload ảnh: $e'),
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

  // Xóa ảnh reminder
  Future<void> _deleteReminderImage(int reminderIndex) async {
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

        final reminder = _reminders[reminderIndex];

        // Xóa ảnh từ Storage
        if (reminder.imageUrl != null && reminder.imageUrl!.isNotEmpty) {
          await _imageService.deleteReminderImage(reminder.imageUrl!);
        }

        // Cập nhật reminder với imageUrl = null
        setState(() {
          _reminders[reminderIndex].imageUrl = null;
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
}
