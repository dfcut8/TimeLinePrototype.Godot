param([string]$Godot = 'C:/home/bin/Godot_v4.7.2-stable_win64/Godot_v4.7.2-stable_win64_console.exe')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path (Split-Path $PSScriptRoot)
$reviewDir = Join-Path (Join-Path $projectRoot '.godot') ('adaptive-library-review-' + [guid]::NewGuid())
$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA
try {
    python (Join-Path $PSScriptRoot 'prepare_review.py') $reviewDir
    if ($LASTEXITCODE -ne 0) { throw 'Dependency preparation failed' }
    $env:APPDATA = $reviewDir
    $env:LOCALAPPDATA = $reviewDir
    $importArguments = @('--headless', '--path', ('"' + $reviewDir + '"'), '--editor', '--import', '--log-file', ('"' + (Join-Path $reviewDir 'adaptive_import.log') + '"'))
    $importRun = Start-Process -FilePath $Godot -ArgumentList $importArguments -WindowStyle Hidden -PassThru
    if (-not $importRun.WaitForExit(60000)) {
        Stop-Process -Id $importRun.Id
        throw "Import timed out; logs at $reviewDir"
    }
    Copy-Item (Join-Path $reviewDir 'adaptive_import.log') -Destination $PSScriptRoot
    if ($importRun.ExitCode -ne 0) { throw "Import failed; logs at $reviewDir" }
    $runtimeGodot = $Godot -replace '_console.exe$', '.exe'
    foreach ($suite in @(
        @('adaptive', 'assets/adaptive_library_review/verify_adaptive.gd'),
        @('rail_regression', 'assets/rail_assembly_review/verify_configurable.gd'),
        @('row_regression', 'assets/record_stack_family/verify_configurable.gd')
    )) {
        $logPath = Join-Path $reviewDir ($suite[0] + '_runtime.log')
        $arguments = @('--path', ('"' + $reviewDir + '"'), '--script', ('res://' + $suite[1]), '--log-file', ('"' + $logPath + '"'))
        $run = Start-Process -FilePath $runtimeGodot -ArgumentList $arguments -WindowStyle Hidden -PassThru
        if (-not $run.WaitForExit(60000)) {
            Stop-Process -Id $run.Id
            throw "Validation timed out; logs at $reviewDir"
        }
        Copy-Item -LiteralPath $logPath -Destination $PSScriptRoot
        if ($run.ExitCode -ne 0) { throw "Validation failed: $($suite[0]); logs at $reviewDir" }
    }
    foreach ($log in @('adaptive_import.log', 'adaptive_runtime.log', 'rail_regression_runtime.log', 'row_regression_runtime.log')) {
        if (Select-String -Path (Join-Path $reviewDir $log) -Pattern '^(ERROR|SCRIPT ERROR|WARNING):' -Quiet) {
            throw "Engine diagnostics in $log; inspect $reviewDir"
        }
    }
    $evidence = Join-Path $reviewDir 'assets/adaptive_library_review'
    $report = Get-Content (Join-Path $evidence 'godot_validation.json') -Raw | ConvertFrom-Json
    if (-not $report.passed) { throw 'Adaptive library checks did not pass' }
    Get-ChildItem $evidence -Filter 'godot_*' | Copy-Item -Destination $PSScriptRoot
    Copy-Item (Join-Path $reviewDir 'assets/rail_assembly_review/godot_configurable_validation.json') (Join-Path $PSScriptRoot 'godot_rail_regression.json')
    Copy-Item (Join-Path $reviewDir 'assets/record_stack_family/godot_configurable_validation.json') (Join-Path $PSScriptRoot 'godot_row_regression.json')
    Write-Output "Passed $($report.rail_cases.Count) rail, $($report.shelf_cases.Count) shelf, $($report.alcove_cases.Count) alcove and $($report.room_cases.Count) room cases."
    Write-Output "Review project retained at $reviewDir"
} finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
}
