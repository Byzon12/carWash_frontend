@echo off
echo ========================================
echo    ANDROID SECURITY SETTINGS CHECKER
echo ========================================
echo.

echo [1/5] Checking AndroidManifest.xml permissions...
if exist "android\app\src\main\AndroidManifest.xml" (
    findstr /C:"INTERNET" android\app\src\main\AndroidManifest.xml >nul && echo ✅ INTERNET permission found || echo ❌ INTERNET permission missing
    findstr /C:"ACCESS_NETWORK_STATE" android\app\src\main\AndroidManifest.xml >nul && echo ✅ NETWORK_STATE permission found || echo ❌ NETWORK_STATE permission missing
    findstr /C:"ACCESS_FINE_LOCATION" android\app\src\main\AndroidManifest.xml >nul && echo ✅ FINE_LOCATION permission found || echo ❌ FINE_LOCATION permission missing
    findstr /C:"usesCleartextTraffic" android\app\src\main\AndroidManifest.xml >nul && echo ✅ Cleartext traffic enabled || echo ❌ Cleartext traffic not enabled
) else (
    echo ❌ AndroidManifest.xml not found
)
echo.

echo [2/5] Checking network security config...
if exist "android\app\src\main\res\xml\network_security_config.xml" (
    echo ✅ Network security config found
) else (
    echo ❌ Network security config missing
)
echo.

echo [3/5] Checking debug manifest...
if exist "android\app\src\debug\AndroidManifest.xml" (
    findstr /C:"INTERNET" android\app\src\debug\AndroidManifest.xml >nul && echo ✅ Debug INTERNET permission found || echo ❌ Debug INTERNET permission missing
    findstr /C:"usesCleartextTraffic" android\app\src\debug\AndroidManifest.xml >nul && echo ✅ Debug cleartext traffic enabled || echo ❌ Debug cleartext traffic not enabled
) else (
    echo ❌ Debug AndroidManifest.xml not found
)
echo.

echo [4/5] Checking build configuration...
if exist "android\app\build.gradle.kts" (
    findstr /C:"ndkVersion" android\app\build.gradle.kts >nul && echo ✅ NDK version configured || echo ❌ NDK version not configured
) else (
    echo ❌ build.gradle.kts not found
)
echo.

echo [5/5] Testing backend connectivity...
powershell -Command "try { $r = Invoke-WebRequest -Uri 'http://192.168.0.104:8000' -TimeoutSec 3; Write-Host '✅ Backend reachable from computer' -ForegroundColor Green } catch { Write-Host '❌ Backend not reachable' -ForegroundColor Red }"
echo.

echo ========================================
echo SUMMARY:
echo.
echo Your Android app should now be able to:
echo ✓ Make HTTP requests to your backend
echo ✓ Access location services
echo ✓ Connect to local development servers
echo.
echo Next steps:
echo 1. Clean and rebuild your Flutter app:
echo    flutter clean
echo    flutter pub get
echo    flutter run
echo.
echo 2. If still having issues, check:
echo    - Your backend is running: python manage.py runserver 0.0.0.0:8000
echo    - Your phone and computer are on same WiFi
echo    - Your IP address in api_connect.dart is correct: 192.168.0.104
echo ========================================
echo.
pause
