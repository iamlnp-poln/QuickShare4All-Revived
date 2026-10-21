#Requires -Version 5.1
<#
.SYNOPSIS
    Registers "Send with Quick Share" into Windows File Explorer context menu for Google Quick Share.
.DESCRIPTION
    Google Quick Share runs on all Windows PCs but often fails to register the right-click Explorer
    context menu due to sparse package / MSIX signature restrictions on Windows 10/11.
    This script registers a clean, native right-click context menu (per-user, no admin required).
#>

$ErrorActionPreference = 'Stop'

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " QuickShare4All Revived: Google Quick Share Menu Enabler  " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Locate Google Quick Share executable and launcher
$possibleLauncherPaths = @(
    "C:\Program Files\Google\NearbyShare\nearby_share_launcher.exe",
    (Join-Path $env:LOCALAPPDATA "Google\NearbyShare\nearby_share_launcher.exe"),
    "C:\Program Files\Google\NearbyShare\nearby_share.exe"
)

$launcherPath = ""
foreach ($p in $possibleLauncherPaths) {
    if (Test-Path $p) {
        $launcherPath = $p
        break
    }
}

if (-not $launcherPath) {
    Write-Error "Google Quick Share was not found. Please install Google Quick Share from official Google website first."
}

Write-Host "[+] Found Google Quick Share launcher: $launcherPath" -ForegroundColor Green

# 2. Locate Icon
$iconPath = Join-Path (Split-Path $launcherPath) "nearby_share.exe"
if (-not (Test-Path $iconPath)) {
    $iconPath = $launcherPath
}

$shellCommand = "`"$launcherPath`" `"%1`""

# 3. Register for all files (*)
$fileKey = "HKCU:\Software\Classes\*\shell\GoogleQuickShare"
if (-not (Test-Path $fileKey)) {
    New-Item -Path $fileKey -Force | Out-Null
}
Set-ItemProperty -Path $fileKey -Name "(Default)" -Value "Send with Quick Share"
Set-ItemProperty -Path $fileKey -Name "Icon" -Value $iconPath

$fileCmdKey = "$fileKey\command"
if (-not (Test-Path $fileCmdKey)) {
    New-Item -Path $fileCmdKey -Force | Out-Null
}
Set-ItemProperty -Path $fileCmdKey -Name "(Default)" -Value $shellCommand

# 4. Register for folders (Directory)
$dirKey = "HKCU:\Software\Classes\Directory\shell\GoogleQuickShare"
if (-not (Test-Path $dirKey)) {
    New-Item -Path $dirKey -Force | Out-Null
}
Set-ItemProperty -Path $dirKey -Name "(Default)" -Value "Send with Quick Share"
Set-ItemProperty -Path $dirKey -Name "Icon" -Value $iconPath

$dirCmdKey = "$dirKey\command"
if (-not (Test-Path $dirCmdKey)) {
    New-Item -Path $dirCmdKey -Force | Out-Null
}
Set-ItemProperty -Path $dirCmdKey -Name "(Default)" -Value $shellCommand

Write-Host "[SUCCESS] Google Quick Share context menu registered successfully!" -ForegroundColor Green
Write-Host "You can now right-click any file or folder in File Explorer and choose 'Send with Quick Share'." -ForegroundColor Cyan
