param([string]$Godot = 'C:/home/bin/Godot_v4.7.2-stable_win64/Godot_v4.7.2-stable_win64_console.exe')
$ErrorActionPreference = 'Stop'
$reviewDir = Join-Path ([IO.Path]::GetTempPath()) ('pier1617-' + [guid]::NewGuid())
$previousAppData = $env:APPDATA
try {
    $env:APPDATA = $reviewDir
    foreach ($name in 'structural_pier_a','structural_pier_b','structural_pier_family','curved_gallery') {
        $target = Join-Path $reviewDir "assets/$name"
        New-Item -ItemType Directory $target -Force | Out-Null
        Get-ChildItem (Join-Path (Split-Path $PSScriptRoot) $name) -File |
            Where-Object { $_.Extension -in '.glb','.tscn','.gd','.import' } | Copy-Item -Destination $target
    }
    Set-Content (Join-Path $reviewDir 'project.godot') @'
config_version=5
[rendering]
renderer/rendering_method="gl_compatibility"
'@
    & $Godot --headless --path $reviewDir --editor --import --log-file (Join-Path $reviewDir 'import.log')
    if ($LASTEXITCODE -ne 0) { throw 'Import failed' }
    Get-ChildItem (Join-Path $reviewDir 'assets') -Recurse -Filter '*.glb.import' | ForEach-Object {
        $settings = [IO.File]::ReadAllText($_.FullName).Replace('meshes/force_disable_compression=false','meshes/force_disable_compression=true').Replace('meshes/generate_lods=true','meshes/generate_lods=false')
        [IO.File]::WriteAllText($_.FullName,$settings)
    }
    & $Godot --headless --path $reviewDir --editor --import --log-file (Join-Path $reviewDir 'reimport.log')
    if ($LASTEXITCODE -ne 0) { throw 'Reimport failed' }
    $run = Start-Process -FilePath $Godot -ArgumentList '--path',$reviewDir,'--script','res://assets/structural_pier_family/verify_godot.gd','--log-file',(Join-Path $reviewDir 'runtime.log') -WindowStyle Hidden -PassThru
    if (-not $run.WaitForExit(60000)) { Stop-Process -Id $run.Id; throw "Validation timeout: $reviewDir" }
    Get-ChildItem (Join-Path $reviewDir 'assets/structural_pier_family') -File |
        Where-Object Name -Like 'godot_*' | Copy-Item -Destination $PSScriptRoot
    foreach ($name in 'structural_pier_a','structural_pier_b') {
        Get-ChildItem (Join-Path $reviewDir "assets/$name") -Filter '*.glb.import' | Copy-Item -Destination (Join-Path (Split-Path $PSScriptRoot) $name)
    }
    Copy-Item (Join-Path $reviewDir 'import.log'),(Join-Path $reviewDir 'reimport.log'),(Join-Path $reviewDir 'runtime.log') -Destination $PSScriptRoot
    Write-Output "Review logs retained at $reviewDir"
    if ($run.ExitCode -ne 0) { throw 'Validation failed; see runtime.log' }
} finally {
    $env:APPDATA=$previousAppData
}
