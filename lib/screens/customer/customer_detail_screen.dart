import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../models/customer.dart';
import '../../models/reminder.dart';
import '../../services/customer_service.dart';
import '../../services/whatsapp_service.dart';
import '../../services/image_service.dart';
import '../../widgets/customer_avatar.dart';
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
  final ImageService _imageService = ImageService(); // Thêm image service
  final ImagePicker _imagePicker = ImagePicker(); // Thêm image picker
  bool _isLoading = false; // ignore: unused_field

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
  }

  Future<void> _openWhatsApp() async {
    try {
      debugPrint(
        '🔄 Starting WhatsApp Business ONLY process for: ${_customer.phone}',
      );

      // Hiển thị loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đang thử mở WhatsApp Business...'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.blue,
          ),
        );
      }

      // CHỈ MỞ WhatsApp Business - không fallback, thử nhiều scheme
      final result = await _whatsappService.openWhatsAppBusinessOnly(
        _customer.phone,
      );

      debugPrint(
        '🎯 WhatsApp Business ONLY result: success=${result.isSuccess}, error=${result.error}',
      );

      if (!result.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ ${result.error ?? 'Không thể mở WhatsApp Business'}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      } else if (result.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã mở WhatsApp Business thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Exception in _openWhatsApp: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi khi mở WhatsApp Business: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
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

  /// Hiển thị options cho hình ảnh (thêm/xem/xóa)
  Future<void> _showImageOptions(BuildContext context, int reminderIndex) async {
    final reminder = _customer.reminders[reminderIndex];
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            if (reminder.imageUrl == null || reminder.imageUrl!.isEmpty) ...[
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text('Chụp ảnh'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(reminderIndex, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(reminderIndex, ImageSource.gallery);
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.visibility, color: Colors.blue),
                title: const Text('Xem ảnh'),
                onTap: () {
                  Navigator.pop(context);
                  _viewImage(reminder.imageUrl!);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.orange),
                title: const Text('Thay đổi ảnh'),
                onTap: () {
                  Navigator.pop(context);
                  _showChangeImageOptions(reminderIndex);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Xóa ảnh'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteImage(reminderIndex);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Hiển thị options thay đổi ảnh
  Future<void> _showChangeImageOptions(int reminderIndex) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Chụp ảnh mới'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(reminderIndex, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(reminderIndex, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Chọn và upload hình ảnh
  Future<void> _pickImage(int reminderIndex, ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Hiển thị loading
      setState(() {
        _isLoading = true;
      });

      // Đọc bytes từ file
      final imageBytes = await pickedFile.readAsBytes();

      // Upload ảnh lên Firebase Storage
      final imageUrl = await _imageService.uploadReminderImage(
        imageBytes: imageBytes,
        customerId: _customer.id!,
        reminderId: _customer.reminders[reminderIndex].id ?? 
                   DateTime.now().millisecondsSinceEpoch.toString(),
        originalFileName: pickedFile.name,
      );

      if (imageUrl != null) {
        // Cập nhật reminder với URL ảnh mới
        await _updateReminderImage(reminderIndex, imageUrl);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã thêm ảnh thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể upload ảnh. Vui lòng thử lại.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xử lý ảnh: $e'),
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

  /// Cập nhật URL ảnh cho reminder
  Future<void> _updateReminderImage(int reminderIndex, String imageUrl) async {
    try {
      final updatedReminders = List<Reminder>.from(_customer.reminders);
      final reminder = updatedReminders[reminderIndex];

      updatedReminders[reminderIndex] = reminder.copyWith(imageUrl: imageUrl);

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
    } catch (e) {
      print('Error updating reminder image: $e');
    }
  }

  /// Xem ảnh full screen
  Future<void> _viewImage(String imageUrl) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.error,
                        color: Colors.white,
                        size: 50,
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Xóa ảnh
  Future<void> _deleteImage(int reminderIndex) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ảnh'),
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

        final reminder = _customer.reminders[reminderIndex];
        
        // Xóa ảnh từ Storage
        if (reminder.imageUrl != null && reminder.imageUrl!.isNotEmpty) {
          await _imageService.deleteReminderImage(reminder.imageUrl!);
        }

        // Cập nhật reminder để bỏ URL ảnh
        await _updateReminderImage(reminderIndex, '');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa ảnh thành công!'),
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

  // Phương thức xử lý avatar khách hàng
  Future<void> _showAvatarOptions(BuildContext context) async {
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
                      _showAvatarViewer(context, _customer.avatarUrl!);
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
                      _deleteCustomerAvatar();
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

  // Chọn và upload ảnh avatar
  Future<void> _pickAndUploadAvatar() async {
    try {
      // Hiển thị dialog chọn nguồn ảnh
      final imageFile = await _imageService.showImageSourceDialog(context);
      if (imageFile == null) return;

      // Hiển thị loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Đọc file thành bytes và upload
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final avatarUrl = await _imageService.uploadCustomerAvatar(
        imageBytes: imageBytes,
        customerId: _customer.id!,
        originalFileName: 'customer_avatar.jpg',
      );

      // Đóng loading dialog
      if (mounted) Navigator.pop(context);

      if (avatarUrl != null) {
        // Cập nhật customer với avatar URL mới
        final updatedCustomer = _customer.copyWith(avatarUrl: avatarUrl);
        await _customerService.updateCustomer(updatedCustomer);
        
        setState(() {
          _customer = updatedCustomer;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Cập nhật ảnh đại diện thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Có lỗi khi tải ảnh lên!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Đóng loading dialog nếu có lỗi
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Xóa ảnh avatar
  Future<void> _deleteCustomerAvatar() async {
    if (_customer.avatarUrl == null || _customer.avatarUrl!.isEmpty) return;

    try {
      // Hiển thị dialog xác nhận
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc muốn xóa ảnh đại diện này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Hiển thị loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Xóa ảnh từ Storage
      await _imageService.deleteCustomerAvatar(_customer.avatarUrl!);

      // Cập nhật customer với avatar URL = null
      final updatedCustomer = _customer.copyWith(avatarUrl: null);
      await _customerService.updateCustomer(updatedCustomer);

      // Đóng loading dialog
      if (mounted) Navigator.pop(context);

      // Cập nhật UI
      setState(() {
        _customer = updatedCustomer;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Xóa ảnh đại diện thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Đóng loading dialog nếu có lỗi
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi khi xóa ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Hiển thị ảnh avatar fullscreen
  void _showAvatarViewer(BuildContext context, String avatarUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
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
              Expanded(
                child: Center(
                  child: InteractiveViewer(
                    child: Image.network(
                      avatarUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, color: Colors.white, size: 48),
                              SizedBox(height: 16),
                              Text(
                                'Không thể tải ảnh',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      },
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
            tooltip: 'Mở WhatsApp Business',
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
            const SizedBox(height: 100),
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
                Expanded(
                  child: Text(
                    'Thông tin khách hàng',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                // Avatar khách hàng
                GestureDetector(
                  onTap: () => _showAvatarOptions(context),
                  child: CustomerAvatar(
                    avatarUrl: _customer.avatarUrl,
                    customerName: _customer.name,
                    radius: 30,
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
                // Hiển thị mô tả chi tiết nếu có
                if (reminder.detailedDescription != null && reminder.detailedDescription!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reminder.detailedDescription!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
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
          // Thêm widget cho hình ảnh reminder
          GestureDetector(
            onTap: () => _showImageOptions(context, index),
            child: Container(
              margin: const EdgeInsets.only(left: 8),
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
                        color: Colors.grey.shade600,
                        size: 20,
                      )
                    : null,
              ),
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
                  'Ghi chú',
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
  final _detailedDescriptionController = TextEditingController(); // Thêm controller cho mô tả chi tiết
  final ImagePicker _imagePicker = ImagePicker(); // Thêm image picker
  DateTime? _selectedDate;
  XFile? _selectedImage; // Thêm biến để lưu ảnh đã chọn

  @override
  void dispose() {
    _descriptionController.dispose();
    _detailedDescriptionController.dispose(); // Dispose controller mới
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

  /// Chọn ảnh cho reminder
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Chụp ảnh'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _imagePicker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 800,
                  maxHeight: 800,
                  imageQuality: 85,
                );
                if (image != null) {
                  setState(() {
                    _selectedImage = image;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Chọn từ thư viện'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _imagePicker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 800,
                  maxHeight: 800,
                  imageQuality: 85,
                );
                if (image != null) {
                  setState(() {
                    _selectedImage = image;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
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
              labelText: 'Tiêu đề',
              hintText: 'Nhập tiêu đề cho lịch nhắc...',
              border: OutlineInputBorder(),
            ),
            maxLines: 1,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _detailedDescriptionController,
            decoration: const InputDecoration(
              labelText: 'Mô tả chi tiết',
              hintText: 'Nhập mô tả chi tiết cho lịch nhắc...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          // Phần chọn ảnh
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: const Icon(Icons.image, color: Colors.green),
              title: Text(_selectedImage != null ? 'Đã chọn ảnh' : 'Chọn ảnh (tuỳ chọn)'),
              subtitle: _selectedImage != null ? Text(_selectedImage!.name) : null,
              trailing: _selectedImage != null 
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _pickImage,
            ),
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
                detailedDescription: _detailedDescriptionController.text.trim().isNotEmpty 
                    ? _detailedDescriptionController.text.trim() 
                    : null, // Thêm mô tả chi tiết
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
