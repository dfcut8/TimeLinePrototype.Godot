param([string]$Godot = 'C:/home/bin/Godot_v4.7.2-stable_win64/Godot_v4.7.2-stable_win64_console.exe')
$ErrorActionPreference = 'Stop'
$reviewDir = Join-Path ([IO.Path]::GetTempPath()) ('rail5-' + [guid]::NewGuid())
$assetDir = Join-Path $reviewDir 'assets/timeline_rail_housing'
New-Item -ItemType Directory $assetDir -Force | Out-Null
$previousAppData = $env:APPDATA
try {
    $env:APPDATA = $reviewDir
    Get-ChildItem -LiteralPath $PSScriptRoot -File | Where-Object { $_.Extension -in '.glb', '.tscn', '.gd' } | Copy-Item -Destination $assetDir
    Set-Content (Join-Path $reviewDir 'project.godot') @'
config_version=5
[rendering]
renderer/rendering_method="gl_compatibility"
'@
    & $Godot --headless --path $reviewDir --editor --import --log-file (Join-Path $reviewDir 'import.log')
    if ($LASTEXITCODE -ne 0) { throw 'Godot import failed' }
    $settings = Join-Path $assetDir 'timeline_rail_housing.glb.import'
    $text = [IO.File]::ReadAllText($settings).Replace('meshes/force_disable_compression=false', 'meshes/force_disable_compression=true').Replace('meshes/generate_lods=true', 'meshes/generate_lods=false')
    [IO.File]::WriteAllText($settings, $text)
    & $Godot --headless --path $reviewDir --editor --import --log-file (Join-Path $reviewDir 'reimport.log')
    if ($LASTEXITCODE -ne 0) { throw 'Godot reimport failed' }
    $run = Start-Process -FilePath $Godot -ArgumentList '--path', $reviewDir, '--script', 'res://assets/timeline_rail_housing/verify_godot.gd', '--log-file', (Join-Path $reviewDir 'runtime.log') -WindowStyle Hidden -PassThru
    if (-not $run.WaitForExit(60000)) { throw "Validation exceeded 60 seconds; process $($run.Id); logs at $reviewDir" }
    if ($run.ExitCode -ne 0) { throw "Godot runtime validation failed; logs at $reviewDir" }
    Get-ChildItem -LiteralPath $assetDir -File | Where-Object { $_.Name -like 'godot_*' -or $_.Name -eq 'timeline_rail_housing.glb.import' } | Copy-Item -Destination $PSScriptRoot
    Copy-Item (Join-Path $reviewDir 'import.log'), (Join-Path $reviewDir 'reimport.log'), (Join-Path $reviewDir 'runtime.log') -Destination $PSScriptRoot
    Write-Output "Review logs retained at $reviewDir"
} finally {
    $env:APPDATA = $previousAppData
}
