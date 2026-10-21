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
    if ($meta.GetString($td.Name) -eq 'App' -and $meta.GetString($td.Namespace) -eq 'QSSystray') {
        $targetType = $td
        break
    }
}

Write-Host "Methods in QSSystray.App:"
foreach ($mh in $targetType.GetMethods()) {
    $m = $meta.GetMethodDefinition($mh)
    $mName = $meta.GetString($m.Name)
    Write-Host "`nMethod: $mName"
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
            } elseif ($b -in @(0x28, 0x6F)) {
                $tok = $br.ReadInt32()
                $handle = [System.Reflection.Metadata.Ecma335.MetadataTokens]::Handle($tok)
                if ($handle.Kind -eq 'MemberReference') {
                    $mr = $meta.GetMemberReference($handle)
                    Write-Host "  +$($pos): call $($meta.GetString($mr.Name))" -ForegroundColor Cyan
                }
            }
        }
    }
}

$pe.Dispose()
$fs.Dispose()
