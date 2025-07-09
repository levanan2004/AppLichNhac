@echo off
REM Script build production cho project Flutter

echo 🚀 Bắt đầu build production...
echo.

REM Kiểm tra Flutter
flutter --version
if %errorlevel% neq 0 (
    echo ❌ Flutter không được cài đặt hoặc không trong PATH
    pause
    exit /b 1
)

REM Clean project
echo 🧹 Làm sạch project...
flutter clean

REM Get dependencies
echo 📦 Cài đặt dependencies...
flutter pub get

REM Kiểm tra lỗi
echo 🔍 Kiểm tra lỗi code...
flutter analyze
if %errorlevel% neq 0 (
    echo ⚠️  Có một số cảnh báo, nhưng vẫn tiếp tục build...
)

REM Build APK cho Android
echo 📱 Build APK cho Android...
flutter build apk --release --target-platform android-arm64
if %errorlevel% neq 0 (
    echo ❌ Build Android thất bại
    pause
    exit /b 1
)

REM Build App Bundle cho Google Play
echo 📦 Build App Bundle cho Google Play...
flutter build appbundle --release
if %errorlevel% neq 0 (
    echo ❌ Build App Bundle thất bại
    pause
    exit /b 1
)

echo.
echo ✅ Build thành công!
echo.
echo 📁 Các file được tạo:
echo - APK: build\app\outputs\flutter-apk\app-release.apk
echo - App Bundle: build\app\outputs\bundle\release\app-release.aab
echo.
echo 📋 Tiếp theo:
echo 1. Test APK trên thiết bị thật
echo 2. Upload App Bundle lên Google Play Console
echo 3. Cấu hình iOS nếu cần (cần macOS + Xcode)
echo.

REM Mở thư mục chứa file build
start "" "build\app\outputs\flutter-apk\"

pause
