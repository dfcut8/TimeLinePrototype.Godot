param(
    [string]$Godot = 'C:/home/bin/Godot_v4.7.2-stable_win64/Godot_v4.7.2-stable_win64_console.exe',
    [switch]$Configurable
)
$ErrorActionPreference = 'Stop'
$reviewDir = Join-Path ([IO.Path]::GetTempPath()) ('rail-assembly-review-' + [guid]::NewGuid())
$previousAppData = $env:APPDATA
$assetRoot = Split-Path $PSScriptRoot
try {
    $env:APPDATA = $reviewDir
    foreach ($name in @('timeline_rail_housing','rail_recessed_light_insert','rail_module_joiner','timeline_start_cap','timeline_end_cap','furniture_review','rail_assembly_review')) {
        $target = Join-Path $reviewDir "assets/$name"
        New-Item -ItemType Directory $target -Force | Out-Null
        Get-ChildItem (Join-Path $assetRoot $name) -File |
            Where-Object { $_.Extension -in '.glb','.tscn','.gd' -or $_.Name -like '*.glb.import' } | Copy-Item -Destination $target
    }
    Set-Content (Join-Path $reviewDir 'project.godot') @'
config_version=5
[rendering]
renderer/rendering_method="forward_plus"
rendering_device/driver.windows="d3d12"
anti_aliasing/quality/msaa_3d=2
'@
    & $Godot --headless --path $reviewDir --editor --import --log-file (Join-Path $reviewDir 'import.log')
    if ($LASTEXITCODE -ne 0) { throw 'Import failed' }
    Get-ChildItem (Join-Path $reviewDir 'assets') -Recurse -Filter '*.glb.import' | ForEach-Object {
        $settings = [IO.File]::ReadAllText($_.FullName).Replace('meshes/force_disable_compression=false','meshes/force_disable_compression=true').Replace('meshes/generate_lods=true','meshes/generate_lods=false')
        [IO.File]::WriteAllText($_.FullName,$settings)
    }
    & $Godot --headless --path $reviewDir --editor --import --log-file (Join-Path $reviewDir 'reimport.log')
    if ($LASTEXITCODE -ne 0) { throw 'Reimport failed' }
    $runtimeGodot = $Godot -replace '_console.exe$', '.exe'
    $scriptName = if ($Configurable) { 'verify_configurable.gd' } else { 'verify_godot.gd' }
    $run = Start-Process -FilePath $runtimeGodot -ArgumentList '--path',$reviewDir,'--script',("res://assets/rail_assembly_review/$scriptName"),'--log-file',(Join-Path $reviewDir 'runtime.log') -WindowStyle Hidden -PassThru
    if (-not $run.WaitForExit(60000)) {
        Stop-Process -Id $run.Id
        throw "Validation timed out; logs at $reviewDir"
    }
    foreach ($name in @('rail_assembly_review')) {
        $destination = Join-Path $assetRoot $name
        Get-ChildItem (Join-Path $reviewDir "assets/$name") -File |
            Where-Object { $_.Name -like 'godot_*' -or $_.Name -like '*.glb.import' } | Copy-Item -Destination $destination
    }
    foreach ($log in @('import.log','reimport.log','runtime.log')) {
        $savedName = if ($Configurable) { "configurable_$log" } else { $log }
        Copy-Item (Join-Path $reviewDir $log) -Destination (Join-Path $PSScriptRoot $savedName)
    }
    if ($run.ExitCode -ne 0) { throw "Validation failed; logs at $reviewDir" }
    $reportName = if ($Configurable) { 'godot_configurable_validation.json' } else { 'godot_validation.json' }
    $report = Get-Content (Join-Path $PSScriptRoot $reportName) -Raw | ConvertFrom-Json
    if (-not $report.passed) { throw 'Runtime checks did not pass' }
    Write-Output "Review logs retained at $reviewDir"
} finally {
    $env:APPDATA = $previousAppData
}


