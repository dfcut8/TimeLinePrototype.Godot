param([string]$Godot = 'C:/home/bin/Godot_v4.7.2-stable_win64/Godot_v4.7.2-stable_win64_console.exe')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path (Split-Path $PSScriptRoot)
$reviewDir = Join-Path (Join-Path $projectRoot '.godot') ('modular-library-review-' + [guid]::NewGuid())
$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA
try {
    python (Join-Path $PSScriptRoot 'prepare_review.py') $reviewDir
    if ($LASTEXITCODE -ne 0) { throw 'Dependency preparation failed' }
    $env:APPDATA = $reviewDir
    $env:LOCALAPPDATA = $reviewDir
    $importArguments = @('--headless', '--path', ('"' + $reviewDir + '"'), '--editor', '--import', '--log-file', ('"' + (Join-Path $reviewDir 'modular_import.log') + '"'))
    $importRun = Start-Process -FilePath $Godot -ArgumentList $importArguments -WindowStyle Hidden -PassThru
    if (-not $importRun.WaitForExit(60000)) {
        Stop-Process -Id $importRun.Id
        throw "Import timed out; logs at $reviewDir"
    }
    Copy-Item (Join-Path $reviewDir 'modular_import.log') -Destination $PSScriptRoot
    if ($importRun.ExitCode -ne 0) { throw "Import failed; logs at $reviewDir" }
    $runtimeGodot = $Godot -replace '_console.exe$', '.exe'
    $arguments = @('--path', ('"' + $reviewDir + '"'), '--script', 'res://assets/modular_library_review/verify_modular.gd', '--log-file', ('"' + (Join-Path $reviewDir 'modular_runtime.log') + '"'))
    $run = Start-Process -FilePath $runtimeGodot -ArgumentList $arguments -WindowStyle Hidden -PassThru
    if (-not $run.WaitForExit(60000)) {
        Stop-Process -Id $run.Id
        throw "Validation timed out; logs at $reviewDir"
    }
    Copy-Item (Join-Path $reviewDir 'modular_runtime.log') -Destination $PSScriptRoot
    if ($run.ExitCode -ne 0) { throw "Validation failed; logs at $reviewDir" }
    foreach ($log in @('modular_import.log', 'modular_runtime.log')) {
        if (Select-String -Path (Join-Path $reviewDir $log) -Pattern '^(ERROR|SCRIPT ERROR|WARNING):' -Quiet) {
            throw "Engine diagnostics in $log; inspect $reviewDir"
        }
    }
    $evidence = Join-Path $reviewDir 'assets/modular_library_review'
    $report = Get-Content (Join-Path $evidence 'godot_validation.json') -Raw | ConvertFrom-Json
    if (-not $report.passed) { throw 'Modular library checks did not pass' }
    Get-ChildItem $evidence -Filter 'godot_*' | Copy-Item -Destination $PSScriptRoot
    Write-Output "Passed $($report.arc_cases.Count) arc, $($report.shelf_cases.Count) shelf, $($report.row_cases.Count) row and $($report.sector_cases.Count) sector inspections."
    Write-Output "Review project retained at $reviewDir"
} finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
}
