# Tính tương thích iOS/Android cho chức năng gọi điện và lưu lịch sử cuộc gọi

## Tổng quan
App đã được thiết kế để tương thích hoàn toàn với cả iOS và Android cho chức năng gọi điện và lưu lịch sử cuộc gọi.

## Sự khác biệt giữa iOS và Android

### Android
- **Quyền**: Cần quyền `CALL_PHONE` và `READ_PHONE_STATE` trong AndroidManifest.xml
- **URI gọi điện**: Sử dụng `tel:` scheme
- **Theo dõi trạng thái**: Có thể theo dõi trạng thái cuộc gọi tốt hơn (completed, missed, busy)
- **Lưu lịch sử**: Status mặc định là 'completed'
- **User Experience**: Mở ứng dụng gọi điện và thực hiện cuộc gọi trực tiếp

### iOS
- **Quyền**: Không cần request quyền riêng, chỉ cần khai báo `LSApplicationQueriesSchemes` trong Info.plist
- **URI gọi điện**: Sử dụng `telprompt:` scheme để hiển thị dialog xác nhận
- **Theo dõi trạng thái**: Không thể theo dõi trạng thái cuộc gọi thực tế do giới hạn của iOS
- **Lưu lịch sử**: Status mặc định là 'initiated' với ghi chú giải thích
- **User Experience**: Hiển thị dialog xác nhận trước khi gọi

## Cách xử lý tương thích

### 1. Platform Detection
```dart
import 'package:flutter/foundation.dart';

// Kiểm tra platform
if (defaultTargetPlatform == TargetPlatform.iOS) {
  // Logic cho iOS
} else if (defaultTargetPlatform == TargetPlatform.android) {
  // Logic cho Android
}
```

### 2. URI gọi điện phù hợp
```dart
// iOS: telprompt - hiển thị dialog xác nhận
Uri(scheme: 'telprompt', path: phoneNumber)

// Android: tel - gọi trực tiếp  
Uri(scheme: 'tel', path: phoneNumber)
```

### 3. Call Status và Logging

#### Android
- Status: 'completed' (có thể theo dõi được)
- Notes: Thông tin chi tiết hơn về cuộc gọi

#### iOS  
- Status: 'initiated' (không thể xác định trạng thái thực tế)
- Notes: Có ghi chú giải thích về giới hạn của iOS

### 4. Platform Metadata
Mỗi CallLog được lưu với metadata về platform:
```dart
class CallLog {
  final String? platform; // 'TargetPlatform.iOS' hoặc 'TargetPlatform.android'
  final String status; // 'completed', 'initiated', 'missed', 'busy'
  // ...
}
```

## Quyền cần thiết

### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.CALL_PHONE" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
```

### iOS (ios/Runner/Info.plist)
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>tel</string>
  <string>telprompt</string>
</array>
```

## Kiểm tra quyền runtime

### Android
```dart
final status = await Permission.phone.request();
return status == PermissionStatus.granted;
```

### iOS
```dart
// iOS không cần request quyền riêng
// Chỉ cần kiểm tra có thể launch URL tel:
final testUri = Uri(scheme: 'tel', path: '123');
return await canLaunchUrl(testUri);
```

## User Interface

### Hiển thị trạng thái cuộc gọi
- **completed** (Hoàn thành) - Màu xanh lá, icon `Icons.call`
- **initiated** (Đã khởi tạo) - Màu xanh dương, icon `Icons.call_made`  
- **missed** (Nhỡ cuộc gọi) - Màu đỏ, icon `Icons.call_missed`
- **busy** (Máy bận) - Màu cam, icon `Icons.call_end`

### Hiển thị platform
- **iOS** - Hiển thị "iOS"
- **Android** - Hiển thị "Android"

## Thông báo cho người dùng

### Android
"Đang thực hiện cuộc gọi. Lịch sử cuộc gọi đã được lưu."

### iOS  
"Đã mở ứng dụng gọi điện. Lịch sử cuộc gọi đã được lưu."

## Hạn chế và lưu ý

### iOS
1. **Không thể theo dõi trạng thái**: iOS không cho phép app theo dõi trạng thái cuộc gọi thực tế
2. **Dialog xác nhận**: Luôn hiển thị dialog xác nhận trước khi gọi
3. **Không tự động gọi**: Người dùng phải xác nhận trong dialog mới thực hiện cuộc gọi

### Android
1. **Quyền nhạy cảm**: Cần quyền CALL_PHONE (có thể bị từ chối)
2. **Phiên bản Android**: Một số tính năng có thể khác nhau giữa các phiên bản Android

## Testing

### Test trên iOS
1. Kiểm tra dialog xác nhận xuất hiện
2. Xác nhận lịch sử cuộc gọi được lưu với status 'initiated'
3. Kiểm tra platform metadata = 'TargetPlatform.iOS'

### Test trên Android  
1. Kiểm tra quyền được yêu cầu đúng cách
2. Xác nhận cuộc gọi được thực hiện
3. Kiểm tra lịch sử cuộc gọi được lưu với status 'completed'
4. Kiểm tra platform metadata = 'TargetPlatform.android'

## Kết luận

Chức năng gọi điện và lưu lịch sử cuộc gọi đã được thiết kế tương thích hoàn toàn với cả iOS và Android. Sự khác biệt chính là ở cách xử lý trạng thái cuộc gọi và user experience, nhưng cả hai platform đều có thể thực hiện gọi điện và lưu lịch sử một cách đáng tin cậy.
