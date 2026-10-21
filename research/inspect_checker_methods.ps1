$ErrorActionPreference = 'Stop'
$loc = (Get-AppxPackage *SamsungQuickShare*).InstallLocation
$dll = Join-Path $loc 'QuickShareCore\QuickShareCore.dll'

Add-Type -AssemblyName System.Reflection.Metadata

$fs = [System.IO.File]::OpenRead($dll)
$pe = [System.Reflection.PortableExecutable.PEReader]::new($fs)
$meta = [System.Reflection.Metadata.PEReaderExtensions]::GetMetadataReader($pe)

$targetClasses = @(
    'DeviceModelSupportChecker',
    'DriverCheckManager',
    'DriverModelVersionChecker',
    'DeveloperToolHelper',
    'RegistryKeyManager'
)

foreach ($h in $meta.TypeDefinitions) {
    $td = $meta.GetTypeDefinition($h)
    $name = $meta.GetString($td.Name)
    if ($targetClasses -contains $name) {
        $ns = $meta.GetString($td.Namespace)
        Write-Host "`n===============================================" -ForegroundColor Yellow
        Write-Host "Class: $ns.$name" -ForegroundColor Green
        Write-Host "-----------------------------------------------"
        
        Write-Host "Fields:"
        foreach ($fh in $td.GetFields()) {
            $f = $meta.GetFieldDefinition($fh)
            $fName = $meta.GetString($f.Name)
            Write-Host "  [Field] $fName"
        }
        
        Write-Host "Methods:"
        foreach ($mh in $td.GetMethods()) {
            $m = $meta.GetMethodDefinition($mh)
            $mName = $meta.GetString($m.Name)
            Write-Host "  [Method] $mName"
        }
    }
}

$pe.Dispose()
$fs.Dispose()
