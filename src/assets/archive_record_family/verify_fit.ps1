param([string]$Godot = 'C:/home/bin/Godot_v4.7.2-stable_win64/Godot_v4.7.2-stable_win64_console.exe')
$ErrorActionPreference = 'Stop'
$reviewDir = Join-Path ([IO.Path]::GetTempPath()) ('cassette-family-review-' + [guid]::NewGuid())
$previousAppData = $env:APPDATA
$assetRoot = Split-Path $PSScriptRoot
try {
    $env:APPDATA = $reviewDir
    foreach ($name in @('timeline_rail_housing','archive_record_small','archive_record_medium','archive_record_large','archive_record_family','record_stack_shelf_bay','archive_display_plinth','shelf_light_channel')) {
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
    & $Godot --headless --path $reviewDir --editor --import --log-file (Join-Path $reviewDir 'fit_import.log')
    if ($LASTEXITCODE -ne 0) { throw 'Import failed' }
    Get-ChildItem (Join-Path $reviewDir 'assets') -Recurse -Filter '*.glb.import' | ForEach-Object {
        $settings = [IO.File]::ReadAllText($_.FullName).Replace('meshes/force_disable_compression=false','meshes/force_disable_compression=true').Replace('meshes/generate_lods=true','meshes/generate_lods=false')
        [IO.File]::WriteAllText($_.FullName,$settings)
    }
    & $Godot --headless --path $reviewDir --editor --import --log-file (Join-Path $reviewDir 'fit_reimport.log')
    if ($LASTEXITCODE -ne 0) { throw 'Reimport failed' }
    $run = Start-Process -FilePath $Godot -ArgumentList '--path',$reviewDir,'--script','res://assets/archive_record_family/verify_fit.gd','--log-file',(Join-Path $reviewDir 'fit_runtime.log') -WindowStyle Hidden -PassThru
    if (-not $run.WaitForExit(60000)) {
        Stop-Process -Id $run.Id
        throw "Validation timed out; logs at $reviewDir"
    }
    foreach ($name in @('archive_record_small','archive_record_large','archive_record_family','record_stack_shelf_bay','archive_display_plinth')) {
        $destination = Join-Path $assetRoot $name
        Get-ChildItem (Join-Path $reviewDir "assets/$name") -File |
            Where-Object { $_.Name -like 'godot_*' -or $_.Name -like '*.glb.import' } | Copy-Item -Destination $destination
    }
    Copy-Item (Join-Path $reviewDir 'fit_import.log'),(Join-Path $reviewDir 'fit_reimport.log'),(Join-Path $reviewDir 'fit_runtime.log') -Destination $PSScriptRoot
    if ($run.ExitCode -ne 0) { throw "Validation failed; logs at $reviewDir" }
    $report = Get-Content (Join-Path $PSScriptRoot 'godot_fit_validation.json') -Raw | ConvertFrom-Json
    if (-not $report.passed) { throw 'Runtime checks did not pass' }
    Write-Output "Review logs retained at $reviewDir"
} finally {
    $env:APPDATA = $previousAppData
}


