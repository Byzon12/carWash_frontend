#!/usr/bin/env pwsh

# Script to find your IP address for wireless debugging
Write-Host "=== Finding Your IP Address for Wireless Debugging ===" -ForegroundColor Green

# Get network adapters with IP addresses
$adapters = Get-NetIPConfiguration | Where-Object { $_.IPv4Address -ne $null -and $_.InterfaceAlias -like "*Wi-Fi*" -or $_.InterfaceAlias -like "*Wireless*" -or $_.InterfaceAlias -like "*Ethernet*" }

if ($adapters) {
    Write-Host "`nFound network adapters:" -ForegroundColor Yellow
    
    foreach ($adapter in $adapters) {
        $ip = $adapter.IPv4Address.IPAddress
        $interface = $adapter.InterfaceAlias
        
        Write-Host "Interface: $interface" -ForegroundColor Cyan
        Write-Host "IP Address: $ip" -ForegroundColor White
        
        # Check if this looks like a local network IP
        if ($ip -match "^192\.168\." -or $ip -match "^10\." -or $ip -match "^172\.(1[6-9]|2[0-9]|3[01])\.") {
            Write-Host "✓ This looks like a local network IP - GOOD for wireless debugging!" -ForegroundColor Green
            Write-Host "Use this IP in your api_connect.dart file: $ip" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    
    Write-Host "Next steps:" -ForegroundColor Magenta
    Write-Host "1. Copy one of the local network IPs above (192.168.x.x format)" -ForegroundColor White
    Write-Host "2. Open lib/api/api_connect.dart" -ForegroundColor White
    Write-Host "3. Replace '_wirelessDebugIP' value with your IP" -ForegroundColor White
    Write-Host "4. Make sure your backend server is running on port 8000" -ForegroundColor White
    Write-Host "5. Ensure your phone and computer are on the same WiFi network" -ForegroundColor White
    
} else {
    Write-Host "No network adapters found with IP addresses." -ForegroundColor Red
    Write-Host "Try running: ipconfig" -ForegroundColor Yellow
}

Write-Host "`nPress any key to continue..."
Read-Host
