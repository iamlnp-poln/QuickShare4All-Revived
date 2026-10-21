$ErrorActionPreference = 'Stop'
$loc = (Get-AppxPackage *SamsungQuickShare*).InstallLocation
$dll = Join-Path $loc 'QuickShareCore\QuickShareCore.dll'

Add-Type -AssemblyName System.Reflection.Metadata

$fs = [System.IO.File]::OpenRead($dll)
$pe = [System.Reflection.PortableExecutable.PEReader]::new($fs)
$meta = [System.Reflection.Metadata.PEReaderExtensions]::GetMetadataReader($pe)

# Find token of IsSamsungDevice and IsSupportedModel
$tokenIsSamsung = 0
$tokenIsSupported = 0

foreach ($h in $meta.TypeDefinitions) {
    $td = $meta.GetTypeDefinition($h)
    if ($meta.GetString($td.Name) -eq 'DeviceModelSupportChecker') {
        foreach ($mh in $td.GetMethods()) {
            $m = $meta.GetMethodDefinition($mh)
            $name = $meta.GetString($m.Name)
            $tok = [System.Reflection.Metadata.Ecma335.MetadataTokens]::GetToken($meta, [System.Reflection.Metadata.EntityHandle]$mh)
            if ($name -eq 'IsSamsungDevice') { $tokenIsSamsung = $tok; Write-Host "IsSamsungDevice token: 0x$($tok.ToString('X8'))" }
            if ($name -eq 'IsSupportedModel') { $tokenIsSupported = $tok; Write-Host "IsSupportedModel token: 0x$($tok.ToString('X8'))" }
        }
    }
}

# Scan all methods in the assembly to see who calls them
Write-Host "`nScanning callers..."
foreach ($h in $meta.TypeDefinitions) {
    $td = $meta.GetTypeDefinition($h)
    $cName = $meta.GetString($td.Name)
    $cNs = $meta.GetString($td.Namespace)
    
    foreach ($mh in $td.GetMethods()) {
        $m = $meta.GetMethodDefinition($mh)
        if ($m.RelativeVirtualAddress -eq 0) { continue }
        
        $body = [System.Reflection.Metadata.PEReaderExtensions]::GetMethodBody($pe, $m.RelativeVirtualAddress)
        $il = $body.GetILBytes()
        $ms = [System.IO.MemoryStream]::new($il)
        $br = [System.IO.BinaryReader]::new($ms)
        
        while ($ms.Position -lt $ms.Length - 4) {
            $op = $br.ReadByte()
            if ($op -in @(0x28, 0x6F)) {
                $callTok = $br.ReadInt32()
                if ($callTok -eq $tokenIsSamsung) {
                    Write-Host "Caller of IsSamsungDevice: $cNs.$cName :: $($meta.GetString($m.Name))" -ForegroundColor Green
                }
                if ($callTok -eq $tokenIsSupported) {
                    Write-Host "Caller of IsSupportedModel: $cNs.$cName :: $($meta.GetString($m.Name))" -ForegroundColor Yellow
                }
            }
        }
    }
}

$pe.Dispose()
$fs.Dispose()
