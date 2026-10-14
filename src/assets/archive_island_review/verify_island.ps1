param([string]$Godot = 'C:/home/bin/Godot_v4.7.2-stable_win64/Godot_v4.7.2-stable_win64_console.exe')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path (Split-Path $PSScriptRoot)
$reviewDir = Join-Path (Join-Path $projectRoot '.godot') ('archive-island-review-' + [guid]::NewGuid())
$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA
try {
    python (Join-Path $PSScriptRoot 'prepare_review.py') $reviewDir
    if ($LASTEXITCODE -ne 0) { throw 'Dependency preparation failed' }
    $env:APPDATA = $reviewDir
    $env:LOCALAPPDATA = $reviewDir
    $importLog = Join-Path $reviewDir 'island_import.log'
    $importArguments = @('--headless', '--path', ('"' + $reviewDir + '"'), '--editor', '--import', '--log-file', ('"' + $importLog + '"'))
    $importRun = Start-Process -FilePath $Godot -ArgumentList $importArguments -WindowStyle Hidden -PassThru
    if (-not $importRun.WaitForExit(60000)) {
        Stop-Process -Id $importRun.Id
        throw "Import timed out; logs at $reviewDir"
    }
    Copy-Item -LiteralPath $importLog -Destination $PSScriptRoot
    if ($importRun.ExitCode -ne 0) { throw "Import failed; logs at $reviewDir" }
    if (Select-String -LiteralPath $importLog -Pattern '^(ERROR|SCRIPT ERROR|WARNING):' -Quiet) { throw 'Import diagnostics; inspect island_import.log' }
    $runtimeGodot = $Godot -replace '_console.exe$', '.exe'
    foreach ($suite in @(
        @('island', 'assets/archive_island_review/verify_island.gd'),
        @('adaptive_regression', 'assets/adaptive_library_review/verify_adaptive.gd'),
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
        if (Select-String -LiteralPath $logPath -Pattern '^(ERROR|SCRIPT ERROR|WARNING):' -Quiet) { throw "Runtime diagnostics in $logPath" }
    }
    $evidence = Join-Path $reviewDir 'assets/archive_island_review'
    $report = Get-Content (Join-Path $evidence 'godot_validation.json') -Raw | ConvertFrom-Json
    if (-not $report.passed) { throw 'Archive island checks did not pass' }
    Get-ChildItem -LiteralPath $evidence -Filter 'godot_*' | Copy-Item -Destination $PSScriptRoot
    Copy-Item (Join-Path $reviewDir 'assets/adaptive_library_review/godot_validation.json') (Join-Path $PSScriptRoot 'godot_adaptive_regression.json')
    Copy-Item (Join-Path $reviewDir 'assets/record_stack_family/godot_configurable_validation.json') (Join-Path $PSScriptRoot 'godot_row_regression.json')
    Write-Output "Passed $($report.island_cases.Count) island, $($report.shelf_cases.Count) shelf and $($report.room_cases.Count) room cases."
    Write-Output "Review project retained at $reviewDir"
} finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
}
