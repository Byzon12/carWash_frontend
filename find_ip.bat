@echo off
echo === FINDING YOUR IP ADDRESS FOR WIRELESS DEBUGGING ===
echo.
echo Running ipconfig to find your network adapters...
echo.
ipconfig | findstr /i "IPv4"
echo.
echo === DETAILED NETWORK INFO ===
ipconfig /all | findstr /i "wireless\|wi-fi\|ethernet" -A 5
echo.
echo Look for an IPv4 Address that starts with:
echo - 192.168.x.x (most common)
echo - 10.x.x.x (some networks) 
echo - 172.16-31.x.x (corporate networks)
echo.
echo Copy that IP address and update _wirelessDebugIP in api_connect.dart
echo.
pause
