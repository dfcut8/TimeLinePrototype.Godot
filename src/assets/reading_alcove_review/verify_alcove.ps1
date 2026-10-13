param([string]$Godot = 'C:/home/bin/Godot_v4.7.2-stable_win64/Godot_v4.7.2-stable_win64_console.exe')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path (Split-Path $PSScriptRoot)
$reviewDir = Join-Path (Join-Path $projectRoot '.godot') ('reading-alcove-review-' + [guid]::NewGuid())
$previousAppData = $env:APPDATA
try {
    python (Join-Path $PSScriptRoot 'prepare_review.py') $reviewDir
    if ($LASTEXITCODE -ne 0) { throw 'Dependency preparation failed' }
    $env:APPDATA = $reviewDir
    $importArguments = @('--headless', '--path', ('"' + $reviewDir + '"'), '--editor', '--import', '--log-file', ('"' + (Join-Path $reviewDir 'alcove_import.log') + '"'))
    $importRun = Start-Process -FilePath $Godot -ArgumentList $importArguments -WindowStyle Hidden -PassThru
    if (-not $importRun.WaitForExit(60000)) {
        Stop-Process -Id $importRun.Id
        throw "Import timed out; logs at $reviewDir"
    }
    Copy-Item (Join-Path $reviewDir 'alcove_import.log') -Destination $PSScriptRoot
    if ($importRun.ExitCode -ne 0) { throw "Import failed; logs at $reviewDir" }
    $runtimeGodot = $Godot -replace '_console.exe$', '.exe'
    $arguments = @('--path', ('"' + $reviewDir + '"'), '--script', 'res://assets/reading_alcove_review/verify_alcove.gd', '--log-file', ('"' + (Join-Path $reviewDir 'alcove_runtime.log') + '"'))
    $run = Start-Process -FilePath $runtimeGodot -ArgumentList $arguments -WindowStyle Hidden -PassThru
    if (-not $run.WaitForExit(60000)) {
        Stop-Process -Id $run.Id
        throw "Validation timed out; logs at $reviewDir"
    }
    Copy-Item (Join-Path $reviewDir 'alcove_import.log'),(Join-Path $reviewDir 'alcove_runtime.log') -Destination $PSScriptRoot
    if ($run.ExitCode -ne 0) { throw "Validation failed; logs at $reviewDir" }
    $evidence = Join-Path $reviewDir 'assets/reading_alcove_review'
    $report = Get-Content (Join-Path $evidence 'godot_validation.json') -Raw | ConvertFrom-Json
    if (-not $report.passed) { throw 'Reading alcove checks did not pass' }
    $regressionArguments = @('--path', ('"' + $reviewDir + '"'), '--script', 'res://assets/record_stack_family/verify_configurable.gd', '--log-file', ('"' + (Join-Path $reviewDir 'row_regression_runtime.log') + '"'))
    $regressionRun = Start-Process -FilePath $runtimeGodot -ArgumentList $regressionArguments -WindowStyle Hidden -PassThru
    if (-not $regressionRun.WaitForExit(60000)) {
        Stop-Process -Id $regressionRun.Id
        throw "Original row regression timed out; logs at $reviewDir"
    }
    Copy-Item (Join-Path $reviewDir 'row_regression_runtime.log') -Destination $PSScriptRoot
    if ($regressionRun.ExitCode -ne 0) { throw "Original row regression failed; logs at $reviewDir" }
    $regressionPath = Join-Path $reviewDir 'assets/record_stack_family/godot_configurable_validation.json'
    $regressionReport = Get-Content $regressionPath -Raw | ConvertFrom-Json
    if (-not $regressionReport.passed) { throw 'Original row regression did not pass' }
    foreach ($log in @('alcove_import.log','alcove_runtime.log','row_regression_runtime.log')) {
        if (Select-String -Path (Join-Path $reviewDir $log) -Pattern '^(ERROR|SCRIPT ERROR|WARNING):' -Quiet) {
            throw "Engine diagnostics in $log; inspect $reviewDir"
        }
    }
    Get-ChildItem $evidence -Filter 'godot_*' | Copy-Item -Destination $PSScriptRoot
    Copy-Item $regressionPath (Join-Path $PSScriptRoot 'godot_existing_row_validation.json')
    Write-Output "Alcove checks passed; $($regressionReport.cases.Count) original row regression cases passed."
    Write-Output "Review project retained at $reviewDir"
} finally {
    $env:APPDATA = $previousAppData
}
