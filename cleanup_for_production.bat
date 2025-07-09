@echo off
REM Script làm sạch project Flutter để chuẩn bị gửi khách hàng

echo Đang làm sạch project Flutter cho production...

REM Xóa các file backup và test không cần thiết
if exist "lib\screens\customer\customer_detail_screen_backup_old.dart" del "lib\screens\customer\customer_detail_screen_backup_old.dart"
if exist "lib\screens\customer\customer_detail_screen_fixed.dart" del "lib\screens\customer\customer_detail_screen_fixed.dart"
if exist "lib\screens\customer\customer_detail_screen_vietnamese.dart" del "lib\screens\customer\customer_detail_screen_vietnamese.dart"
if exist "lib\screens\customer\customer_detail_screen_backup.dart" del "lib\screens\customer\customer_detail_screen_backup.dart"
if exist "lib\screens\customer\add_customer_screen_backup.dart" del "lib\screens\customer\add_customer_screen_backup.dart"
if exist "lib\screens\customer\add_customer_screen_vietnamese.dart" del "lib\screens\customer\add_customer_screen_vietnamese.dart"
if exist "lib\screens\customer\add_customer_screen_fixed.dart" del "lib\screens\customer\add_customer_screen_fixed.dart"
if exist "lib\screens\customer\add_customer_screen_new.dart" del "lib\screens\customer\add_customer_screen_new.dart"
if exist "lib\services\call_service_fixed.dart" del "lib\services\call_service_fixed.dart"
if exist "lib\app_fixed.dart" del "lib\app_fixed.dart"

REM Xóa các file log và cache
if exist "pglite-debug.log" del "pglite-debug.log"

REM Clean Flutter build
flutter clean

REM Get dependencies
flutter pub get

REM Run code generation (if any)
flutter packages pub run build_runner build --delete-conflicting-outputs

echo.
echo ✅ Project đã được làm sạch và chuẩn bị cho production!
echo.
echo Các file đã được xóa:
echo - Các file backup (_backup, _old, _fixed, _vietnamese, _new)
echo - File log debug
echo - Flutter build cache
echo.
echo Để build production:
echo - Android: flutter build apk --release
echo - iOS: flutter build ios --release
echo.
pause
