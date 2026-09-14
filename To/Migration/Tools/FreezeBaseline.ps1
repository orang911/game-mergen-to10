param(
    [string]$Source = 'D:\UGit\UGit\TO10',
    [string]$Target = 'D:\UGit\T0\To',
    [string]$BaselineId = 'godot_2026-09-11_v01'
)
$ErrorActionPreference = 'Stop'
$Source = (Resolve-Path -LiteralPath $Source).Path
$Target = (Resolve-Path -LiteralPath $Target).Path
$destination = Join-Path $Target "Migration/Baselines/$BaselineId"
if (Test-Path -LiteralPath $destination) { throw "Refusing to overwrite baseline: $destination" }
$snapshot = Join-Path $destination 'Source'
$working = Join-Path $destination 'WorkingGodot'
New-Item -ItemType Directory -Path $snapshot,$working -Force | Out-Null
$records = [Collections.Generic.List[object]]::new()
$files = @()
foreach ($folder in @('assets','scripts','scenes','shaders','docs','tests','tools')) {
    $files += Get-ChildItem -LiteralPath (Join-Path $Source $folder) -Recurse -File
}
foreach ($name in @('project.godot','export_presets.cfg','AGENTS.md','.gitignore','MIGRATION_GODOT.md','PROJECT_DIRECTION.md')) {
    if (Test-Path -LiteralPath (Join-Path $Source $name)) { $files += Get-Item -LiteralPath (Join-Path $Source $name) }
}
foreach ($file in $files) {
    $relative = [IO.Path]::GetRelativePath($Source, $file.FullName)
    $outFile = Join-Path $snapshot $relative
    New-Item -ItemType Directory -Path (Split-Path $outFile) -Force | Out-Null
    $before = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    Copy-Item -LiteralPath $file.FullName -Destination $outFile
    $after = (Get-FileHash -LiteralPath $outFile -Algorithm SHA256).Hash
    if ($before -ne $after) { throw "Changed while copying: $relative" }
    $records.Add([ordered]@{path=$relative.Replace('\','/'); bytes=$file.Length; sha256=$after})
}
$head = & git -C $Source rev-parse HEAD
$status = @(& git -C $Source status --porcelain)
$manifest = [ordered]@{
    id=$BaselineId; createdUtc=[DateTime]::UtcNow.ToString('o'); source=$Source
    sourceCommit=$head; sourceDirty=($status.Count -gt 0); sourceStatus=$status
    unityTarget=$Target; unityVersion='6000.3.11f1'; urpVersion='17.3.0'
    status='AWAITING_BASELINE_REVIEW'; fileCount=$records.Count; files=$records
    exclusions=@('.git','.godot','previous build binaries','art drafts','player saves','unreferenced legacy packages/settings/imge')
}
$manifest | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $destination 'manifest.json') -Encoding utf8
foreach ($folder in @('assets','scripts','scenes','shaders','tests')) {
    Copy-Item -LiteralPath (Join-Path $snapshot $folder) -Destination (Join-Path $working $folder) -Recurse
}
Copy-Item -LiteralPath (Join-Path $snapshot 'project.godot'),(Join-Path $snapshot 'export_presets.cfg') -Destination $working
$audit = Join-Path $Source 'builds/ui_audit/2026-09-10_v02_runtime'
if (Test-Path -LiteralPath $audit) { Copy-Item -LiteralPath $audit -Destination (Join-Path $destination 'ReferenceUI') -Recurse }
Write-Output "BASELINE_FROZEN files=$($records.Count) root=$destination"
