param([string]$Godot = 'C:/home/bin/Godot_v4.7.2-stable_win64/Godot_v4.7.2-stable_win64_console.exe')
$ErrorActionPreference = 'Stop'
$reviewDir = Join-Path ([IO.Path]::GetTempPath()) ('gallery19-' + [guid]::NewGuid())
New-Item -ItemType Directory $reviewDir | Out-Null
$previousAppData = $env:APPDATA
try {
    # Keep editor settings and logs out of the user's installed editor profile.
    $env:APPDATA = $reviewDir
    Copy-Item (Join-Path $PSScriptRoot 'curved_gallery.glb'), (Join-Path $PSScriptRoot 'verify_godot.gd') $reviewDir
    Set-Content (Join-Path $reviewDir 'project.godot') 'config_version=5'
    & $Godot --headless --path $reviewDir --editor --import --log-file (Join-Path $reviewDir 'import.log')
    if ($LASTEXITCODE -ne 0) { throw 'Godot import failed' }
    $settings = Join-Path $reviewDir 'curved_gallery.glb.import'
    $text = [IO.File]::ReadAllText($settings).Replace('meshes/force_disable_compression=false', 'meshes/force_disable_compression=true').Replace('meshes/generate_lods=true', 'meshes/generate_lods=false')
    [IO.File]::WriteAllText($settings, $text)
    # Invalidate only this isolated project's generated mesh cache.
    Get-ChildItem -LiteralPath (Join-Path $reviewDir '.godot/imported') -File | Where-Object { $_.Name -like 'curved_gallery.glb-*' } | Remove-Item
    & $Godot --headless --path $reviewDir --editor --import --log-file (Join-Path $reviewDir 'reimport.log')
    if ($LASTEXITCODE -ne 0) { throw 'Godot precise-mesh reimport failed' }
    & $Godot --headless --path $reviewDir --script res://verify_godot.gd --log-file (Join-Path $reviewDir 'verification.log')
    if ($LASTEXITCODE -ne 0) { throw 'Godot verification failed' }
    Copy-Item (Join-Path $reviewDir 'godot_validation.json') $PSScriptRoot
    Write-Output "Review logs retained at $reviewDir"
} finally {
    $env:APPDATA = $previousAppData
}
