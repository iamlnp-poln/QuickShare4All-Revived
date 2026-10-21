<#
.SYNOPSIS
    Enables Samsung Quick Share to run on non-Samsung Windows PCs (Dell, HP, Lenovo, ASUS, etc.)
.DESCRIPTION
    Activates the internal non-Samsung support mechanism discovered in Samsung Quick Share 2.3+.
    Places QuickShare_Non_Samsung_support.config into LocalState and ensures services are ready.
#>

$ErrorActionPreference = 'Stop'

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " QuickShare4All Revived: Samsung Quick Share Enabler     " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Locate Samsung Quick Share LocalState directory
$appDataPackages = Join-Path $env:LOCALAPPDATA "Packages"
$targetFolder = Get-ChildItem -Path $appDataPackages -Filter "*SamsungQuickShare*" -ErrorAction SilentlyContinue | 
                Select-Object -First 1

if (-not $targetFolder) {
    Write-Error "Samsung Quick Share package not found in LocalAppData. Please install Samsung Quick Share from Microsoft Store or via MSIX bundle first."
}

$localStateDir = Join-Path $targetFolder.FullName "LocalState"
if (-not (Test-Path $localStateDir)) {
    Write-Host "[*] Creating LocalState directory at: $localStateDir" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $localStateDir -Force | Out-Null
}

# 2. Create the non-Samsung support trigger config
$configFile = Join-Path $localStateDir "QuickShare_Non_Samsung_support.config"
if (-not (Test-Path $configFile)) {
    Write-Host "[+] Creating non-Samsung support trigger config..." -ForegroundColor Yellow
    New-Item -ItemType File -Path $configFile -Force | Out-Null
}
Write-Host "[+] Verified configuration file: $configFile" -ForegroundColor Green

# 3. Check SamsungQuickShareService if present
$svc = Get-Service -Name "SamsungQuickShareService" -ErrorAction SilentlyContinue
if ($svc) {
    Write-Host "[+] SamsungQuickShareService status: $($svc.Status)" -ForegroundColor Green
    if ($svc.Status -ne 'Running') {
        Write-Host "[*] Starting SamsungQuickShareService..." -ForegroundColor Yellow
        Start-Service -Name "SamsungQuickShareService" -ErrorAction SilentlyContinue
    }
}

# 4. Launch Quick Share protocol to activate
Write-Host "`n[*] Starting Quick Share daemon..." -ForegroundColor Cyan
Start-Process "quickshare:"

Start-Sleep -Seconds 2

$proc = Get-Process -Name QuickShare, QuickShareCore -ErrorAction SilentlyContinue
if ($proc) {
    Write-Host "[SUCCESS] Samsung Quick Share is now running smoothly on this PC!" -ForegroundColor Green
    $proc | Select-Object Id, ProcessName, WorkingSet64 | Format-Table -AutoSize
} else {
    Write-Host "[!] Note: Check system tray to confirm Quick Share is running." -ForegroundColor Yellow
}
