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
  List<ReminderInput> _reminders = []; // Bat dau voi danh sach rong

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

  void _addAutoReminders() {
    // Luon luon dung ngay hien tai lam moc
    final baseDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tao lich nhac tu dong'),
        content: const Text(
          'Tao lich nhac tu dong cho khach hang nay?\n\n'
          'Se tao 6 lich nhac:\n'
          '- 3 ngay sau\n'
          '- 7 ngay sau\n'
          '- 15 ngay sau\n'
          '- 1 thang sau\n'
          '- 3 thang sau\n'
          '- 6 thang sau',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generateAutoReminders(baseDate);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Tao', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _generateAutoReminders(DateTime baseDate) {
    setState(() {
      _reminders = [
        ReminderInput(
          description: 'Nhac nho sau 3 ngay - Goi hoi ve cam nhan',
          date: baseDate.add(const Duration(days: 3)),
        ),
        ReminderInput(
          description: 'Nhac nho sau 1 tuan - Hoi tham cam nhan',
          date: baseDate.add(const Duration(days: 7)),
        ),
        ReminderInput(
          description: 'Nhac nho sau 15 ngay - Tu van san pham moi',
          date: baseDate.add(const Duration(days: 15)),
        ),
        ReminderInput(
          description: 'Nhac nho sau 1 thang - Danh gia hieu qua tong the',
          date: DateTime(baseDate.year, baseDate.month + 1, baseDate.day),
        ),
        ReminderInput(
          description: 'Nhac nho sau 3 thang - Tai su dung dich vu',
          date: DateTime(baseDate.year, baseDate.month + 3, baseDate.day),
        ),
        ReminderInput(
          description: 'Nhac nho sau 6 thang - Cham soc dinh ky',
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

    // Loc ra nhung reminder hop le (co du thong tin)
    final validReminders = _reminders
        .where((r) => r.date != null && r.description.isNotEmpty)
        .toList();

    setState(() {
      _isLoading = true;
    });

    try {
      // Tao danh sach reminders tu input (co the rong)
      List<Reminder> reminders = validReminders
          .map(
            (r) => Reminder(reminderDate: r.date!, description: r.description),
          )
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
            ? 'Da them khach hang ${customer.name} voi $reminderCount lich nhac'
            : 'Da them khach hang ${customer.name}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loi khi them khach hang: $e'),
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
          'Them khach hang',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              // Thong tin co ban
              _buildSectionTitle('Thong tin co ban'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nameController,
                label: 'Ten khach hang',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui long nhap ten khach hang';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'So dien thoai',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui long nhap so dien thoai';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                label: 'Dia chi',
                icon: Icons.location_on,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui long nhap dia chi';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Thong tin dich vu
              _buildSectionTitle('Thong tin dich vu'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _serviceController,
                label: 'Dich vu da thuc hien',
                icon: Icons.spa,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui long nhap dich vu da thuc hien';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _amountController,
                label: 'So tien da chi tieu (VND)',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui long nhap so tien';
                  }
                  if (double.tryParse(value) == null) {
                    return 'So tien khong hop le';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Lich nhac
              Row(
                children: [
                  _buildSectionTitle('Lich nhac'),
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
                      '${_reminders.where((r) => r.isValid).length} nhac nho',
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
              // Buttons de quan ly reminders
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addAutoReminders,
                      icon: const Icon(Icons.auto_awesome, color: Colors.green),
                      label: const Text(
                        'Tao tu dong',
                        style: TextStyle(color: Colors.green, fontSize: 12),
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
                        'Xoa tat ca',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
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
              if (_reminders.isNotEmpty || _reminders.isEmpty)
                _buildAddReminderButton(),

              const SizedBox(height: 24),

              // Ghi chu
              _buildSectionTitle('Ghi chu'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _notesController,
                label: 'Ghi chu (tuy chon)',
                icon: Icons.note,
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // Nut luu
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Luu khach hang',
                          style: TextStyle(
                            fontSize: 16,
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
            color: reminder.isValid
                ? Colors.green.shade300
                : Colors.grey.shade300,
            width: reminder.isValid ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Lich nhac ${index + 1}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                const Spacer(),
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
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Mo ta lich nhac',
                prefixIcon: Icon(Icons.description, color: Colors.green),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (value) {
                setState(() {
                  reminder.description = value;
                });
              },
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
                          : 'Chon ngay nhac',
                      style: TextStyle(
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
      label: const Text(
        'Them lich nhac',
        style: TextStyle(color: Colors.green, fontSize: 14),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.green),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

class ReminderInput {
  String description;
  DateTime? date;

  ReminderInput({this.description = '', this.date});

  bool get isValid => description.isNotEmpty && date != null;
}
