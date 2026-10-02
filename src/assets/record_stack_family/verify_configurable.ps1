param([string]$Godot = 'C:/home/bin/Godot_v4.7.2-stable_win64/Godot_v4.7.2-stable_win64_console.exe')
$ErrorActionPreference = 'Stop'
$reviewDir = Join-Path ([IO.Path]::GetTempPath()) ('shelf-row-review-' + [guid]::NewGuid())
$previousAppData = $env:APPDATA
$assetRoot = Split-Path $PSScriptRoot
try {
    $env:APPDATA = $reviewDir
    $files = @{
        record_stack_shelf_bay = @('record_stack_shelf_bay.glb','record_stack_shelf_bay.glb.import','record_stack_shelf_bay.tscn','illuminated_shelf_bay.tscn')
        record_stack_end_cap = @('record_stack_end_cap.glb','record_stack_end_cap.glb.import','record_stack_end_cap.tscn','configurable_shelf_row.gd','configurable_shelf_row.tscn')
        shelf_light_channel = @('shelf_light_channel.glb','shelf_light_channel.glb.import','shelf_light_channel.tscn')
        furniture_review = @('review_rig.tscn')
        record_stack_family = @('review_configurable.tscn','verify_configurable.gd')
    }
    foreach ($name in $files.Keys) {
        $target = Join-Path $reviewDir "assets/$name"
        New-Item -ItemType Directory $target -Force | Out-Null
        foreach ($file in $files[$name]) {
            Copy-Item (Join-Path $assetRoot "$name/$file") -Destination $target
        }
    }
    Set-Content (Join-Path $reviewDir 'project.godot') @'
config_version=5
[rendering]
renderer/rendering_method="forward_plus"
rendering_device/driver.windows="d3d12"
anti_aliasing/quality/msaa_3d=2
'@
    & $Godot --headless --path $reviewDir --editor --import --log-file (Join-Path $reviewDir 'configurable_import.log')
    if ($LASTEXITCODE -ne 0) { throw 'Import failed' }
    $runtimeGodot = $Godot -replace '_console.exe$', '.exe'
    $run = Start-Process -FilePath $runtimeGodot -ArgumentList '--path',$reviewDir,'--script','res://assets/record_stack_family/verify_configurable.gd','--log-file',(Join-Path $reviewDir 'configurable_runtime.log') -WindowStyle Hidden -PassThru
    if (-not $run.WaitForExit(60000)) {
        Stop-Process -Id $run.Id
        throw "Validation timed out; logs at $reviewDir"
    }
    Copy-Item (Join-Path $reviewDir 'configurable_import.log'),(Join-Path $reviewDir 'configurable_runtime.log') -Destination $PSScriptRoot
    if ($run.ExitCode -ne 0) { throw "Validation failed; logs at $reviewDir" }
    $reportPath = Join-Path $reviewDir 'assets/record_stack_family/godot_configurable_validation.json'
    $report = Get-Content $reportPath -Raw | ConvertFrom-Json
    if (-not $report.passed) { throw 'Runtime checks did not pass' }
    Get-ChildItem (Join-Path $reviewDir 'assets/record_stack_family') -Filter 'godot_configurable_*' | Copy-Item -Destination $PSScriptRoot
    Write-Output "Review logs retained at $reviewDir"
} finally {
    $env:APPDATA = $previousAppData
}
