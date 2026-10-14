param(
    [string]$Godot = 'C:/home/bin/Godot_v4.7.2-stable_win64/Godot_v4.7.2-stable_win64_console.exe',
    [switch]$Baseline
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path (Split-Path $PSScriptRoot)
$reviewDir = Join-Path (Join-Path $projectRoot '.godot') ('assembly-editing-review-' + [guid]::NewGuid())
$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA
function Invoke-ReviewEngine([string[]]$EngineArguments, [string]$LogPath) {
    $arguments = @('--path', ('"' + $reviewDir + '"'), '--log-file', ('"' + $LogPath + '"')) + $EngineArguments
    $process = Start-Process -FilePath $Godot -ArgumentList $arguments -WindowStyle Hidden -PassThru
    if (-not $process.WaitForExit(60000)) {
        Stop-Process -Id $process.Id
        throw "Engine timed out; logs at $reviewDir"
    }
    return $process.ExitCode
}
try {
    python (Join-Path $PSScriptRoot '../catalog_perimeter_review/prepare_review.py') $reviewDir `
        'assets/assembly_editing_review/verify_editing.gd' 'assets/assembly_editing_review/review_objects.tscn' `
        'assets/adaptive_library_review/verify_adaptive.gd' 'assets/adaptive_library_review/review_room.tscn' `
        'assets/rail_assembly_review/verify_configurable.gd' 'assets/rail_assembly_review/review_configurable.tscn'
    if ($LASTEXITCODE -ne 0) { throw 'Dependency preparation failed' }
    if ($Baseline) {
        # Replay the pre-fix scripts only in the isolated project, never the checkout.
        $baselineCommit = 'b90a628e7e143d7b3d62abf2b9772c8b9adc449f'
        $repoRoot = Split-Path $projectRoot
        foreach ($relative in @(
            'assets/timeline_rail_housing/configurable_timeline_rail.gd',
            'assets/catalog_lectern/configurable_catalog_station.gd',
            'assets/reading_bench/configurable_reading_alcove.gd',
            'assets/archive_display_plinth/configurable_archive_display.gd'
        )) {
            $sourceLines = git -C $repoRoot show "${baselineCommit}:src/$relative"
            if ($LASTEXITCODE -ne 0) { throw "Cannot load baseline $relative" }
            [System.IO.File]::WriteAllLines((Join-Path $reviewDir $relative), $sourceLines, [System.Text.UTF8Encoding]::new($false))
        }
        @{
            commit = $baselineCommit
            verifier_sha256 = (Get-FileHash -LiteralPath (Join-Path $PSScriptRoot 'verify_editing.gd') -Algorithm SHA256).Hash.ToLowerInvariant()
        } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'baseline_source.json') -Encoding utf8
    }
    $env:APPDATA = $reviewDir
    $env:LOCALAPPDATA = $reviewDir
    $importLog = Join-Path $reviewDir 'editing_import.log'
    $exitCode = Invoke-ReviewEngine @('--headless', '--editor', '--import') $importLog
    $savedImportLog = if ($Baseline) { 'baseline_import.log' } else { 'editing_import.log' }
    Copy-Item -LiteralPath $importLog -Destination (Join-Path $PSScriptRoot $savedImportLog)
    if ($exitCode -ne 0 -or (Select-String -LiteralPath $importLog -Pattern '^(ERROR|SCRIPT ERROR|WARNING):' -Quiet)) {
        throw "Import failed; logs at $reviewDir"
    }
    $suites = @(
        @('editing', 'assembly_editing_review', 'verify_editing.gd'),
        @('adaptive_regression', 'adaptive_library_review', 'verify_adaptive.gd'),
        @('catalog_regression', 'catalog_perimeter_review', 'verify_catalog.gd'),
        @('display_regression', 'catalog_display_review', 'verify_display.gd')
    )
    if ($Baseline) { $suites = @(, $suites[0]) }
    foreach ($suite in $suites) {
        $name = if ($Baseline) { 'baseline' } else { $suite[0] }
        $logPath = Join-Path $reviewDir ($name + '_runtime.log')
        $arguments = @('--script', ('res://assets/' + $suite[1] + '/' + $suite[2]))
        if ($Baseline) { $arguments += '--headless' }
        $exitCode = Invoke-ReviewEngine $arguments $logPath
        Copy-Item -LiteralPath $logPath -Destination $PSScriptRoot
        $reportPath = Join-Path $reviewDir ('assets/' + $suite[1] + '/godot_validation.json')
        $report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
        $reportName = if ($Baseline) { 'godot_baseline.json' } elseif ($suite[0] -eq 'editing') { 'godot_validation.json' } else { 'godot_' + $suite[0] + '.json' }
        Copy-Item -LiteralPath $reportPath -Destination (Join-Path $PSScriptRoot $reportName)
        if ($Baseline) {
            if ($exitCode -ne 1 -or $report.passed) { throw 'Baseline did not reproduce expected failures' }
            Write-Output "Baseline reproduced $($report.failures.Count) failed assertions."
        } elseif ($exitCode -ne 0 -or -not $report.passed -or (Select-String -LiteralPath $logPath -Pattern '^(ERROR|SCRIPT ERROR|WARNING):' -Quiet)) {
            throw "Validation failed: $name; logs at $reviewDir"
        }
    }
    if (-not $Baseline) {
        Get-ChildItem -LiteralPath (Join-Path $reviewDir 'assets/assembly_editing_review') -Filter 'godot_*.png' | Copy-Item -Destination $PSScriptRoot
    }
    Write-Output "Review project retained at $reviewDir"
} finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
}
