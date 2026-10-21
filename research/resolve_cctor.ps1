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

foreach ($mh in $targetType.GetMethods()) {
    $m = $meta.GetMethodDefinition($mh)
    $mName = $meta.GetString($m.Name)
    if ($mName -in @('.cctor', 'IsNonSamsungDeviceSupported', 'IsSamsungDevice', 'IsSupportedModel')) {
        Write-Host "`n=== Method: $mName ===" -ForegroundColor Cyan
        $body = [System.Reflection.Metadata.PEReaderExtensions]::GetMethodBody($pe, $m.RelativeVirtualAddress)
        $il = $body.GetILBytes()
        $ms = [System.IO.MemoryStream]::new($il)
        $br = [System.IO.BinaryReader]::new($ms)
        
        while ($ms.Position -lt $ms.Length) {
            $pos = $ms.Position
            $b = $br.ReadByte()
            if ($b -in @(0x28, 0x6F)) {
                $tok = $br.ReadInt32()
                $handle = [System.Reflection.Metadata.Ecma335.MetadataTokens]::Handle($tok)
                $methodName = ""
                $className = ""
                if ($handle.Kind -eq 'MemberReference') {
                    $mr = $meta.GetMemberReference($handle)
                    $methodName = $meta.GetString($mr.Name)
                    $parentHandle = $mr.Parent
                    if ($parentHandle.Kind -eq 'TypeReference') {
                        $tr = $meta.GetTypeReference($parentHandle)
                        $className = $meta.GetString($tr.Name)
                    }
                }
                Write-Host ("{0:D4}: call {1}::{2} (0x{3:X8})" -f $pos, $className, $methodName, $tok)
            } elseif ($b -eq 0x72) {
                $tok = $br.ReadInt32()
                $strHandle = [System.Reflection.Metadata.Ecma335.MetadataTokens]::UserStringHandle($tok)
                $str = $meta.GetUserString($strHandle)
                Write-Host ("{0:D4}: ldstr `"{1}`"" -f $pos, $str)
            }
        }
    }
}

$pe.Dispose()
$fs.Dispose()
