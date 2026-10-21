#Requires -Version 5.1
<#
.SYNOPSIS
    Removes "Send with Quick Share" for Google Quick Share from Windows File Explorer context menu.
#>

$ErrorActionPreference = 'SilentlyContinue'

Remove-Item -Path "HKCU:\Software\Classes\*\shell\GoogleQuickShare" -Recurse -Force
Remove-Item -Path "HKCU:\Software\Classes\Directory\shell\GoogleQuickShare" -Recurse -Force

Write-Host "[SUCCESS] Google Quick Share context menu entries removed." -ForegroundColor Green
