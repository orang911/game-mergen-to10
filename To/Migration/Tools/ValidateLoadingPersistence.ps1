param([string]$RunName=('Run_'+(Get-Date -Format 'yyyyMMdd_HHmmss')),[string]$Method='MergeTo10.Editor.LoadingPersistenceVerifier.Validate',[switch]$ScreenCapture)
$ErrorActionPreference='Stop'
$unityProject=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$validation=Join-Path $unityProject 'Migration/Validation/M1Project'
if(Get-CimInstance Win32_Process -Filter "Name = 'Unity.exe'" | Where-Object {$_.CommandLine -and $_.CommandLine.Contains($validation)}){throw 'Validation editor already open'}
foreach($folder in @('Assets','Packages','ProjectSettings')){
 & robocopy (Join-Path $unityProject $folder) (Join-Path $validation $folder) /E /MT:8 /NFL /NDL /NJH /NJS /NP
 if($LASTEXITCODE -ge 8){throw "Copy failed: $folder"}
}
$env:M2_EDITOR_OUTPUT=Join-Path $unityProject "Migration/Reports/LoadingPersistence/2026-09-14_v01/$RunName"
if(Test-Path $env:M2_EDITOR_OUTPUT){throw 'Output exists; use a new run name'}
New-Item -ItemType Directory -Path $env:M2_EDITOR_OUTPUT | Out-Null
$env:M2_ORACLE=Join-Path $unityProject 'Migration/Reports/M2Foundation/combat_oracle.json'
$arguments="-batchmode -projectPath `"$validation`" -executeMethod $Method -logFile `"$env:M2_EDITOR_OUTPUT/editor.log`""
if($ScreenCapture){$arguments=$arguments.Replace('-batchmode ','')}
$run=Start-Process 'D:\UnityEditor\6000.3.11f1\Editor\Unity.exe' -ArgumentList $arguments -WindowStyle Hidden -PassThru -Wait
Get-ChildItem $env:M2_EDITOR_OUTPUT -Filter '*result.txt' | ForEach-Object { Get-Content $_.FullName }
if($run.ExitCode -ne 0){throw "Editor validation failed ($($run.ExitCode)): $env:M2_EDITOR_OUTPUT/editor.log"}
