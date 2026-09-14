param([string]$Baseline='D:\UGit\T0\To\Migration\Baselines\godot_2026-09-11_v01')
$ErrorActionPreference='Stop'
$manifest=Get-Content (Join-Path $Baseline 'manifest.json') -Raw | ConvertFrom-Json
$mismatches=@()
$sourceChanges=@()
foreach($entry in $manifest.files){
    $actual=(Get-FileHash -LiteralPath (Join-Path (Join-Path $Baseline 'Source') $entry.path) -Algorithm SHA256).Hash
    if($actual -ne $entry.sha256){$mismatches+=$entry.path}
    $current=(Get-FileHash -LiteralPath (Join-Path $manifest.source $entry.path) -Algorithm SHA256).Hash
    if($current -ne $entry.sha256){$sourceChanges+=$entry.path}
}
if($mismatches.Count -gt 0){throw 'Frozen baseline hash mismatch'}
$reports=Join-Path $Baseline 'Reports'
$tests=@(Get-Content (Join-Path $reports 'tests.json') -Raw | ConvertFrom-Json)
Add-Type -AssemblyName System.Drawing
foreach($size in @('941x1672','720x1600','768x1024')){
    $imagePath=Join-Path $reports ('Layouts/'+$size+'/packed_first_run.png')
    $img=[Drawing.Image]::FromFile($imagePath)
    $actual="$($img.Width)x$($img.Height)"
    $img.Dispose()
    if($actual -ne $size){throw "Layout sample size mismatch: $size vs $actual"}
}
$uiDir=Join-Path $Baseline 'WorkingGodot/builds/ui_audit/2026-09-11_v02_runtime_baseline/screenshots'
$uiCount=@(Get-ChildItem -LiteralPath $uiDir -File -Filter '*.png').Count
if($uiCount -ne 35){throw "UI screenshot count mismatch: $uiCount"}
$artifacts=@()
foreach($relative in @('Builds/MergeTo10_GodotBaseline_20260911.apk','Builds/MergeTo10_GodotBaseline_Windows.zip','Reports/board_oracle.json','Reports/reference_motion.avi','Reports/reference_motion_trace.json','Reports/reference_motion_realtime_trace.json')){
    $file=Get-Item -LiteralPath (Join-Path $Baseline $relative)
    $artifacts+=[ordered]@{path=$relative;bytes=$file.Length;sha256=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash}
}
$summary=[ordered]@{
    baseline=$manifest.id; status='AWAITING_BASELINE_REVIEW'; unityPlayable=$false
    frozenFileCount=$manifest.fileCount; frozenHashMismatches=$mismatches; liveSourceChanges=$sourceChanges
    godotTests=[ordered]@{total=$tests.Count;pass=@($tests|Where-Object status -eq PASS).Count;fail=@($tests|Where-Object status -eq FAIL).Count}
    oracleCases=288; oracleSamples=2592; currentUiScreenshots=35
    offscreenLayoutResolutions=@('941x1672','720x1600','768x1024')
    actualDesktopStartupCapture='597x1061 (window/viewport constrained; not a full-screen device screenshot)'
    offlineMovieTimingValid=$false
    androidPackage='com.crystalguardians.mergeto10.baseline'
    pending=@('user baseline approval','Android physical device testing','30/60fps physical performance','safe-area physical device verification','Unity M1-M4')
    artifacts=$artifacts
}
$summary | ConvertTo-Json -Depth 7 | Set-Content (Join-Path $reports 'delivery_manifest.json') -Encoding utf8
Write-Output "BASELINE_DELIVERY files=$($manifest.fileCount) frozen_mismatches=$($mismatches.Count) live_changes=$($sourceChanges.Count) tests=$($summary.godotTests.pass)/$($tests.Count)"
