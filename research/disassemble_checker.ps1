$ErrorActionPreference = 'Stop'
$loc = (Get-AppxPackage *SamsungQuickShare*).InstallLocation
$dll = Join-Path $loc 'QuickShareCore\QuickShareCore.dll'

Add-Type -AssemblyName System.Reflection.Metadata

$fs = [System.IO.File]::OpenRead($dll)
$pe = [System.Reflection.PortableExecutable.PEReader]::new($fs)
$meta = [System.Reflection.Metadata.PEReaderExtensions]::GetMetadataReader($pe)

# Find DeviceModelSupportChecker
$targetType = $null
foreach ($h in $meta.TypeDefinitions) {
    $td = $meta.GetTypeDefinition($h)
    if ($meta.GetString($td.Name) -eq 'DeviceModelSupportChecker') {
        $targetType = $td
        break
    }
}

if (-not $targetType) {
    Write-Error "DeviceModelSupportChecker not found."
}

Write-Host "Disassembling methods of DeviceModelSupportChecker..." -ForegroundColor Cyan

foreach ($mh in $targetType.GetMethods()) {
    $m = $meta.GetMethodDefinition($mh)
    $mName = $meta.GetString($m.Name)
    
    if ($m.RelativeVirtualAddress -eq 0) {
        continue
    }
    
    Write-Host "`n--- Method: $mName (RVA: 0x$($m.RelativeVirtualAddress.ToString('X'))) ---" -ForegroundColor Yellow
    $body = [System.Reflection.Metadata.PEReaderExtensions]::GetMethodBody($pe, $m.RelativeVirtualAddress)
    $ilBytes = $body.GetILBytes()
    
    # Simple opcodes and string resolution
    $reader = [System.IO.BinaryReader]::new([System.IO.MemoryStream]::new($ilBytes))
    $offset = 0
    while ($reader.BaseStream.Position -lt $reader.BaseStream.Length) {
        $pos = $reader.BaseStream.Position
        $b = $reader.ReadByte()
        
        # Check for ldstr (0x72) followed by 4-byte string token
        if ($b -eq 0x72) {
            $token = $reader.ReadInt32()
            $userStringHandle = [System.Reflection.Metadata.Ecma335.MetadataTokens]::UserStringHandle($token)
            try {
                $str = $meta.GetUserString($userStringHandle)
                Write-Host "  +$($pos): ldstr `"$str`"" -ForegroundColor Green
            } catch {
                Write-Host "  +$($pos): ldstr <token: 0x$($token.ToString('X'))>" -ForegroundColor Gray
            }
        }
        # Check for call / callvirt (0x28, 0x6F)
        elseif ($b -eq 0x28 -or $b -eq 0x6F) {
            $token = $reader.ReadInt32()
            $op = if ($b -eq 0x28) { "call" } else { "callvirt" }
            Write-Host "  +$($pos): $op 0x$($token.ToString('X'))" -ForegroundColor DarkCyan
        }
        # Check for ldc.i4.0 (0x16) / ldc.i4.1 (0x17)
        elseif ($b -eq 0x16) {
            Write-Host "  +$($pos): ldc.i4.0 (false)" -ForegroundColor White
        }
        elseif ($b -eq 0x17) {
            Write-Host "  +$($pos): ldc.i4.1 (true)" -ForegroundColor White
        }
        # ret (0x2A)
        elseif ($b -eq 0x2A) {
            Write-Host "  +$($pos): ret" -ForegroundColor Red
        }
    }
}

$pe.Dispose()
$fs.Dispose()
