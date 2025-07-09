# 🎯 PROMPT XÂY DỰNG LẠI ỨNG DỤNG VIP CSKH

## 📋 TỔNG QUAN DỰ ÁN

Xây dựng một ứng dụng **Flutter** quản lý chăm sóc khách hàng VIP cho ngành mỹ phẩm với tên "**VIP CSKH**". Ứng dụng có hệ thống xác thực phân quyền và giao diện tiếng Việt đẹp mắt.

---

## 🎨 THIẾT KẾ UI/UX

### **Màu Sắc Chủ Đạo**
- **Primary Color**: `Colors.green` (#4CAF50)
- **Background**: `Color(0xFFFFF6F8)` (hồng rất nhạt)
- **Card Background**: `Colors.white`
- **Success**: `Colors.green`
- **Warning**: `Colors.orange` 
- **Error**: `Colors.red`
- **Info**: `Colors.blue`

### **Typography**
- **Font**: Roboto (mặc định Flutter)
- **Heading**: Bold, màu xanh lá
- **Body**: Regular, màu đen/xám
- **Labels**: Medium weight
- **Hỗ trợ**: Unicode đầy đủ cho tiếng Việt

### **Layout Style**
- **Border Radius**: 12px cho cards, 8px cho buttons
- **Padding**: 16px chuẩn, 24px cho màn hình
- **Elevation**: 2-4 cho cards
- **Icons**: Material Design, màu xanh lá

---

## 🏗️ KIẾN TRÚC ỨNG DỤNG

### **Models**
```dart
// Customer Model
class Customer {
  String? id;
  String name;           // Tên khách hàng
  String phone;          // Số điện thoại
  String address;        // Địa chỉ
  String serviceCompleted; // Dịch vụ đã hoàn thành
  double amountSpent;    // Số tiền đã chi
  List<Reminder> reminders; // Danh sách lịch nhắc
  String? notes;         // Ghi chú
  String? avatarUrl;     // URL ảnh đại diện
  DateTime createdAt;    // Ngày tạo
  DateTime updatedAt;    // Ngày cập nhật
}

// Reminder Model  
class Reminder {
  String? id;
  DateTime reminderDate;    // Ngày nhắc nhở
  String description;       // Mô tả ngắn
  String? detailedDescription; // Mô tả chi tiết
  String? imageUrl;         // URL hình ảnh
  bool isCompleted;         // Đã hoàn thành
  DateTime createdAt;       // Ngày tạo
  DateTime? completedAt;    // Ngày hoàn thành
}

// Auth Models
class AccessCode {
  String code;              // Mã truy cập 6 ký tự
  bool isActive;           // Còn hiệu lực
  String? usedBy;          // Được sử dụng bởi ai
  DateTime createdAt;      // Ngày tạo
  DateTime? usedAt;        // Ngày sử dụng
}
```

### **Services**
```dart
// CustomerService - Quản lý khách hàng
- getCustomers() -> Stream<List<Customer>>
- addCustomer(Customer) -> Future<String?>
- updateCustomer(Customer) -> Future<bool>
- deleteCustomer(String id) -> Future<bool>
- searchCustomers(String query) -> Future<List<Customer>>
- getCustomersDueToday() -> Future<List<Customer>>
- getOverdueCustomers() -> Future<List<Customer>>
- getUpcomingCustomers({int days}) -> Future<List<Customer>>
- getCustomersCompletedToday() -> Future<List<Customer>>
- getCustomersCreatedToday() -> Future<List<Customer>>

// AuthService - Xác thực và phân quyền
- adminLogin(username, password) -> Future<bool>
- employeeLogin(accessCode) -> Future<bool>
- createAccessCode() -> Future<String>
- getAccessCodes() -> Stream<List<AccessCode>>
- logout() -> Future<void>
- isAuthenticated() -> Future<bool>
- getUserType() -> Future<String?>

// WhatsAppService - Tích hợp WhatsApp
- openWhatsAppBusinessChat(phone, message) -> Future<bool>
- createCustomerMessage(customerName) -> String

// ImageService - Quản lý hình ảnh
- uploadCustomerAvatar(imageBytes, customerId) -> Future<String?>
- uploadReminderImage(imageBytes, customerId, reminderId) -> Future<String?>
- deleteCustomerAvatar(imageUrl) -> Future<void>

// CallService - Lịch sử cuộc gọi
- logCall(customerId, duration, notes) -> Future<void>
- getCallLogsForCustomer(customerId) -> Future<List<CallLog>>
```

---

## 📱 CẤU TRÚC SCREENS

### **1. Authentication Flow**

#### **RoleSelectionScreen** 
- 2 nút lớn: "QUẢN TRỊ VIÊN" (filled) và "NHÂN VIÊN" (outlined)
- Logo app ở giữa
- Background màu hồng nhạt
- Typography bold, màu xanh lá

#### **AdminLoginScreen**
- Form đăng nhập: username + password
- Show/hide password
- Validation đầy đủ
- Loading state với CircularProgressIndicator
- Icon admin_panel_settings

#### **EmployeeLoginScreen** 
- Input mã truy cập 6 ký tự
- Auto uppercase
- Center alignment text
- Ghi chú hướng dẫn
- Icon person

#### **AdminDashboardScreen**
- Stats card với icon
- Danh sách access codes
- Nút tạo mã mới
- ListTile với status indicators
- Popup menu đăng xuất

### **2. Customer Management Flow**

#### **CustomerListScreen** (Main Screen)
- **AppBar**: Tiêu đề + notification icon + menu (admin/logout)
- **Search Section** (màu xanh với gradient):
  - TextField tìm kiếm với border radius 12
  - Dropdown "Lọc & sắp xếp" với 5 options:
    - "Ưu tiên" (mặc định)
    - "Ngày nhắc gần nhất" 
    - "Tên A-Z"
    - "Lịch vừa nhắc hôm nay"
    - "Lịch vừa thêm hôm nay"
- **Customer Cards**:
  - Card với elevation 2, border radius 12
  - Avatar trái + thông tin giữa + badge/arrow phải
  - Viền màu cho từng loại: đỏ (urgent), xanh lá (completed), xanh dương (created)
  - Badge hiển thị số lượng tương ứng
  - Text info động theo loại lọc
- **FloatingActionButton**: Màu xanh, icon add

#### **CustomerDetailScreen**
- **TabBar**: "Thông tin" + "Lịch sử gọi"
- **AppBar**: Tên khách hàng + phone icon (WhatsApp) + menu (edit/delete)
- **Avatar Section**: Có thể upload/edit/delete ảnh
- **Info Cards**: 
  - Thông tin khách hàng (icon + label + value)
  - Dịch vụ & chi tiêu
  - Danh sách reminders với checkbox
  - Ghi chú (nếu có)
- **Reminder Items**:
  - Checkbox + mô tả + ngày
  - Màu background: xanh (completed), đỏ (overdue), cam (today) 
  - Icon warning cho overdue
  - Upload/view ảnh reminder
- **FAB**: Thêm reminder mới

#### **AddCustomerScreen**
- **Form đầy đủ**:
  - Tên khách hàng (required)
  - Số điện thoại (required) 
  - Địa chỉ (required)
  - Dịch vụ hoàn thành
  - Số tiền chi (number input)
  - Ghi chú (multiline)
- **Reminder Section**:
  - Danh sách reminder inputs
  - Mỗi reminder: date picker + mô tả + mô tả chi tiết
  - Nút thêm/xóa reminder
  - Border màu xanh khi valid
- **Bottom Button**: "Lưu khách hàng" full width

#### **EditCustomerScreen** 
- Tương tự AddCustomerScreen nhưng pre-fill data
- Avatar section ở đầu
- Giữ nguyên reminders đã completed
- Có thể edit reminder chưa completed

### **3. Reminder Management**

#### **Add Reminder Dialog**
- TextField mô tả (required)
- TextField mô tả chi tiết (optional)
- Date picker với format dd/MM/yyyy
- Upload ảnh (optional)
- Actions: Hủy + Thêm

---

## 🎨 COMPONENT DESIGNS

### **Cards**
```dart
Card(
  elevation: 2,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(color: borderColor, width: borderWidth), // Conditional
  ),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: // Content
  ),
)
```

### **TextFields**
```dart
TextFormField(
  decoration: InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: Colors.green),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.green),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12), 
      borderSide: BorderSide(color: Colors.green, width: 2),
    ),
    filled: true,
    fillColor: Colors.white,
  ),
)
```

### **Buttons**
```dart
// Primary Button
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    minimumSize: Size(double.infinity, 50),
  ),
  child: Text('Button Text', 
    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
  ),
)

// Secondary Button  
OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: Colors.green,
    side: BorderSide(color: Colors.green, width: 2),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  child: Text('Button Text'),
)
```

### **AppBar Style**
```dart
AppBar(
  backgroundColor: Colors.green,
  foregroundColor: Colors.white,
  elevation: 0,
  title: Text(title, 
    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
  ),
)
```

### **Search Bar**
```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.green,
    borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(24),
      bottomRight: Radius.circular(24),
    ),
  ),
  child: TextField(
    decoration: InputDecoration(
      hintText: 'Tìm kiếm khách hàng...',
      prefixIcon: Icon(Icons.search, color: Colors.green),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  ),
)
```

---

## 📊 BUSINESS LOGIC

### **Sorting & Filtering**
1. **"Ưu tiên"**: Số lượng urgent → ngày gần nhất → tên A-Z
2. **"Ngày nhắc gần nhất"**: Ngày reminder sớm nhất → tên A-Z
3. **"Tên A-Z"**: Sắp xếp alphabet
4. **"Lịch vừa nhắc hôm nay"**: Lọc customers có reminder completed today → số lượng → thời gian gần nhất
5. **"Lịch vừa thêm hôm nay"**: Lọc customers có reminder created today → số lượng → thời gian gần nhất

### **Status Logic**
```dart
// Priority levels
1: Overdue (quá hạn) - màu đỏ
2: Today (hôm nay) - màu cam  
3: Tomorrow (ngày mai) - màu tím nhạt
4: Soon (trong 3 ngày) - màu xanh lá nhạt
5: Others - màu trắng
```

### **Card Appearance**
- **Border Color**: Đỏ (urgent), Xanh lá (completed today), Xanh dương (created today)
- **Badge**: Hiển thị số lượng tương ứng với màu border
- **Text Info**: Dynamic theo loại lọc

---

## 🔐 AUTHENTICATION SYSTEM

### **User Roles**
- **Admin**: Toàn quyền + quản lý access codes
- **Employee**: Sử dụng app với access code

### **Access Code System**
- Mã 6 ký tự random (A-Z, 0-9)
- Chỉ sử dụng 1 lần
- Admin tạo và quản lý
- Lưu trạng thái: active/used + metadata

### **Security Features**
- Hash password với SHA-256 + salt
- Session management
- Auto logout khi cần
- Validation đầy đủ

---

## 🔧 TECHNICAL REQUIREMENTS

### **Dependencies**
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  
  # Firebase
  firebase_core: ^3.14.0
  cloud_firestore: ^5.6.9
  firebase_storage: ^12.3.4
  
  # UI/UX
  flutter_screenutil: ^5.9.3
  intl: ^0.20.2
  flutter_localizations:
    sdk: flutter
    
  # Utilities
  shared_preferences: ^2.2.2
  crypto: ^3.0.3
  permission_handler: ^11.3.1
  device_info_plus: ^10.1.2
  
  # External Integration
  url_launcher: ^6.2.2
  whatsapp_unilink: ^2.1.0
  android_intent_plus: ^4.0.3
  
  # Media
  image: ^4.2.0
  image_picker: ^1.1.2
  path: ^1.9.0
  
  # Date/Time
  flutter_datetime_picker_plus: ^2.2.0
  flutter_cupertino_datetime_picker: ^3.0.0
  timezone: ^0.9.4
```

### **Folder Structure**
```
lib/
├── main.dart
├── app.dart
├── models/
│   ├── customer.dart
│   ├── reminder.dart
│   ├── access_code.dart
│   └── call_log.dart
├── services/
│   ├── customer_service.dart
│   ├── auth_service.dart
│   ├── whatsapp_service.dart
│   ├── image_service.dart
│   └── call_service.dart
├── screens/
│   ├── auth/
│   │   ├── role_selection_screen.dart
│   │   ├── admin_login_screen.dart
│   │   ├── employee_login_screen.dart
│   │   └── admin_dashboard_screen.dart
│   └── customer/
│       ├── customer_list_screen.dart
│       ├── customer_detail_screen.dart
│       ├── add_customer_screen.dart
│       └── edit_customer_screen.dart
├── widgets/
│   ├── auth_wrapper.dart
│   ├── customer_avatar.dart
│   └── notification_icon.dart
└── utils/
    └── constants.dart
```

---

## 📋 DEVELOPMENT CHECKLIST

### **Phase 1: Setup & Models**
- [ ] Tạo project Flutter mới
- [ ] Setup Firebase (Firestore + Storage)
- [ ] Tạo models: Customer, Reminder, AccessCode
- [ ] Setup theme và colors

### **Phase 2: Authentication**
- [ ] RoleSelectionScreen UI
- [ ] AdminLoginScreen + logic
- [ ] EmployeeLoginScreen + logic
- [ ] AdminDashboardScreen + access code management
- [ ] AuthWrapper và routing

### **Phase 3: Customer Management**
- [ ] CustomerListScreen với search/filter
- [ ] AddCustomerScreen với form validation
- [ ] CustomerDetailScreen với tabs
- [ ] EditCustomerScreen
- [ ] Customer services (CRUD operations)

### **Phase 4: Advanced Features**
- [ ] Image upload/management
- [ ] WhatsApp integration
- [ ] Call log functionality
- [ ] Reminder management với image
- [ ] Advanced filtering (completed today, created today)

### **Phase 5: Polish & Testing**
- [ ] Error handling toàn diện
- [ ] Loading states
- [ ] Empty states với messages thông minh
- [ ] Responsive design
- [ ] Testing trên multiple devices

---

## 🎯 KEY FEATURES TO IMPLEMENT

1. **Smart Filtering**: 5 loại lọc với UI động
2. **Visual Indicators**: Border colors, badges, status text
3. **Image Management**: Avatar + reminder images
4. **WhatsApp Integration**: Direct chat với business account
5. **Role-based Access**: Admin vs Employee permissions
6. **Vietnamese Localization**: Đầy đủ UI tiếng Việt
7. **Responsive Design**: Hoạt động tốt mọi screen size
8. **Real-time Updates**: Firebase streams cho data sync
9. **Offline Support**: Caching với SharedPreferences
10. **Professional UI**: Material Design với custom branding

---

## 🚀 DEPLOYMENT NOTES

- **Android**: Cấu hình Firebase + permissions
- **iOS**: Cấu hình Firebase + Info.plist
- **Build**: flutter build apk/ios
- **Assets**: Logo app trong assets/
- **Localization**: Default Vietnamese, fallback English

---

**📌 LƯU Ý QUAN TRỌNG**: 
- KHÔNG implement push notifications (đã loại bỏ khỏi requirements)
- Focus vào UI/UX đẹp, smooth, professional
- Validation đầy đủ ở mọi input
- Error handling graceful với user-friendly messages
- Code clean, có comments tiếng Việt khi cần thiết
