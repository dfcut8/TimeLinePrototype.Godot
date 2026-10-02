param([string]$Godot = 'C:/home/bin/Godot_v4.7.2-stable_win64/Godot_v4.7.2-stable_win64_console.exe')
$ErrorActionPreference = 'Stop'
$reviewDir = Join-Path ([IO.Path]::GetTempPath()) ('library-room-review-' + [guid]::NewGuid())
$previousAppData = $env:APPDATA
$assetRoot = Split-Path $PSScriptRoot
try {
    $env:APPDATA = $reviewDir
    $files = @{
        library_room_review = @('library_room_assembly.tscn','review_room.tscn','room_review_rig.tscn','verify_room.gd')
        wall_portal_review = @('review_rig.tscn','verify_godot.gd')
        archive_record_small = @('shelf_assembly.tscn')
        archive_record_large = @('shelf_assembly.tscn')
        record_stack_shelf_bay = @('illuminated_shelf_bay.tscn')
        timeline_rail_housing = @('configurable_timeline_rail.tscn','configurable_timeline_rail.gd')
        rail_module_joiner = @('illuminated_rail_module.tscn')
    }
    foreach ($name in @('wall_infill_bay','passage_portal_bay_frame','window_bay_frame','structural_pier_a','archive_record_small','archive_record_large','record_stack_shelf_bay','shelf_light_channel','timeline_rail_housing','timeline_start_cap','timeline_end_cap','rail_module_joiner','rail_recessed_light_insert')) {
        $files[$name] = @($files[$name]) + @("$name.tscn","$name.glb","$name.glb.import")
    }
    foreach ($name in $files.Keys) {
        $target = Join-Path $reviewDir "assets/$name"
        New-Item -ItemType Directory $target -Force | Out-Null
        foreach ($file in $files[$name]) {
            if ($file) { Copy-Item -LiteralPath (Join-Path $assetRoot "$name/$file") -Destination $target }
        }
    }
    Set-Content (Join-Path $reviewDir 'project.godot') @'
config_version=5
[application]
run/main_scene="res://assets/library_room_review/review_room.tscn"
[rendering]
renderer/rendering_method="forward_plus"
rendering_device/driver.windows="d3d12"
anti_aliasing/quality/msaa_3d=2
'@
    & $Godot --headless --path $reviewDir --editor --import --log-file (Join-Path $reviewDir 'room_import.log')
    if ($LASTEXITCODE -ne 0) { throw 'Room import failed' }
    $runtimeGodot = $Godot -replace '_console.exe$', '.exe'
    $run = Start-Process -FilePath $runtimeGodot -ArgumentList '--path',$reviewDir,'--script','res://assets/library_room_review/verify_room.gd','--log-file',(Join-Path $reviewDir 'room_runtime.log') -WindowStyle Hidden -PassThru
    if (-not $run.WaitForExit(60000)) {
        Stop-Process -Id $run.Id
        throw "Validation timed out; logs at $reviewDir"
    }
    Copy-Item (Join-Path $reviewDir 'room_import.log'),(Join-Path $reviewDir 'room_runtime.log') -Destination $PSScriptRoot
    if ($run.ExitCode -ne 0) { throw "Validation failed; logs at $reviewDir" }
    $report = Get-Content (Join-Path $reviewDir 'assets/library_room_review/godot_room_validation.json') -Raw | ConvertFrom-Json
    if (-not $report.passed) { throw 'Room runtime checks did not pass' }
    Get-ChildItem (Join-Path $reviewDir 'assets/library_room_review') -Filter 'godot_room_*' | Copy-Item -Destination $PSScriptRoot
    Write-Output "Review project and logs retained at $reviewDir"
} finally {
    $env:APPDATA = $previousAppData
}
