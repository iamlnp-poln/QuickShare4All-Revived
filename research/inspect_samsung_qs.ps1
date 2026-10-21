$ErrorActionPreference = 'Stop'

$appx = Get-AppxPackage *SamsungQuickShare*
if (-not $appx) {
    Write-Error "Samsung Quick Share is not installed."
}

$loc = $appx.InstallLocation
Write-Host "Samsung Quick Share Install Location: $loc"

Add-Type -AssemblyName System.Reflection.Metadata -ErrorAction SilentlyContinue
Add-Type -AssemblyName System.IO.MemoryMappedFiles -ErrorAction SilentlyContinue

$files = Get-ChildItem -Path $loc -Recurse -Include "*.dll","*.exe" -ErrorAction SilentlyContinue
Write-Host "Total DLLs and EXEs found: $($files.Count)"

foreach ($dll in $files) {
    try {
        $fs = [System.IO.File]::OpenRead($dll.FullName)
        $pe = [System.Reflection.PortableExecutable.PEReader]::new($fs)
        if ($pe.HasMetadata) {
            $reader = $pe.GetMetadataReader()
            $interesting = @()
            foreach ($th in $reader.TypeDefinitions) {
                $type = $reader.GetTypeDefinition($th)
                $tName = $reader.GetString($type.Name)
                $tNs = $reader.GetString($type.Namespace)
                if ($tName -match 'Device|Hardware|Model|Samsung|Bios|Check|System|Support|Validate|Wmi|Capability') {
                    $interesting += "$tNs.$tName"
                }
            }
            if ($interesting.Count -gt 0) {
                Write-Host "`n=== Assembly: $($dll.Name) (Matched $($interesting.Count) types) ===" -ForegroundColor Cyan
                $interesting | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" }
            }
        }
        $pe.Dispose()
        $fs.Dispose()
    } catch {
        # Not a managed PE or failed to read
    }
}
