import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  final List<ReminderInput> _reminders = [ReminderInput()];

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
      _reminders.add(ReminderInput());
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
      // Tạo danh sách reminders từ input
      List<Reminder> reminders = _reminders
          .where((r) => r.date != null && r.description.isNotEmpty)
          .map((r) => r.toReminder())
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ÄÃ£ thÃªm khÃ¡ch hÃ ng ${customer.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lá»—i khi thÃªm khÃ¡ch hÃ ng: $e'),
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
        title: Text(
          'ThÃªm khÃ¡ch hÃ ng',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ThÃ´ng tin cÆ¡ báº£n
              _buildSectionTitle('ThÃ´ng tin cÆ¡ báº£n'),
              SizedBox(height: 8.h),
              _buildTextField(
                controller: _nameController,
                label: 'TÃªn khÃ¡ch hÃ ng',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lÃ²ng nháº­p tÃªn khÃ¡ch hÃ ng';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                controller: _phoneController,
                label: 'Sá»‘ Ä‘iá»‡n thoáº¡i',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lÃ²ng nháº­p sá»‘ Ä‘iá»‡n thoáº¡i';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                controller: _addressController,
                label: 'Äá»‹a chá»‰',
                icon: Icons.location_on,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lÃ²ng nháº­p Ä‘á»‹a chá»‰';
                  }
                  return null;
                },
              ),

              SizedBox(height: 24.h),

              // ThÃ´ng tin dá»‹ch vá»¥
              _buildSectionTitle('ThÃ´ng tin dá»‹ch vá»¥'),
              SizedBox(height: 8.h),
              _buildTextField(
                controller: _serviceController,
                label: 'Dá»‹ch vá»¥ Ä‘Ã£ thá»±c hiá»‡n',
                icon: Icons.spa,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lÃ²ng nháº­p dá»‹ch vá»¥ Ä‘Ã£ thá»±c hiá»‡n';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                controller: _amountController,
                label: 'Sá»‘ tiá»n Ä‘Ã£ chi tiÃªu (VNÄ)',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lÃ²ng nháº­p sá»‘ tiá»n';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Sá»‘ tiá»n khÃ´ng há»£p lá»‡';
                  }
                  return null;
                },
              ),

              SizedBox(height: 24.h),

              // Lá»‹ch nháº¯c
              _buildSectionTitle('Lá»‹ch nháº¯c'),
              SizedBox(height: 8.h),
              ..._buildReminderInputs(),
              SizedBox(height: 8.h),
              _buildAddReminderButton(),

              SizedBox(height: 24.h),

              // Ghi chÃº
              _buildSectionTitle('Ghi chÃº'),
              SizedBox(height: 8.h),
              _buildTextField(
                controller: _notesController,
                label: 'Ghi chÃº (tÃ¹y chá»n)',
                icon: Icons.note,
                maxLines: 3,
              ),

              SizedBox(height: 32.h),

              // NÃºt lÆ°u
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'LÆ°u khÃ¡ch hÃ ng',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18.sp,
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
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.green),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
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
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.green, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'Lá»‹ch nháº¯c ${index + 1}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                const Spacer(),
                if (_reminders.length > 1)
                  IconButton(
                    onPressed: () => _removeReminder(index),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'MÃ´ táº£ lá»‹ch nháº¯c',
                prefixIcon: const Icon(Icons.description, color: Colors.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              onChanged: (value) => reminder.description = value,
              validator: (value) {
                if (reminder.date != null && (value == null || value.isEmpty)) {
                  return 'Vui lÃ²ng nháº­p mÃ´ táº£ cho lá»‹ch nháº¯c';
                }
                return null;
              },
            ),
            SizedBox(height: 12.h),
            // Trường mô tả chi tiết
            TextFormField(
              initialValue: reminder.detailedDescription ?? '',
              onChanged: (value) {
                reminder.detailedDescription = value.isNotEmpty ? value : null;
              },
              decoration: InputDecoration(
                labelText: 'Mô tả chi tiết',
                hintText: 'Nhập mô tả chi tiết cho lịch nhắc này...',
                prefixIcon: const Icon(Icons.notes, color: Colors.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 12.h),
            InkWell(
              onTap: () => _selectDate(context, reminder),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.green),
                    SizedBox(width: 12.w),
                    Text(
                      reminder.date != null
                          ? DateFormat('dd/MM/yyyy').format(reminder.date!)
                          : 'Chá»n ngÃ y nháº¯c',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: reminder.date != null
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
      );
    }).toList();
  }

  Widget _buildAddReminderButton() {
    return OutlinedButton.icon(
      onPressed: _addReminder,
      icon: const Icon(Icons.add, color: Colors.green),
      label: Text(
        'ThÃªm lá»‹ch nháº¯c',
        style: TextStyle(color: Colors.green, fontSize: 14.sp),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.green),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, ReminderInput reminder) async {
    final DateTime? picked = await showDatePicker(
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
