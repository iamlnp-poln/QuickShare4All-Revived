$ErrorActionPreference = 'Continue'
$loc = (Get-AppxPackage *SamsungQuickShare*).InstallLocation
$dll = Join-Path $loc 'QuickShareCore\QuickShareCore.dll'

Write-Host "Inspecting: $dll"
$fs = [System.IO.File]::OpenRead($dll)
$pe = [System.Reflection.PortableExecutable.PEReader]::new($fs)
Write-Host "HasMetadata: $($pe.HasMetadata)"

if ($pe.HasMetadata) {
    $meta = [System.Reflection.Metadata.PEReaderExtensions]::GetMetadataReader($pe)
    Write-Host "TypeDefinitions count: $($meta.TypeDefinitions.Count)"
    
    $types = @()
    foreach ($h in $meta.TypeDefinitions) {
        $td = $meta.GetTypeDefinition($h)
        $name = $meta.GetString($td.Name)
        $ns = $meta.GetString($td.Namespace)
        $types += if ($ns) { "$ns.$name" } else { $name }
    }
    Write-Host "Classes in QuickShareCore:"
    $types | Sort-Object | ForEach-Object { Write-Host "  $_" }
}
$pe.Dispose()
$fs.Dispose()
