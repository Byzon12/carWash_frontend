# Wireless Debugging Setup Guide

## Problem
When debugging your Flutter app wirelessly on a real device, the app can't communicate with your backend server because `localhost` and `127.0.0.1` refer to the device itself, not your development computer.

## Solution
You need to use your computer's actual IP address on the local network.

## Steps to Fix

### 1. Find Your Computer's IP Address

**Option A: Use the provided script**
```powershell
# Run this in PowerShell from the project directory
.\find_ip.ps1
```

**Option B: Manual method**
```cmd
# Run this in Command Prompt
ipconfig
```
Look for your WiFi adapter's IPv4 Address (usually starts with 192.168.x.x)

### 2. Update the Code
1. Open `lib/api/api_connect.dart`
2. Find the line: `static const String _wirelessDebugIP = '192.168.1.100';`
3. Replace `192.168.1.100` with your actual IP address

### 3. Ensure Network Setup
- Your phone and computer must be on the same WiFi network
- Your backend server must be running on port 8000
- Check that no firewall is blocking the connection

### 4. Test the Connection
When you run the app, check the debug console for network setup instructions and connectivity test results.

## Troubleshooting

### Common Issues:
1. **Wrong IP Address**: Double-check your computer's IP with `ipconfig`
2. **Different Networks**: Ensure phone and computer are on same WiFi
3. **Firewall**: Windows Firewall might block the connection
4. **Backend Not Running**: Make sure your server is actually running on port 8000

### Debug Features:
- The app will print network instructions when it starts
- Use the "Debug API" button to test connectivity
- Check the console output for detailed error messages

### Network Configuration Examples:
```dart
// For WiFi (most common)
static const String _wirelessDebugIP = '192.168.1.105';

// For some routers
static const String _wirelessDebugIP = '192.168.0.105';

// For corporate networks
static const String _wirelessDebugIP = '10.0.0.105';
```

## Alternative URLs for Different Scenarios:
- **Android Emulator**: `http://10.0.2.2:8000/`
- **iOS Simulator**: `http://localhost:8000/`
- **Real Device (Wireless)**: `http://YOUR_IP:8000/`
- **Production**: `https://your-domain.com/`
