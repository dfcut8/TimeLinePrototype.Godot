param([string]$Godot = 'C:/home/bin/Godot_v4.7.2-stable_win64/Godot_v4.7.2-stable_win64_console.exe')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path (Split-Path $PSScriptRoot)
$reviewDir = Join-Path (Join-Path $projectRoot '.godot') ('archive-editing-review-' + [guid]::NewGuid())
$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA
try {
    python (Join-Path $PSScriptRoot 'prepare_review.py') $reviewDir
    if ($LASTEXITCODE -ne 0) { throw 'Dependency preparation failed' }
    $env:APPDATA = $reviewDir
    $env:LOCALAPPDATA = $reviewDir
    $importLog = Join-Path $reviewDir 'editing_import.log'
    $importRun = Start-Process -FilePath $Godot -ArgumentList @('--headless', '--path', ('"' + $reviewDir + '"'), '--editor', '--import', '--log-file', ('"' + $importLog + '"')) -WindowStyle Hidden -PassThru
    if (-not $importRun.WaitForExit(60000)) {
        Stop-Process -Id $importRun.Id
        throw "Import timed out; logs at $reviewDir"
    }
    Copy-Item -LiteralPath $importLog -Destination $PSScriptRoot
    if ($importRun.ExitCode -ne 0) { throw "Import failed; logs at $reviewDir" }
    if (Select-String -LiteralPath $importLog -Pattern '^(ERROR|SCRIPT ERROR|WARNING):' -Quiet) { throw 'Import diagnostics; inspect editing_import.log' }
    $runtimeGodot = $Godot -replace '_console.exe$', '.exe'
    foreach ($suite in @(
        @('editing', 'archive_editing_review', 'verify_editing.gd', 'godot_validation.json'),
        @('island_regression', 'archive_island_review', 'verify_island.gd', 'godot_validation.json'),
        @('modular_regression', 'modular_library_review', 'verify_modular.gd', 'godot_validation.json'),
        @('row_regression', 'record_stack_family', 'verify_configurable.gd', 'godot_configurable_validation.json')
    )) {
        $logPath = Join-Path $reviewDir ($suite[0] + '_runtime.log')
        $scriptPath = 'res://assets/' + $suite[1] + '/' + $suite[2]
        $run = Start-Process -FilePath $runtimeGodot -ArgumentList @('--path', ('"' + $reviewDir + '"'), '--script', $scriptPath, '--log-file', ('"' + $logPath + '"')) -WindowStyle Hidden -PassThru
        if (-not $run.WaitForExit(60000)) {
            Stop-Process -Id $run.Id
            throw "Validation timed out: $($suite[0]); logs at $reviewDir"
        }
        Copy-Item -LiteralPath $logPath -Destination $PSScriptRoot
        if ($run.ExitCode -ne 0) { throw "Validation failed: $($suite[0]); logs at $reviewDir" }
        if (Select-String -LiteralPath $logPath -Pattern '^(ERROR|SCRIPT ERROR|WARNING):' -Quiet) { throw "Runtime diagnostics in $logPath" }
        $reportPath = Join-Path $reviewDir ('assets/' + $suite[1] + '/' + $suite[3])
        $report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
        if (-not $report.passed) { throw "Failed report: $($suite[0])" }
        if ($suite[0] -ne 'editing') {
            Copy-Item -LiteralPath $reportPath -Destination (Join-Path $PSScriptRoot ('godot_' + $suite[0] + '.json'))
        }
    }
    Get-ChildItem -LiteralPath (Join-Path $reviewDir 'assets/archive_editing_review') -Filter 'godot_*' | Copy-Item -Destination $PSScriptRoot
    Write-Output "All four suites passed. Review project retained at $reviewDir"
} finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
}
