@echo off
echo Testing Flutter wireless debugging connection...
echo.
echo Current configuration:
echo - Your computer IP: 192.168.0.104
echo - Backend port: 8000
echo - Flutter app will connect to: http://192.168.0.104:8000
echo.
echo Testing connection...
powershell -Command "try { $r = Invoke-WebRequest -Uri 'http://192.168.0.104:8000' -TimeoutSec 5; Write-Host 'SUCCESS: Backend is accessible!' -ForegroundColor Green; Write-Host 'Status Code:' $r.StatusCode } catch { Write-Host 'FAILED: Backend not accessible' -ForegroundColor Red; Write-Host 'Make sure to start your backend with: python manage.py runserver 0.0.0.0:8000' }"
echo.
echo If successful, your Flutter app should now connect!
pause
