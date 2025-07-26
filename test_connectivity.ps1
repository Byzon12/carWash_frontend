#!/usr/bin/env pwsh

Write-Host "=== BACKEND SERVER DIAGNOSTIC ===" -ForegroundColor Yellow
Write-Host ""

# Test different protocols and endpoints
$testConfigs = @(
    @{url="http://localhost:8000"; desc="Localhost HTTP"},
    @{url="https://localhost:8000"; desc="Localhost HTTPS"},
    @{url="http://127.0.0.1:8000"; desc="127.0.0.1 HTTP"},
    @{url="http://192.168.0.104:8000"; desc="Network IP HTTP"},
    @{url="https://192.168.0.104:8000"; desc="Network IP HTTPS"},
    @{url="http://192.168.0.104:8000/user/"; desc="Network IP + /user/ endpoint"},
    @{url="http://192.168.0.104:8000/api/"; desc="Network IP + /api/ endpoint"},
    @{url="http://192.168.0.104:8000/admin/"; desc="Network IP + /admin/ endpoint"}
)

foreach ($config in $testConfigs) {
    Write-Host "Testing: $($config.desc)" -ForegroundColor Cyan
    try {
        $response = Invoke-WebRequest -Uri $config.url -TimeoutSec 3 -UseBasicParsing
        Write-Host "  ✅ SUCCESS - Status: $($response.StatusCode)" -ForegroundColor Green
        if ($response.Content.Length -lt 200) {
            Write-Host "  📄 Response: $($response.Content.Substring(0, [Math]::Min(100, $response.Content.Length)))" -ForegroundColor White
        }
    }
    catch {
        $errorMsg = $_.Exception.Message
        if ($errorMsg -like "*SSL/TLS*") {
            Write-Host "  ❌ SSL/TLS Error (try HTTP instead of HTTPS)" -ForegroundColor Red
        }
        elseif ($errorMsg -like "*timeout*") {
            Write-Host "  ⏱️ TIMEOUT" -ForegroundColor Yellow
        }
        elseif ($errorMsg -like "*refused*" -or $errorMsg -like "*cannot connect*") {
            Write-Host "  🚫 CONNECTION REFUSED" -ForegroundColor Red
        }
        else {
            Write-Host "  ❌ ERROR: $errorMsg" -ForegroundColor Red
        }
    }
    Write-Host ""
}

Write-Host "=== NEXT STEPS ===" -ForegroundColor Yellow
Write-Host "1. If any URL shows SUCCESS, use that in your Flutter app"
Write-Host "2. If all fail, check your backend server logs"
Write-Host "3. Make sure your backend allows external connections"
Write-Host "4. For Django: python manage.py runserver 0.0.0.0:8000"
Write-Host "5. For Node/Express: app.listen(8000, '0.0.0.0')"
