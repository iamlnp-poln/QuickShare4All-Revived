#Requires -Version 5.1
<#
.SYNOPSIS
    Registers "Share with Quick Share" into Windows File Explorer context menu (per-user, no admin required).
#>

$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$vbsPath = Join-Path $scriptDir "send_to_quickshare.vbs"

if (-not (Test-Path $vbsPath)) {
    Write-Error "send_to_quickshare.vbs not found at $vbsPath"
}

# 1. Discover Samsung Quick Share install location via user AppModel repository
$iconPath = ""
$appRepo = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\Repository\Packages"
$pkgItem = Get-ChildItem -Path $appRepo -ErrorAction SilentlyContinue | 
           Where-Object { $_.PSChildName -like "*SamsungQuickShare*" } | 
           Select-Object -First 1

if ($pkgItem) {
    $prop = Get-ItemProperty -Path $pkgItem.PSPath -ErrorAction SilentlyContinue
    if ($prop -and $prop.PackageRootFolder) {
        $root = $prop.PackageRootFolder
        $candidates = @(
            (Join-Path $root "Assets\AppList.targetsize-32.png"),
            (Join-Path $root "Assets\AppList.scale-100.png"),
            (Join-Path $root "QuickShare.exe")
        )
        foreach ($c in $candidates) {
            if (Test-Path $c) {
                $iconPath = $c
                break
            }
        }
    }
}

$shellCommand = "wscript.exe `"$vbsPath`" `"%1`""

# 2. Register context menu for all files (*)
$fileKey = "HKCU:\Software\Classes\*\shell\SamsungQuickShare"
if (-not (Test-Path $fileKey)) {
    New-Item -Path $fileKey -Force | Out-Null
}
Set-ItemProperty -Path $fileKey -Name "(Default)" -Value "Share with Quick Share"
if ($iconPath) {
    Set-ItemProperty -Path $fileKey -Name "Icon" -Value $iconPath
}
$fileCmdKey = "$fileKey\command"
if (-not (Test-Path $fileCmdKey)) {
    New-Item -Path $fileCmdKey -Force | Out-Null
}
Set-ItemProperty -Path $fileCmdKey -Name "(Default)" -Value $shellCommand

# 3. Register context menu for folders (Directory)
$dirKey = "HKCU:\Software\Classes\Directory\shell\SamsungQuickShare"
if (-not (Test-Path $dirKey)) {
    New-Item -Path $dirKey -Force | Out-Null
}
Set-ItemProperty -Path $dirKey -Name "(Default)" -Value "Share with Quick Share"
if ($iconPath) {
    Set-ItemProperty -Path $dirKey -Name "Icon" -Value $iconPath
}
$dirCmdKey = "$dirKey\command"
if (-not (Test-Path $dirCmdKey)) {
    New-Item -Path $dirCmdKey -Force | Out-Null
}
Set-ItemProperty -Path $dirCmdKey -Name "(Default)" -Value $shellCommand

Write-Host "[SUCCESS] 'Share with Quick Share' context menu installed successfully!" -ForegroundColor Green
Write-Host "You can now right-click any file or folder in File Explorer and choose 'Share with Quick Share'." -ForegroundColor Cyan
