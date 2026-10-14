param([string]$Godot = 'C:/home/bin/Godot_v4.7.2-stable_win64/Godot_v4.7.2-stable_win64_console.exe')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path (Split-Path $PSScriptRoot)
$reviewDir = Join-Path (Join-Path $projectRoot '.godot') ('kit-editing-review-' + [guid]::NewGuid())
$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA
try {
    python (Join-Path $PSScriptRoot '../catalog_perimeter_review/prepare_review.py') $reviewDir 'assets/kit_editing_review/verify_editing.gd' 'assets/kit_editing_review/review_entrance.tscn'
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
        @('editing', 'assets/kit_editing_review/verify_editing.gd'),
        @('catalog_regression', 'assets/catalog_perimeter_review/verify_catalog.gd'),
        @('display_regression', 'assets/catalog_display_review/verify_display.gd'),
        @('modular_regression', 'assets/modular_library_review/verify_modular.gd')
    )) {
        $logPath = Join-Path $reviewDir ($suite[0] + '_runtime.log')
        $run = Start-Process -FilePath $runtimeGodot -ArgumentList @('--path', ('"' + $reviewDir + '"'), '--script', ('res://' + $suite[1]), '--log-file', ('"' + $logPath + '"')) -WindowStyle Hidden -PassThru
        if (-not $run.WaitForExit(60000)) {
            Stop-Process -Id $run.Id
            throw "Validation timed out: $($suite[0]); logs at $reviewDir"
        }
        Copy-Item -LiteralPath $logPath -Destination $PSScriptRoot
        if ($run.ExitCode -ne 0) { throw "Validation failed: $($suite[0]); logs at $reviewDir" }
        if (Select-String -LiteralPath $logPath -Pattern '^(ERROR|SCRIPT ERROR|WARNING):' -Quiet) { throw "Runtime diagnostics in $logPath" }
        $suiteReport = Get-Content (Join-Path $reviewDir ($suite[1] -replace '/[^/]+$', '/godot_validation.json')) -Raw | ConvertFrom-Json
        if (-not $suiteReport.passed) { throw "Failed report: $($suite[0])" }
        if ($suite[0] -ne 'editing') {
            Copy-Item (Join-Path $reviewDir ($suite[1] -replace '/[^/]+$', '/godot_validation.json')) (Join-Path $PSScriptRoot ('godot_' + $suite[0] + '.json'))
        }
    }
    Get-ChildItem -LiteralPath (Join-Path $reviewDir 'assets/kit_editing_review') -Filter 'godot_*' | Copy-Item -Destination $PSScriptRoot
    Write-Output "All four suites passed. Review project retained at $reviewDir"
} finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
}
