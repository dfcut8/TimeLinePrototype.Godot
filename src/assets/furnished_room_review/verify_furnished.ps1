param([string]$Godot = 'C:/home/bin/Godot_v4.7.2-stable_win64/Godot_v4.7.2-stable_win64_console.exe')
$ErrorActionPreference = 'Stop'
$reviewDir = Join-Path ([IO.Path]::GetTempPath()) ('furnished-room-review-' + [guid]::NewGuid())
$previousAppData = $env:APPDATA
try {
    python (Join-Path $PSScriptRoot 'prepare_review.py') $reviewDir
    if ($LASTEXITCODE -ne 0) { throw 'Dependency preparation failed' }
    $env:APPDATA = $reviewDir
    & $Godot --headless --path $reviewDir --editor --import --log-file (Join-Path $reviewDir 'furnished_import.log')
    if ($LASTEXITCODE -ne 0) { throw "Import failed; logs at $reviewDir" }
    $runtimeGodot = $Godot -replace '_console.exe$', '.exe'
    $arguments = @('--path', ('"' + $reviewDir + '"'), '--script', 'res://assets/furnished_room_review/verify_furnished.gd', '--log-file', ('"' + (Join-Path $reviewDir 'furnished_runtime.log') + '"'))
    $run = Start-Process -FilePath $runtimeGodot -ArgumentList $arguments -WindowStyle Hidden -PassThru
    if (-not $run.WaitForExit(60000)) {
        Stop-Process -Id $run.Id
        throw "Validation timed out; logs at $reviewDir"
    }
    Copy-Item (Join-Path $reviewDir 'furnished_import.log'),(Join-Path $reviewDir 'furnished_runtime.log') -Destination $PSScriptRoot
    if ($run.ExitCode -ne 0) { throw "Validation failed; logs at $reviewDir" }
    $evidence = Join-Path $reviewDir 'assets/furnished_room_review'
    $report = Get-Content (Join-Path $evidence 'godot_validation.json') -Raw | ConvertFrom-Json
    if (-not $report.passed) { throw 'Furnishing checks did not pass' }
    Get-ChildItem $evidence -Filter 'godot_*' | Copy-Item -Destination $PSScriptRoot
    Write-Output "Review project retained at $reviewDir"
} finally {
    $env:APPDATA = $previousAppData
}
