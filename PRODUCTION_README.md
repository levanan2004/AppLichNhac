# VIP CSKH - Ứng Dụng Quản Lý Khách Hàng Mỹ Phẩm

## 🎯 Giới Thiệu
VIP CSKH là ứng dụng quản lý khách hàng chuyên nghiệp dành cho ngành mỹ phẩm, giúp doanh nghiệp quản lý hiệu quả thông tin khách hàng, lịch nhắc nhở và tăng cường tương tác với khách hàng.

## ✨ Tính Năng Chính

### 🔐 Hệ Thống Xác Thực
- **Đăng nhập phân quyền**: Admin và Nhân viên
- **Bảo mật mật khẩu**: Hash SHA-256 + Salt
- **Quản lý phiên đăng nhập**: Tự động đăng xuất khi hết hạn

### 👥 Quản Lý Khách Hàng
- **Thêm/Sửa/Xóa** thông tin khách hàng
- **Tìm kiếm và lọc** khách hàng theo nhiều tiêu chí
- **Theo dõi lịch sử** dịch vụ và chi tiêu
- **Quản lý ghi chú** cá nhân hóa cho từng khách hàng

### 📞 Tính Năng Gọi Điện Tích Hợp
- **Gọi điện trực tiếp** từ app (iOS & Android)
- **Lưu lịch sử cuộc gọi** tự động
- **Ghi chú cuộc gọi** cho từng lần tương tác
- **Thống kê cuộc gọi** theo khách hàng

### 🔔 Hệ Thống Nhắc Nhở Thông Minh
- **Tạo lịch nhắc nhở** tự động
- **Push Notification** đúng giờ
- **Background Processing** luôn hoạt động
- **Quản lý trạng thái** hoàn thành/chưa hoàn thành

### 📊 Dashboard & Báo Cáo
- **Thống kê tổng quan** số lượng khách hàng
- **Báo cáo doanh thu** theo thời gian
- **Phân tích cuộc gọi** và tương tác
- **Theo dõi hiệu suất** nhân viên

## 🛠 Công Nghệ Sử Dụng

### Frontend
- **Flutter 3.x**: Framework UI đa nền tảng
- **Material Design**: Giao diện đẹp, thân thiện
- **State Management**: Provider pattern

### Backend & Database
- **Firebase Firestore**: Database NoSQL real-time
- **Firebase Auth**: Xác thực và phân quyền
- **Firebase Messaging**: Push notification
- **Firebase Storage**: Lưu trữ file và hình ảnh

### Tích Hợp Nền Tảng
- **iOS**: Hỗ trợ đầy đủ tính năng trên iPhone/iPad
- **Android**: Tối ưu cho tất cả thiết bị Android
- **Cross-platform**: Code một lần, chạy mọi nơi

## 📱 Hỗ Trợ Nền Tảng

### iOS (iPhone/iPad)
- **Phiên bản tối thiểu**: iOS 12.0+
- **Tính năng đặc biệt**: 
  - Gọi điện với dialog xác nhận
  - Push notification native
  - Background app refresh

### Android
- **Phiên bản tối thiểu**: Android 6.0 (API 23)+
- **Quyền cần thiết**:
  - Gọi điện thoại
  - Thông báo
  - Truy cập mạng

## 🚀 Cài Đặt & Triển Khai

### Yêu Cầu Hệ Thống
- Flutter SDK 3.x
- Dart SDK 3.x
- Android Studio / Xcode
- Firebase project đã cấu hình

### Các Bước Cài Đặt
1. **Clone source code**
2. **Cấu hình Firebase**: Thêm config files cho iOS/Android
3. **Install dependencies**: `flutter pub get`
4. **Build project**: 
   - Android: `flutter build apk --release`
   - iOS: `flutter build ios --release`

### Cấu Hình Firebase
- Tạo project trên Firebase Console
- Bật Firestore Database
- Cấu hình Authentication
- Thêm Firebase Messaging
- Download và đặt config files:
  - `google-services.json` (Android)
  - `GoogleService-Info.plist` (iOS)

## 📋 Hướng Dẫn Sử Dụng

### Cho Admin
1. **Đăng nhập** với tài khoản admin
2. **Quản lý nhân viên** và phân quyền
3. **Xem báo cáo** tổng quan
4. **Cấu hình hệ thống** notification

### Cho Nhân Viên
1. **Đăng nhập** với tài khoản nhân viên
2. **Thêm khách hàng mới** với đầy đủ thông tin
3. **Tạo lịch nhắc nhở** cho khách hàng
4. **Gọi điện** và ghi chú cuộc gọi
5. **Cập nhật trạng thái** dịch vụ

## 🔒 Bảo Mật

### Xác Thực
- Mật khẩu được hash với SHA-256
- Session management an toàn
- Auto-logout khi không hoạt động

### Dữ Liệu
- Firestore security rules nghiêm ngặt
- Encryption cho dữ liệu nhạy cảm
- Backup tự động trên Cloud

### Quyền Truy Cập
- Phân quyền rõ ràng Admin/Nhân viên
- Chỉ truy cập dữ liệu được phép
- Audit log cho mọi thao tác quan trọng

## 📞 Hỗ Trợ Kỹ Thuật

### Liên Hệ
- **Email hỗ trợ**: [email hỗ trợ]
- **Hotline**: [số điện thoại]
- **Thời gian hỗ trợ**: 8h00 - 17h30 (T2-T6)

### Bảo Hành
- **Thời gian bảo hành**: 12 tháng
- **Bao gồm**: Bug fixes, cập nhật nhỏ
- **Không bao gồm**: Tính năng mới, thay đổi thiết kế

## 📈 Roadmap

### Version 2.0 (Sắp Tới)
- [ ] Tích hợp CRM nâng cao
- [ ] Báo cáo chi tiết hơn
- [ ] Đồng bộ đa thiết bị
- [ ] API cho hệ thống khác

### Version 2.1
- [ ] AI recommend sản phẩm
- [ ] Chat tích hợp
- [ ] Quản lý inventory
- [ ] Multi-language support

## 🏆 Ưu Điểm Cạnh Tranh

### So Với Giải Pháp Khác
- ✅ **Chuyên biệt**: Thiết kế riêng cho ngành mỹ phẩm
- ✅ **Đa nền tảng**: iOS, Android cùng một code base
- ✅ **Real-time**: Đồng bộ dữ liệu tức thời
- ✅ **Offline-first**: Hoạt động cả khi mất mạng
- ✅ **Scalable**: Mở rộng theo quy mô doanh nghiệp

### ROI (Return on Investment)
- 📈 **Tăng 40%** hiệu quả quản lý khách hàng
- 📞 **Tăng 60%** tỷ lệ liên lạc thành công
- ⏰ **Tiết kiệm 50%** thời gian quản lý
- 💰 **Tăng 25%** doanh thu từ khách hàng cũ

---

**© 2025 VIP CSKH. All rights reserved.**

*Phần mềm được phát triển bởi [Tên công ty] - Chuyên gia phát triển ứng dụng di động cho doanh nghiệp.*
