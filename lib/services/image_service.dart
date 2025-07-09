import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Chọn ảnh từ gallery hoặc camera - hỗ trợ tất cả định dạng ảnh
  Future<File?> pickImage({bool fromCamera = false}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        // Không giới hạn kích thước ở đây để hỗ trợ ảnh chất lượng cao
        // maxWidth và maxHeight sẽ được xử lý trong quá trình nén
        imageQuality: 100, // Giữ chất lượng gốc, sẽ nén sau
      );
      
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        // Kiểm tra file có tồn tại không
        if (await file.exists()) {
          // Kiểm tra kích thước file (cho phép tối đa 500MB)
          final fileSize = await file.length();
          print('📁 File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
          
          if (fileSize > 500 * 1024 * 1024) { // 500MB
            print('❌ File quá lớn (>500MB): ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
            return null;
          }
          
          return file;
        } else {
          print('❌ File không tồn tại: ${pickedFile.path}');
          return null;
        }
      }
      return null;
    } catch (e) {
      print('❌ Error picking image: $e');
      // Thông báo lỗi chi tiết hơn
      if (e.toString().contains('camera_access_denied')) {
        print('❌ Quyền truy cập camera bị từ chối');
      } else if (e.toString().contains('photo_access_denied')) {
        print('❌ Quyền truy cập thư viện ảnh bị từ chối');
      }
      return null;
    }
  }

  /// Hiển thị bottom sheet để chọn nguồn ảnh
  Future<File?> showImageSourceDialog(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
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
                  'Chọn hình ảnh',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageSourceOption(
                      context: context,
                      icon: Icons.photo_library,
                      label: 'Thư viện',
                      onTap: () => Navigator.pop(context, 'gallery'),
                    ),
                    _buildImageSourceOption(
                      context: context,
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () => Navigator.pop(context, 'camera'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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

    if (result == null) return null;

    if (result == 'gallery') {
      return await pickImage(fromCamera: false);
    } else if (result == 'camera') {
      return await pickImage(fromCamera: true);
    }

    return null;
  }

  Widget _buildImageSourceOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
              ),
            ),
            child: Icon(
              icon,
              size: 40,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Compress và upload hình ảnh reminder lên Firebase Storage
  Future<String?> uploadReminderImage({
    required Uint8List imageBytes,
    required String customerId,
    required String reminderId,
    String? originalFileName,
  }) async {
    try {
      // Nén hình ảnh thông minh
      final compressedImageBytes = await _compressImageSmart(imageBytes);
      
      if (compressedImageBytes == null) {
        print('❌ Failed to compress image');
        return null;
      }

      // Tạo đường dẫn file trong Storage
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'reminders/$customerId/$reminderId/$fileName';
      
      // Upload lên Firebase Storage
      final ref = _storage.ref().child(filePath);
      final uploadTask = ref.putData(
        compressedImageBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'originalFileName': originalFileName ?? 'reminder_image',
            'customerId': customerId,
            'reminderId': reminderId,
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ Image uploaded successfully: $downloadUrl');
      return downloadUrl;
      
    } catch (e) {
      print('❌ Error uploading image: $e');
      return null;
    }
  }

  /// Nén hình ảnh thông minh - hỗ trợ tất cả định dạng, nén xuống ~10MB
  Future<Uint8List?> _compressImageSmart(Uint8List imageBytes) async {
    try {
      print('📊 Original image size: ${(imageBytes.length / 1024 / 1024).toStringAsFixed(2)} MB');
      
      // Decode hình ảnh gốc - hỗ trợ tất cả định dạng (JPEG, PNG, WEBP, GIF, BMP, TIFF, etc.)
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        print('❌ Không thể decode image - định dạng không được hỗ trợ');
        return null;
      }
      
      print('🖼️ Original image: ${originalImage.width}x${originalImage.height}');
      
      // Bước 1: Resize ảnh nếu quá lớn
      img.Image processedImage = originalImage;
      
      // Tính toán kích thước mới dựa trên kích thước gốc
      int targetWidth = originalImage.width;
      int targetHeight = originalImage.height;
      
      // Nếu ảnh quá lớn, resize xuống kích thước phù hợp
      final maxDimension = 2048; // Max 2048px cho cạnh dài nhất
      if (originalImage.width > maxDimension || originalImage.height > maxDimension) {
        if (originalImage.width > originalImage.height) {
          targetWidth = maxDimension;
          targetHeight = (originalImage.height * maxDimension / originalImage.width).round();
        } else {
          targetHeight = maxDimension;
          targetWidth = (originalImage.width * maxDimension / originalImage.height).round();
        }
        
        processedImage = img.copyResize(
          originalImage,
          width: targetWidth,
          height: targetHeight,
          interpolation: img.Interpolation.cubic, // Chất lượng resize tốt nhất
        );
        
        print('📐 Resized to: ${targetWidth}x${targetHeight}');
      }
      
      // Bước 2: Thử nhiều mức chất lượng JPEG để đạt kích thước mục tiêu (~10MB)
      const targetSizeMB = 10;
      const targetSizeBytes = targetSizeMB * 1024 * 1024;
      
      List<int> qualityLevels = [95, 90, 85, 80, 75, 70, 65, 60, 55, 50, 45, 40, 35, 30];
      
      for (int quality in qualityLevels) {
        final jpegBytes = img.encodeJpg(processedImage, quality: quality);
        
        print('� Quality $quality%: ${(jpegBytes.length / 1024 / 1024).toStringAsFixed(2)} MB');
        
        // Nếu kích thước đạt yêu cầu hoặc đã thử quality thấp nhất
        if (jpegBytes.length <= targetSizeBytes || quality == qualityLevels.last) {
          print('✅ Final compressed: ${(jpegBytes.length / 1024 / 1024).toStringAsFixed(2)} MB (Quality: $quality%)');
          return Uint8List.fromList(jpegBytes);
        }
      }
      
      // Fallback: nếu vẫn quá lớn, resize thêm một lần nữa
      print('⚠️ Still too large, applying additional resize...');
      final smallerImage = img.copyResize(
        processedImage,
        width: (targetWidth * 0.8).round(),
        height: (targetHeight * 0.8).round(),
        interpolation: img.Interpolation.cubic,
      );
      
      final finalBytes = img.encodeJpg(smallerImage, quality: 70);
      print('✅ Final fallback compressed: ${(finalBytes.length / 1024 / 1024).toStringAsFixed(2)} MB');
      
      return Uint8List.fromList(finalBytes);
      
    } catch (e) {
      print('❌ Error compressing image: $e');
      return null;
    }
  }

  /// Xóa hình ảnh reminder từ Firebase Storage
  Future<bool> deleteReminderImage(String imageUrl) async {
    try {
      // Remove timestamp parameter nếu có
      final cleanUrl = _removeTimestampFromUrl(imageUrl);
      
      // Lấy reference từ URL
      final ref = _storage.refFromURL(cleanUrl);
      await ref.delete();
      
      print('✅ Image deleted successfully: $cleanUrl');
      return true;
      
    } catch (e) {
      print('❌ Error deleting image: $e');
      return false;
    }
  }

  /// Cập nhật hình ảnh reminder (xóa cũ và upload mới)
  Future<String?> updateReminderImage({
    required String? oldImageUrl,
    required Uint8List newImageBytes,
    required String customerId,
    required String reminderId,
    String? originalFileName,
  }) async {
    try {
      print('🔄 Updating reminder image...');
      print('  - Customer ID: $customerId');
      print('  - Reminder ID: $reminderId');
      print('  - Old image URL: $oldImageUrl');
      
      // Xóa hình ảnh cũ nếu có
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        print('🗑️ Deleting old reminder image...');
        final deleted = await deleteReminderImage(oldImageUrl);
        if (deleted) {
          print('✅ Old reminder image deleted successfully');
        } else {
          print('⚠️ Failed to delete old reminder image, but continuing with upload');
        }
      } else {
        print('ℹ️ No old reminder image to delete');
      }

      // Upload hình ảnh mới
      print('📤 Uploading new reminder image...');
      final newUrl = await uploadReminderImage(
        imageBytes: newImageBytes,
        customerId: customerId,
        reminderId: reminderId,
        originalFileName: originalFileName,
      );
      
      if (newUrl != null) {
        print('✅ New reminder image uploaded successfully: $newUrl');
      } else {
        print('❌ Failed to upload new reminder image');
      }
      
      return newUrl;
      
    } catch (e) {
      print('❌ Error updating reminder image: $e');
      return null;
    }
  }

  /// Lấy kích thước file từ URL (để hiển thị thông tin)
  Future<int?> getImageSize(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      final metadata = await ref.getMetadata();
      return metadata.size;
    } catch (e) {
      print('❌ Error getting image size: $e');
      return null;
    }
  }

  /// Upload ảnh avatar cho khách hàng
  Future<String?> uploadCustomerAvatar({
    required Uint8List imageBytes,
    required String customerId,
    String? originalFileName,
  }) async {
    try {
      // Nén hình ảnh thông minh
      final compressedImageBytes = await _compressImageSmart(imageBytes);
      
      if (compressedImageBytes == null) {
        print('❌ Failed to compress avatar image');
        return null;
      }

      // Tạo đường dẫn file trong Storage
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'customers/$customerId/avatar/$fileName';
      
      // Upload lên Firebase Storage
      final ref = _storage.ref().child(filePath);
      final uploadTask = ref.putData(
        compressedImageBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'originalFileName': originalFileName ?? 'customer_avatar',
            'customerId': customerId,
            'type': 'avatar',
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ Avatar uploaded successfully: $downloadUrl');
      return downloadUrl;
      
    } catch (e) {
      print('❌ Error uploading avatar: $e');
      return null;
    }
  }

  /// Xóa ảnh avatar khách hàng từ Firebase Storage
  Future<bool> deleteCustomerAvatar(String avatarUrl) async {
    try {
      // Remove timestamp parameter nếu có
      final cleanUrl = _removeTimestampFromUrl(avatarUrl);
      
      // Lấy reference từ URL
      final ref = _storage.refFromURL(cleanUrl);
      await ref.delete();
      
      print('✅ Avatar deleted successfully: $cleanUrl');
      return true;
      
    } catch (e) {
      print('❌ Error deleting avatar: $e');
      return false;
    }
  }

  /// Remove timestamp parameter từ URL
  String _removeTimestampFromUrl(String url) {
    // Remove cả timestamp và các query parameters khác
    if (url.contains('?t=')) {
      return url.split('?t=')[0];
    }
    // Remove các query parameters khác nếu có
    if (url.contains('?')) {
      final parts = url.split('?');
      final baseUrl = parts[0];
      final queryParams = parts[1];
      
      // Giữ lại các params quan trọng, bỏ timestamp
      final params = queryParams.split('&').where((param) => !param.startsWith('t='));
      
      if (params.isNotEmpty) {
        return '$baseUrl?${params.join('&')}';
      } else {
        return baseUrl;
      }
    }
    return url;
  }

  /// Cập nhật ảnh avatar (xóa cũ và upload mới)
  Future<String?> updateCustomerAvatar({
    required String? oldAvatarUrl,
    required Uint8List newImageBytes,
    required String customerId,
    String? originalFileName,
  }) async {
    try {
      print('🔄 Updating customer avatar...');
      print('  - Customer ID: $customerId');
      print('  - Old avatar URL: $oldAvatarUrl');
      
      // Xóa ảnh avatar cũ nếu có
      if (oldAvatarUrl != null && oldAvatarUrl.isNotEmpty) {
        print('🗑️ Deleting old avatar...');
        final deleted = await deleteCustomerAvatar(oldAvatarUrl);
        if (deleted) {
          print('✅ Old avatar deleted successfully');
        } else {
          print('⚠️ Failed to delete old avatar, but continuing with upload');
        }
      } else {
        print('ℹ️ No old avatar to delete');
      }

      // Upload ảnh avatar mới
      print('📤 Uploading new avatar...');
      final newUrl = await uploadCustomerAvatar(
        imageBytes: newImageBytes,
        customerId: customerId,
        originalFileName: originalFileName,
      );
      
      if (newUrl != null) {
        print('✅ New avatar uploaded successfully: $newUrl');
      } else {
        print('❌ Failed to upload new avatar');
      }
      
      return newUrl;
      
    } catch (e) {
      print('❌ Error updating avatar: $e');
      return null;
    }
  }
}
