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
    if ($meta.GetString($td.Name) -eq 'DriverCheckManager') {
        $targetType = $td
        break
    }
}

Write-Host "Methods of DriverCheckManager:"
foreach ($mh in $targetType.GetMethods()) {
    $m = $meta.GetMethodDefinition($mh)
    $mName = $meta.GetString($m.Name)
    Write-Host "Method: $mName (RVA: 0x$($m.RelativeVirtualAddress.ToString('X')))"
    
    if ($m.RelativeVirtualAddress -ne 0) {
        $body = [System.Reflection.Metadata.PEReaderExtensions]::GetMethodBody($pe, $m.RelativeVirtualAddress)
        $il = $body.GetILBytes()
        $ms = [System.IO.MemoryStream]::new($il)
        $br = [System.IO.BinaryReader]::new($ms)
        while ($ms.Position -lt $ms.Length) {
            $pos = $ms.Position
            $b = $br.ReadByte()
            if ($b -eq 0x72) {
                $tok = $br.ReadInt32()
                $sh = [System.Reflection.Metadata.Ecma335.MetadataTokens]::UserStringHandle($tok)
                Write-Host "  +$($pos): ldstr `"$($meta.GetUserString($sh))`"" -ForegroundColor Green
            }
        }
    }
}

$pe.Dispose()
$fs.Dispose()
