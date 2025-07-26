@echo off
cls
echo ========================================
echo    FLUTTER WIRELESS DEBUG HELPER
echo ========================================
echo.

echo [1/4] Checking your IP addresses...
echo.
ipconfig | findstr /C:"IPv4 Address"
echo.

echo [2/4] Testing if backend is running locally...
echo.
powershell -Command "try { $response = Invoke-WebRequest -Uri 'http://localhost:8000' -TimeoutSec 3; Write-Host 'SUCCESS: Backend responding on localhost:8000 (Status: ' $response.StatusCode ')' -ForegroundColor Green } catch { Write-Host 'FAILED: Backend not responding on localhost:8000' -ForegroundColor Red; Write-Host 'Error: ' $_.Exception.Message -ForegroundColor Red }"
echo.

echo [3/4] Testing Node.js backend connectivity test...
echo.
if exist "test_backend_api.js" (
    node test_backend_api.js
) else (
    echo test_backend_api.js not found, skipping...
)
echo.

echo [4/4] Instructions for Flutter app:
echo.
echo 1. Find your WiFi IP address from step 1 above (usually 192.168.x.x)
echo 2. Open lib/api/api_connect.dart in VS Code
echo 3. Update this line:
echo    static const String _wirelessDebugIP = 'YOUR_IP_HERE';
echo 4. Replace YOUR_IP_HERE with your actual IP address
echo 5. Make sure your phone and computer are on the same WiFi
echo 6. Run your Flutter app and check the debug console
echo.

echo ========================================
echo Troubleshooting tips:
echo - If backend test failed, make sure your server is running
echo - If you can't find your IP, disconnect/reconnect WiFi
echo - Check Windows Firewall if connection still fails
echo - Ensure port 8000 is not blocked
echo ========================================
echo.
pause
