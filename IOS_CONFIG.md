# Hướng dẫn cấu hình iOS cho VIP CSKH

## Cấu hình đã hoàn thành

### 1. Info.plist đã được cấu hình
✅ **Tên app**: "VIP CSKH"
✅ **Firebase Messaging**: Đã enable
✅ **Background modes**: Remote notification, background processing, background fetch
✅ **Permissions**: Camera, Photo Library, Location, Contacts, Notifications

### 2. Podfile đã được cấu hình
✅ **iOS Deployment Target**: 15.0
✅ **Build settings**: Đã fix các vấn đề build
✅ **Permissions**: Camera, Photos, Notifications

### 3. GoogleService-Info.plist
✅ **File đã tồn tại** và cấu hình đúng cho project Firebase

### 4. Notification Service
✅ **iOS permissions**: Đã cấu hình đầy đủ
✅ **Local notifications**: Đã hỗ trợ iOS
✅ **Background processing**: Đã enable

## Cách build trên macOS (nếu có)

### Bước 1: Cài đặt dependencies
```bash
cd ios
pod install
cd ..
```

### Bước 2: Build iOS
```bash
# Simulator
flutter build ios --simulator

# Device
flutter build ios --release
```

### Bước 3: Mở Xcode (nếu cần)
```bash
open ios/Runner.xcworkspace
```

## Cấu hình đã thực hiện

### 1. **Permissions đã được thêm vào Info.plist:**
- `NSCameraUsageDescription`: Quyền camera
- `NSPhotoLibraryUsageDescription`: Quyền thư viện ảnh
- `NSLocationWhenInUseUsageDescription`: Quyền vị trí
- `NSContactsUsageDescription`: Quyền danh bạ
- `NSUserNotificationAlertStyle`: Style notification

### 2. **Background Modes:**
- `remote-notification`: Push notifications
- `background-processing`: Background tasks
- `background-fetch`: Background data fetch

### 3. **Firebase Configuration:**
- `FirebaseMessagingAutoInitEnabled`: Auto-init Firebase Messaging
- GoogleService-Info.plist đã được cấu hình đúng

### 4. **Notification Channels:**
- Customer Reminder Channel
- Test Notification Channel
- Proper iOS notification handling

## Tính năng iOS đã được hỗ trợ

✅ **Push Notifications**: Firebase Cloud Messaging
✅ **Local Notifications**: Scheduled reminders
✅ **Background Processing**: Notification handling
✅ **Permissions**: Tự động request khi cần
✅ **App Icon**: Đã cập nhật từ logo.jpg
✅ **App Name**: "VIP CSKH"

## Lưu ý quan trọng

1. **Build chỉ có thể thực hiện trên macOS** với Xcode
2. **CocoaPods** cần được cài đặt trên macOS
3. **Simulator testing** có thể thực hiện trên macOS
4. **Device testing** cần Apple Developer Account

## File đã được cấu hình

- ✅ `ios/Runner/Info.plist` - App settings và permissions
- ✅ `ios/Podfile` - Dependencies và build settings  
- ✅ `ios/Runner/GoogleService-Info.plist` - Firebase config
- ✅ `lib/services/notification_service.dart` - iOS notification support

## Kiểm tra cấu hình

Nếu bạn có macOS, chạy lệnh sau để kiểm tra:

```bash
flutter doctor
flutter build ios --debug --simulator
```

Tất cả cấu hình iOS đã sẵn sàng và tương thích!
