param(
    [ValidateSet('Import','Tests','Packages')][string]$Action='Tests',
    [string]$Baseline='D:\UGit\T0\To\Migration\Baselines\godot_2026-09-11_v01',
    [string]$Godot='C:\Tools\Godot\Godot_v4.7.1-stable_win64.exe',
    [string[]]$TestNames=@(),
    [int]$MaxFps=0,
    [string]$ReportSuffix='',
    [switch]$SkipAndroid
)
$ErrorActionPreference='Stop'
$work=Join-Path $Baseline 'WorkingGodot'
$reports=Join-Path $Baseline 'Reports'
$builds=Join-Path $Baseline 'Builds'
New-Item -ItemType Directory -Path $reports,$builds -Force | Out-Null
function Invoke-Godot([string]$Name,[string[]]$Arguments,[int]$TimeoutSeconds=120) {
    $stdout=Join-Path $reports ($Name+'.log')
    $stderr=Join-Path $reports ($Name+'.errors.log')
    $watch=[Diagnostics.Stopwatch]::StartNew()
    $process=Start-Process -FilePath $Godot -ArgumentList $Arguments -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
    $done=$process.WaitForExit($TimeoutSeconds*1000)
    if (-not $done) { $process.Kill(); $process.WaitForExit() }
    $process.Refresh()
    $code=if ($done) { $process.ExitCode } else { -999 }
    $errors=Get-Content -LiteralPath $stderr -Raw -ErrorAction SilentlyContinue
    $output=Get-Content -LiteralPath $stdout -Raw -ErrorAction SilentlyContinue
    $result=[ordered]@{name=$Name;exitCode=$code;timedOut=(-not $done);seconds=[Math]::Round($watch.Elapsed.TotalSeconds,2);status='PASS';log=$stdout;errors=$stderr}
    if ($code -ne 0 -or $errors -match '(?m)^(SCRIPT ERROR|ERROR):' -or $output -match '(?m)^(SCRIPT ERROR|ERROR):') { $result.status='FAIL' }
    Write-Host "$Name $($result.status) exit=$code seconds=$($result.seconds)"
    return $result
}
$common=@('--headless','--path',$work)
if ($MaxFps -gt 0) { $common+=@('--max-fps',[string]$MaxFps) }
if ($Action -eq 'Import') {
    $result=Invoke-Godot 'import' ($common+@('--editor','--import')) 180
    $result | ConvertTo-Json | Set-Content (Join-Path $reports 'import.json') -Encoding utf8
    if ($result.status -ne 'PASS') { exit 1 }
    $probe=Invoke-Godot 'isolation' ($common+@('--script','res://tests/migration_probe.gd')) 30
    if ($probe.status -ne 'PASS') { exit 1 }
    exit 0
}
$probe=Invoke-Godot 'isolation' ($common+@('--script','res://tests/migration_probe.gd')) 30
if ($probe.status -ne 'PASS') { throw 'Save isolation verification failed' }
if ($Action -eq 'Tests') {
    $results=@()
    foreach ($test in Get-ChildItem (Join-Path $work 'tests') -File -Filter '*smoke.gd' | Sort-Object Name) {
        if ($TestNames.Count -gt 0 -and $test.BaseName -notin $TestNames) { continue }
        $results+=Invoke-Godot ($test.BaseName+$ReportSuffix) ($common+@('--script',('res://tests/'+$test.Name))) 120
        $results | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $reports ('tests'+$ReportSuffix+'.json')) -Encoding utf8
    }
    $rows=@('# Godot baseline smoke tests','','These results describe the frozen Godot version, not Unity parity.','','| Test | Status | Exit | Seconds |','|---|---|---:|---:|')
    foreach ($result in $results) { $rows+="|$($result.name)|$($result.status)|$($result.exitCode)|$($result.seconds)|" }
    $rows | Set-Content (Join-Path $reports ('tests'+$ReportSuffix+'.md')) -Encoding utf8
    Write-Host "BASELINE_TESTS_COMPLETE passed=$(@($results | Where-Object status -eq PASS).Count) total=$($results.Count)"
} else {
    $android=$null
    if (-not $SkipAndroid) { $android=Invoke-Godot 'export_android' ($common+@('--export-debug','"Android ARM64 Test"',(Join-Path $builds 'MergeTo10_GodotBaseline_20260911.apk'))) 240 }
    $windows=Join-Path $builds 'Windows'
    New-Item -ItemType Directory -Path $windows -Force | Out-Null
    $pack=Invoke-Godot 'export_windows_pack' ($common+@('--export-pack','"Windows Desktop Baseline"',(Join-Path $windows 'MergeTo10Baseline.pck'))) 180
    if ($pack.status -eq 'PASS') {
        Copy-Item -LiteralPath $Godot -Destination (Join-Path $windows 'MergeTo10Baseline.exe')
        Compress-Archive -Path (Join-Path $windows '*') -DestinationPath (Join-Path $builds 'MergeTo10_GodotBaseline_Windows.zip') -Force
    }
    $packageResults=@($android,$pack) | Where-Object { $null -ne $_ }
    $reportName=if($SkipAndroid){'windows_package.json'}else{'packages.json'}
    $packageResults | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $reports $reportName) -Encoding utf8
}
