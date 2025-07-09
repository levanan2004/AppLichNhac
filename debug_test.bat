@echo off
REM Debug script for Windows

echo 🔍 Debug script for VIP CSKH app
echo ================================
echo.

echo 📱 Chạy app trong debug mode và theo dõi console logs...
echo.
echo 🔔 Test lịch nhắc:
echo 1. Mở chi tiết khách hàng
echo 2. Nhấn nút + để thêm lịch nhắc
echo 3. Kiểm tra console logs với các từ khóa:
echo    - 🔔 Mở dialog thêm lịch nhắc mới
echo    - ✅ Nhận được lịch nhắc mới
echo    - 📋 Số lượng reminder
echo    - 💾 Cập nhật customer
echo    - 🔄 Reload customer data
echo.
echo 📞 Test cuộc gọi:
echo 1. Nhấn nút gọi điện
echo 2. Kiểm tra console logs với các từ khóa:
echo    - 📞 Bắt đầu gọi điện
echo    - ✅ Gọi điện thành công
echo    - 💾 Call log data
echo    - 🔄 Bắt đầu lưu call log
echo    - ✅ Lưu call log thành công
echo.
echo 💡 Lưu ý:
echo - Nếu không thấy logs, kiểm tra Firestore rules
echo - Kiểm tra internet connection
echo - Kiểm tra Firebase config
echo.

REM Chạy Flutter trong debug mode với verbose logging
flutter run --debug --verbose

pause
