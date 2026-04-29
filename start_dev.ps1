# ============================================================
#  DVPets Dev Starter
#  Cara pakai: klik kanan -> "Run with PowerShell"
#  atau ketik di terminal: powershell -ExecutionPolicy Bypass -File .\start_dev.ps1
# ============================================================

$PORT          = 8000
$LARAVEL_DIR   = "D:\laragon\www\devpets"
$PYTHON_DIR    = "D:\dvpets_v2"
$FLUTTER_CONST = "E:\flutterProject\dvpets\lib\core\constants\api_constants.dart"

# ── 1. Deteksi IP WiFi aktif
Write-Host ""
Write-Host "[1/5] Mendeteksi IP WiFi..." -ForegroundColor Cyan

$IP = (Get-NetIPAddress -AddressFamily IPv4 |
       Where-Object { $_.InterfaceAlias -match 'Wi-Fi|Wireless|WLAN' -and
                      $_.IPAddress -notmatch '^169' } |
       Select-Object -First 1).IPAddress

if (-not $IP) {
    $IP = (Get-NetIPAddress -AddressFamily IPv4 |
           Where-Object { $_.IPAddress -notmatch '^127\.' -and
                          $_.IPAddress -notmatch '^169\.' } |
           Select-Object -First 1).IPAddress
}

if (-not $IP) {
    Write-Host "GAGAL: Tidak dapat mendeteksi IP. Pastikan WiFi aktif!" -ForegroundColor Red
    Read-Host "Tekan Enter untuk keluar"
    exit 1
}

Write-Host "  --> IP ditemukan: $IP" -ForegroundColor Green

# ── 2. Update api_constants.dart Flutter
Write-Host "[2/5] Update Flutter api_constants.dart..." -ForegroundColor Cyan
$newBaseUrl  = "http://${IP}:${PORT}/api"
$content     = Get-Content $FLUTTER_CONST -Raw -Encoding UTF8
$newContent  = $content -replace 'static const String baseUrl = "http://[^"]+";',
                                 "static const String baseUrl = `"$newBaseUrl`";"
Set-Content $FLUTTER_CONST $newContent -Encoding UTF8
Write-Host "  --> baseUrl = $newBaseUrl" -ForegroundColor Green

# ── 3. Update .env Laravel APP_URL
Write-Host "[3/5] Update Laravel .env APP_URL..." -ForegroundColor Cyan
$envPath    = "$LARAVEL_DIR\.env"
$envContent = Get-Content $envPath -Raw -Encoding UTF8
$envContent = $envContent -replace 'APP_URL=http://[^\r\n]+', "APP_URL=http://${IP}:${PORT}"
Set-Content $envPath $envContent -Encoding UTF8
Write-Host "  --> APP_URL = http://${IP}:${PORT}" -ForegroundColor Green

# ── 4. Clear Laravel config cache
Write-Host "[4/5] Clear Laravel config cache..." -ForegroundColor Cyan
$proc = Start-Process -FilePath "php" `
    -ArgumentList "artisan", "config:clear" `
    -WorkingDirectory $LARAVEL_DIR `
    -Wait -NoNewWindow -PassThru
if ($proc.ExitCode -eq 0) {
    Write-Host "  --> Config cache cleared" -ForegroundColor Green
} else {
    Write-Host "  --> Peringatan: config:clear gagal (tidak kritis)" -ForegroundColor Yellow
}

# ── 5. Start Python AI Service di terminal baru
Write-Host "[5/5] Menjalankan Python AI Service dan Laravel..." -ForegroundColor Cyan

$pythonCmd  = "Write-Host 'DVPets Python AI Service - port 5000' -ForegroundColor Yellow; " +
              "Set-Location '$PYTHON_DIR'; python app.py; Read-Host 'Tekan Enter'"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $pythonCmd

Start-Sleep -Seconds 2

$laravelCmd = "Write-Host 'DVPets Laravel Server - port $PORT' -ForegroundColor Yellow; " +
              "Set-Location '$LARAVEL_DIR'; php artisan serve --host=$IP --port=$PORT"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $laravelCmd

# ── Ringkasan
Write-Host ""
Write-Host "================================================" -ForegroundColor Yellow
Write-Host "  DVPets Dev Environment Siap!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Yellow
Write-Host "  Flutter baseUrl : $newBaseUrl" -ForegroundColor White
Write-Host "  Laravel Server  : http://${IP}:${PORT}" -ForegroundColor White
Write-Host "  Python AI       : http://127.0.0.1:5000" -ForegroundColor White
Write-Host "================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Tinggal jalankan Flutter di emulator/HP!" -ForegroundColor Green
Write-Host ""
Read-Host "Tekan Enter untuk menutup jendela ini"
