$ErrorActionPreference = 'Stop'
$loc = (Get-AppxPackage *SamsungQuickShare*).InstallLocation
$dll = Join-Path $loc 'QuickShareCore\QuickShareCore.dll'

Add-Type -AssemblyName System.Reflection.Metadata

$fs = [System.IO.File]::OpenRead($dll)
$pe = [System.Reflection.PortableExecutable.PEReader]::new($fs)
$meta = [System.Reflection.Metadata.PEReaderExtensions]::GetMetadataReader($pe)

$targetType = $null
foreach ($h in $meta.TypeDefinitions) {
    $td = $meta.GetTypeDefinition($h)
    if ($meta.GetString($td.Name) -eq 'DeviceModelSupportChecker') {
        $targetType = $td
        break
    }
}

function Dump-Method($mName) {
    foreach ($mh in $targetType.GetMethods()) {
        $m = $meta.GetMethodDefinition($mh)
        if ($meta.GetString($m.Name) -eq $mName) {
            Write-Host "`n=================== $mName ===================" -ForegroundColor Cyan
            $body = [System.Reflection.Metadata.PEReaderExtensions]::GetMethodBody($pe, $m.RelativeVirtualAddress)
            $il = $body.GetILBytes()
            
            $ms = [System.IO.MemoryStream]::new($il)
            $br = [System.IO.BinaryReader]::new($ms)
            
            while ($ms.Position -lt $ms.Length) {
                $pos = $ms.Position
                $op = $br.ReadByte()
                $opHex = "0x" + $op.ToString("X2")
                
                if ($op -eq 0x72) {
                    $tok = $br.ReadInt32()
                    $strHandle = [System.Reflection.Metadata.Ecma335.MetadataTokens]::UserStringHandle($tok)
                    $s = try { $meta.GetUserString($strHandle) } catch { "" }
                    Write-Host ("{0:D4}: {1} ldstr `"{2}`"" -f $pos, $opHex, $s) -ForegroundColor Green
                } elseif ($op -in @(0x28, 0x6F)) {
                    $tok = $br.ReadInt32()
                    $callType = if ($op -eq 0x28) { "call" } else { "callvirt" }
                    Write-Host ("{0:D4}: {1} {2} tok:0x{3:X8}" -f $pos, $opHex, $callType, $tok) -ForegroundColor Yellow
                } elseif ($op -in @(0x7E, 0x7B, 0x80, 0x7D)) {
                    $tok = $br.ReadInt32()
                    Write-Host ("{0:D4}: {1} field-op tok:0x{2:X8}" -f $pos, $opHex, $tok) -ForegroundColor DarkYellow
                } elseif ($op -in @(0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F, 0x30, 0x31, 0x32)) {
                    $target = if ($op -ge 0x38 -and $op -le 0x3F) { $br.ReadInt32() + $ms.Position } else { [sbyte]$br.ReadByte() + $ms.Position }
                    Write-Host ("{0:D4}: {1} br/cond -> {2:D4}" -f $pos, $opHex, $target) -ForegroundColor Magenta
                } elseif ($op -eq 0x2A) {
                    Write-Host ("{0:D4}: {1} ret" -f $pos, $opHex) -ForegroundColor Red
                } else {
                    Write-Host ("{0:D4}: {1}" -f $pos, $opHex)
                }
            }
            break
        }
    }
}

Dump-Method '.cctor'
Dump-Method 'IsNonSamsungDeviceSupported'
Dump-Method 'IsSamsungDevice'
Dump-Method 'IsSupportedModel'

$pe.Dispose()
$fs.Dispose()
