param([string]$Baseline='D:\UGit\T0\To\Migration\Baselines\godot_2026-09-11_v01')
$ErrorActionPreference='Stop'
$reports=Join-Path $Baseline 'Reports'
$env:APPDATA=Join-Path $reports 'RealtimeMotionProfile'
New-Item -ItemType Directory -Path $env:APPDATA -Force | Out-Null
$p=Start-Process -FilePath 'C:\Tools\Godot\Godot_v4.7.1-stable_win64.exe' -ArgumentList @('--path',(Join-Path $Baseline 'WorkingGodot'),'--script','res://tests/migration_record_reference.gd','--rendering-method','gl_compatibility','--audio-driver','Dummy','--position','-2000,-2000','--resolution','470x836','--max-fps','60','--','--realtime') -WindowStyle Hidden -RedirectStandardOutput (Join-Path $reports 'reference_realtime.log') -RedirectStandardError (Join-Path $reports 'reference_realtime.errors.log') -PassThru
if(-not $p.WaitForExit(60000)){$p.Kill();throw 'Realtime recording timeout'}
$p.Refresh()
if($p.ExitCode -ne 0){throw 'Realtime reference failed'}
Write-Output 'REFERENCE_REALTIME_OK'
