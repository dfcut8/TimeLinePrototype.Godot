param(
    [string]$Godot = 'C:/home/bin/Godot_v4.7.2-stable_win64/Godot_v4.7.2-stable_win64_console.exe',
    [string]$Asset = 'event_socket',
    [ValidateSet('gl_compatibility','forward_plus')][string]$Renderer = 'gl_compatibility'
)
$ErrorActionPreference = 'Stop'
$reviewDir = Join-Path ([IO.Path]::GetTempPath()) ('event-review-' + [guid]::NewGuid())
$previousAppData = $env:APPDATA
$assetRoot = Split-Path $PSScriptRoot
$destination = Join-Path $assetRoot $Asset
try {
    $env:APPDATA = $reviewDir
    $names = @('timeline_rail_housing', 'rail_recessed_light_insert', 'event_socket')
    if ($Asset -ne 'event_socket') { $names += $Asset }
    foreach ($name in $names) {
        $target = Join-Path $reviewDir "assets/$name"
        New-Item -ItemType Directory $target -Force | Out-Null
        Get-ChildItem (Join-Path $assetRoot $name) -File |
            Where-Object { $_.Extension -in '.glb', '.tscn', '.gd' } | Copy-Item -Destination $target
    }
    Set-Content (Join-Path $reviewDir 'project.godot') @"
config_version=5
[rendering]
renderer/rendering_method="$Renderer"
rendering_device/driver.windows="d3d12"
"@
    & $Godot --headless --path $reviewDir --editor --import --log-file (Join-Path $reviewDir 'import.log')
    if ($LASTEXITCODE -ne 0) { throw 'Import failed' }
    Get-ChildItem (Join-Path $reviewDir 'assets') -Recurse -Filter '*.glb.import' | ForEach-Object {
        $settings = [IO.File]::ReadAllText($_.FullName).Replace('meshes/force_disable_compression=false', 'meshes/force_disable_compression=true').Replace('meshes/generate_lods=true', 'meshes/generate_lods=false')
        [IO.File]::WriteAllText($_.FullName, $settings)
    }
    & $Godot --headless --path $reviewDir --editor --import --log-file (Join-Path $reviewDir 'reimport.log')
    if ($LASTEXITCODE -ne 0) { throw 'Reimport failed' }
    $run = Start-Process -FilePath $Godot -ArgumentList '--path', $reviewDir, '--script', "res://assets/$Asset/verify_godot.gd", '--log-file', (Join-Path $reviewDir 'runtime.log') -WindowStyle Hidden -PassThru
    if (-not $run.WaitForExit(60000)) {
        Stop-Process -Id $run.Id
        throw "Validation timed out; logs at $reviewDir"
    }
    Get-ChildItem (Join-Path $reviewDir "assets/$Asset") -File |
        Where-Object { $_.Name -like 'godot_*' -or $_.Name -like '*.glb.import' } | Copy-Item -Destination $destination
    Copy-Item (Join-Path $reviewDir 'import.log'), (Join-Path $reviewDir 'reimport.log'), (Join-Path $reviewDir 'runtime.log') -Destination $destination
    if ($run.ExitCode -ne 0) { throw "Validation failed; logs at $reviewDir" }
    Write-Output "Review logs retained at $reviewDir"
} finally {
    $env:APPDATA = $previousAppData
}
