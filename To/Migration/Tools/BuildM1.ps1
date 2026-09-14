param(
 [string]$UnityEditor = 'D:\UnityEditor\6000.3.11f1\Editor\Unity.exe',
 [string]$OutputDirectory = '',
 [string]$CombatOracle = ''
)
$ErrorActionPreference = 'Stop'
$project = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$validation = Join-Path $project 'Migration/Validation/M1Project'
if (!(Test-Path -LiteralPath $UnityEditor)) { throw 'Unity editor not found' }
$running = Get-CimInstance Win32_Process -Filter "Name = 'Unity.exe'" |
 Where-Object { $_.CommandLine -and $_.CommandLine.Contains($validation) }
if ($running) { throw 'The isolated validation project is already open; wait for its build to finish.' }
New-Item -ItemType Directory -Path $validation -Force | Out-Null
foreach ($folder in @('Assets','Packages','ProjectSettings')) {
 & robocopy (Join-Path $project $folder) (Join-Path $validation $folder) /E /MT:8 /NFL /NDL /NJH /NJS /NP
 if ($LASTEXITCODE -ge 8) { throw "Copy failed: $folder" }
}
if (Test-Path -LiteralPath (Join-Path $project 'Library/PackageCache')) {
 & robocopy (Join-Path $project 'Library/PackageCache') (Join-Path $validation 'Library/PackageCache') /E /MT:8 /NFL /NDL /NJH /NJS /NP
 if ($LASTEXITCODE -ge 8) { throw 'Package cache copy failed' }
}
$env:M1_OUTPUT = if ($OutputDirectory) { [IO.Path]::GetFullPath($OutputDirectory) } else { Join-Path $project 'Builds/M1V02' }
$env:M2_ORACLE = $CombatOracle
$env:M1_ORACLE = Join-Path $project 'Migration/Baselines/godot_2026-09-11_v01/Reports/board_oracle.json'
$env:M1_FEEDBACK_ORACLE = Join-Path $project 'Migration/Reports/M1V02/feedback_oracle.json'
if (!(Test-Path -LiteralPath $env:M1_FEEDBACK_ORACLE)) { throw 'Generate the frozen Godot feedback oracle before building M1.' }
$log = Join-Path $project ('Migration/Validation/m1-build-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.log')
$arguments = "-batchmode -nographics -projectPath `"$validation`" -executeMethod MergeTo10.Editor.M1Builder.Run -logFile `"$log`""
$run = Start-Process -FilePath $UnityEditor -ArgumentList $arguments -WindowStyle Hidden -PassThru -Wait
if ($run.ExitCode -ne 0) { throw "Unity build failed; see $log" }
Write-Output "Build and core tests passed. Runtime screenshots still require launching the player with --m1-smoke --capture-dir=<absolute directory>."
