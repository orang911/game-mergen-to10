param([string]$Baseline='D:\UGit\T0\To\Migration\Baselines\godot_2026-09-11_v01')
$ErrorActionPreference='Stop'
$capture=Join-Path (Split-Path (Split-Path $Baseline)) 'Tools/CapturePackedBaseline.gd'
$windows=Join-Path $Baseline 'Builds/Windows'
foreach($resolution in @('941x1672','720x1600','768x1024')){
    $output=Join-Path $Baseline ('Reports/Layouts/'+$resolution)
    New-Item -ItemType Directory -Path $output -Force | Out-Null
    $env:APPDATA=Join-Path $output 'TestProfile'
    New-Item -ItemType Directory -Path $env:APPDATA -Force | Out-Null
    $p=Start-Process -FilePath (Join-Path $windows 'MergeTo10Baseline.exe') -ArgumentList @('--path',$windows,'--script',$capture,'--rendering-method','gl_compatibility','--audio-driver','Dummy','--position','-2000,-2000','--resolution','470x836','--',('--capture-dir='+$output),('--capture-size='+$resolution)) -WindowStyle Hidden -RedirectStandardOutput (Join-Path $output 'capture.log') -RedirectStandardError (Join-Path $output 'capture.errors.log') -PassThru
    if(-not $p.WaitForExit(45000)){$p.Kill();throw "Capture timeout $resolution"}
    $p.Refresh()
    if($p.ExitCode -ne 0){throw "Capture failed $resolution"}
    Write-Output "LAYOUT_CAPTURE_OK $resolution"
}
