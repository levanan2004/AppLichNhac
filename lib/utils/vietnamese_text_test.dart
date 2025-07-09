// File test để kiểm tra hiển thị tiếng Việt
import 'package:flutter/material.dart';

class VietnameseTextTest extends StatelessWidget {
  const VietnameseTextTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Tiếng Việt'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kiểm tra hiển thị tiếng Việt:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Tên khách hàng: Nguyễn Văn A'),
            Text('Địa chỉ: 123 Đường Lê Lợi, Quận 1, TP.HCM'),
            Text('Dịch vụ: Chăm sóc da mặt'),
            Text('Ghi chú: Khách VIP - cần chăm sóc đặc biệt'),
            SizedBox(height: 16),
            Text(
              'Các ký tự đặc biệt:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text('à á ả ã ạ â ầ ấ ẩ ẫ ậ ă ằ ắ ẳ ẵ ặ'),
            Text('è é ẻ ẽ ẹ ê ề ế ể ễ ệ'),
            Text('ì í ỉ ĩ ị'),
            Text('ò ó ỏ õ ọ ô ồ ố ổ ỗ ộ ơ ờ ớ ở ỡ ợ'),
            Text('ù ú ủ ũ ụ ư ừ ứ ử ữ ự'),
            Text('ỳ ý ỷ ỹ ỵ'),
            Text('đ'),
            SizedBox(height: 16),
            Text(
              'Viết hoa:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text('À Á Ả Ã Ạ Â Ầ Ấ Ẩ Ẫ Ậ Ă Ằ Ắ Ẳ Ẵ Ặ'),
            Text('È É Ẻ Ẽ Ẹ Ê Ề Ế Ể Ễ Ệ'),
            Text('Ì Í Ỉ Ĩ Ị'),
            Text('Ò Ó Ỏ Õ Ọ Ô Ồ Ố Ổ Ỗ Ộ Ơ Ờ Ớ Ở Ỡ Ợ'),
            Text('Ù Ú Ủ Ũ Ụ Ư Ừ Ứ Ử Ữ Ự'),
            Text('Ỳ Ý Ỷ Ỹ Ỵ'),
            Text('Đ'),
          ],
        ),
      ),
    );
  }
}
