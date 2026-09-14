param([string]$OutputDirectory='')
$ErrorActionPreference='Stop'
$project=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$validation=Join-Path $project 'Migration/Validation/M1Project'
if(Get-CimInstance Win32_Process -Filter "Name = 'Unity.exe'" | Where-Object {$_.CommandLine -and $_.CommandLine.Contains($validation)}){throw 'Validation editor already open'}
foreach($folder in @('Assets','Packages','ProjectSettings')){
 & robocopy (Join-Path $project $folder) (Join-Path $validation $folder) /E /MT:8 /NFL /NDL /NJH /NJS /NP
 if($LASTEXITCODE -ge 8){throw "Copy failed: $folder"}
}
$env:M2_EDITOR_OUTPUT=if($OutputDirectory){$OutputDirectory}else{Join-Path $project 'Migration/Reports/M2EditorV01'}
New-Item -ItemType Directory -Path $env:M2_EDITOR_OUTPUT -Force | Out-Null
$env:M2_ORACLE=Join-Path $project 'Migration/Reports/M2Foundation/combat_oracle.json'
$arguments="-batchmode -projectPath `"$validation`" -executeMethod MergeTo10.Editor.M2EditorTools.Validate -logFile `"$env:M2_EDITOR_OUTPUT/editor.log`""
$run=Start-Process 'D:\UnityEditor\6000.3.11f1\Editor\Unity.exe' -ArgumentList $arguments -WindowStyle Hidden -PassThru -Wait
if($run.ExitCode -ne 0){throw "Editor test failed: $env:M2_EDITOR_OUTPUT/editor.log"}
Get-Content (Join-Path $env:M2_EDITOR_OUTPUT 'editor-result.txt')

