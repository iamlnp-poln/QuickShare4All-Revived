#Requires -Version 7.0
<#
.SYNOPSIS
    Removes "Share with Quick Share" from Windows File Explorer context menu.
#>

$ErrorActionPreference = 'SilentlyContinue'

Remove-Item -Path "HKCU:\Software\Classes\*\shell\SamsungQuickShare" -Recurse -Force
Remove-Item -Path "HKCU:\Software\Classes\Directory\shell\SamsungQuickShare" -Recurse -Force

Write-Host "[SUCCESS] Context menu entries removed." -ForegroundColor Green
