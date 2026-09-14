param([string]$Baseline='D:\UGit\T0\To\Migration\Baselines\godot_2026-09-11_v01')
$ErrorActionPreference='Stop'
$reports=Join-Path $Baseline 'Reports'
$env:APPDATA=Join-Path $reports 'MotionProfile'
New-Item -ItemType Directory -Path $env:APPDATA -Force | Out-Null
$p=Start-Process -FilePath 'C:\Tools\Godot\Godot_v4.7.1-stable_win64.exe' -ArgumentList @('--path',(Join-Path $Baseline 'WorkingGodot'),'--script','res://tests/migration_record_reference.gd','--rendering-method','gl_compatibility','--audio-driver','Dummy','--position','-2000,-2000','--resolution','470x836','--write-movie',(Join-Path $reports 'reference_motion.avi'),'--fixed-fps','60') -WindowStyle Hidden -RedirectStandardOutput (Join-Path $reports 'reference_motion.log') -RedirectStandardError (Join-Path $reports 'reference_motion.errors.log') -PassThru
if(-not $p.WaitForExit(120000)){$p.Kill();throw 'Reference recording timeout'}
$p.Refresh()
if($p.ExitCode -ne 0){throw 'Reference recording failed'}
Write-Output 'REFERENCE_RECORD_OK'
