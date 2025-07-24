# Flutter Login Debug Helper Script
# This script helps diagnose and resolve login connectivity issues

Write-Host "=== Flutter Login Debug Helper ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check if Flutter is available
Write-Host "1. Checking Flutter installation..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Flutter is installed" -ForegroundColor Green
    } else {
        Write-Host "❌ Flutter is not installed or not in PATH" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Flutter is not available" -ForegroundColor Red
    exit 1
}

# Step 2: Check project directory
Write-Host "2. Checking project directory..." -ForegroundColor Yellow
$projectPath = "c:\Users\BYZONE\front\flutter_application_2"

if (Test-Path $projectPath) {
    Write-Host "✅ Project directory found: $projectPath" -ForegroundColor Green
    Set-Location $projectPath
} else {
    Write-Host "❌ Project directory not found: $projectPath" -ForegroundColor Red
    exit 1
}

# Step 3: Check for pubspec.yaml
Write-Host "3. Checking Flutter project structure..." -ForegroundColor Yellow
if (Test-Path "pubspec.yaml") {
    Write-Host "✅ Flutter project structure is valid" -ForegroundColor Green
} else {
    Write-Host "❌ Not a valid Flutter project (pubspec.yaml not found)" -ForegroundColor Red
    exit 1
}

# Step 4: Install dependencies
Write-Host "4. Installing Flutter dependencies..." -ForegroundColor Yellow
try {
    flutter pub get
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Dependencies installed successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Error installing dependencies" -ForegroundColor Red
    exit 1
}

# Step 5: Test backend connectivity
Write-Host "5. Testing backend connectivity..." -ForegroundColor Yellow

$backendUrls = @(
    "http://localhost:8000/user/",
    "http://127.0.0.1:8000/user/"
)

$backendAvailable = $false
foreach ($url in $backendUrls) {
    try {
        Write-Host "   Testing: $url" -ForegroundColor Gray
        $response = Invoke-WebRequest -Uri $url -Method GET -TimeoutSec 5 -ErrorAction Stop
        Write-Host "✅ Backend is available at: $url (Status: $($response.StatusCode))" -ForegroundColor Green
        $backendAvailable = $true
        break
    } catch {
        Write-Host "   ❌ Cannot reach: $url" -ForegroundColor Red
    }
}

if (-not $backendAvailable) {
    Write-Host "❌ Backend is not running or not accessible" -ForegroundColor Red
    Write-Host "   Please start your Django backend server first" -ForegroundColor Yellow
    Write-Host "   Example: python manage.py runserver 127.0.0.1:8000" -ForegroundColor Gray
}

# Step 6: Provide options
Write-Host ""
Write-Host "=== Available Actions ===" -ForegroundColor Cyan
Write-Host "1. Start Flutter web app (http://localhost:3000)" -ForegroundColor White
Write-Host "2. Open login debug tool (http://localhost:3000/#/login-debug)" -ForegroundColor White
Write-Host "3. Run Flutter doctor for diagnostics" -ForegroundColor White
Write-Host "4. Exit" -ForegroundColor White
Write-Host ""

do {
    $choice = Read-Host "Enter your choice (1-4)"
    
    switch ($choice) {
        "1" {
            Write-Host "Starting Flutter web application..." -ForegroundColor Yellow
            Write-Host "The app will be available at: http://localhost:3000" -ForegroundColor Green
            Write-Host "Use Ctrl+C to stop the server" -ForegroundColor Gray
            flutter run -d web-server --web-port=3000
            break
        }
        "2" {
            Write-Host "Starting Flutter web application with debug focus..." -ForegroundColor Yellow
            Write-Host "Navigate to: http://localhost:3000/#/login-debug" -ForegroundColor Green
            Write-Host "Use Ctrl+C to stop the server" -ForegroundColor Gray
            Start-Process "http://localhost:3000/#/login-debug" -ErrorAction SilentlyContinue
            flutter run -d web-server --web-port=3000
            break
        }
        "3" {
            Write-Host "Running Flutter doctor..." -ForegroundColor Yellow
            flutter doctor -v
            Write-Host ""
        }
        "4" {
            Write-Host "Goodbye!" -ForegroundColor Green
            exit 0
        }
        default {
            Write-Host "Invalid choice. Please enter 1, 2, 3, or 4." -ForegroundColor Red
        }
    }
} while ($true)
