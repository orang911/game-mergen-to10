param([string]$Baseline='D:\UGit\T0\To\Migration\Baselines\godot_2026-09-11_v01')
$ErrorActionPreference='Stop'
$reports=Join-Path $Baseline 'Reports'
foreach($name in @('imprint','input','feedback')){
    $file='migration_diagnose_'+$name
    $p=Start-Process -FilePath 'C:\Tools\Godot\Godot_v4.7.1-stable_win64.exe' -ArgumentList @('--headless','--max-fps','60','--path',(Join-Path $Baseline 'WorkingGodot'),'--script',('res://tests/'+$file+'.gd')) -WindowStyle Hidden -RedirectStandardOutput (Join-Path $reports ($file+'.log')) -RedirectStandardError (Join-Path $reports ($file+'.errors.log')) -PassThru
    if(-not $p.WaitForExit(60000)){$p.Kill();throw "Diagnostic timeout $name"}
    $p.Refresh()
    Write-Output "$name exit=$($p.ExitCode)"
}
