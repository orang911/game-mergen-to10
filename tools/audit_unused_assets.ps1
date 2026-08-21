param(
    [ValidateSet("Analyze", "Move")]
    [string]$Mode = "Analyze",
    [string]$BatchDate = "2026-08-11"
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$reviewRoot = Join-Path $repoRoot ("asset_review_delete\{0}\unreferenced" -f $BatchDate)
$runtimeRoot = Join-Path $repoRoot "assets\runtime"
$legacyUiRoot = Join-Path $repoRoot "assets\UI"

function Get-RepoRelativePath([string]$absolutePath) {
    return $absolutePath.Substring($repoRoot.Length + 1).Replace("\", "/")
}

function Assert-PathInside([string]$absolutePath, [string]$allowedRoot) {
    $full = [System.IO.Path]::GetFullPath($absolutePath)
    $root = [System.IO.Path]::GetFullPath($allowedRoot).TrimEnd("\") + "\"
    if (-not $full.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing path outside allowed root: $full"
    }
}

$textFiles = @()
foreach ($directory in @("scripts", "scenes", "tests", "assets/runtime")) {
    $absoluteDirectory = Join-Path $repoRoot $directory
    if (Test-Path -LiteralPath $absoluteDirectory) {
        $textFiles += Get-ChildItem -LiteralPath $absoluteDirectory -Recurse -File |
            Where-Object { $_.Extension -in ".gd", ".tscn", ".tres", ".cfg", ".json", ".godot" }
    }
}
$textFiles += Get-Item -LiteralPath (Join-Path $repoRoot "project.godot")

$corpusBuilder = [System.Text.StringBuilder]::new()
foreach ($textFile in $textFiles) {
    [void]$corpusBuilder.AppendLine([System.IO.File]::ReadAllText($textFile.FullName))
}
$corpus = $corpusBuilder.ToString().ToLowerInvariant()

# These directories are loaded through numbered filename patterns or nested
# ASSET_ROOT composition and cannot be proven file-by-file from literal paths.
$dynamicProtectedPrefixes = @(
    "assets/runtime/characters/",
    "assets/runtime/fx/merge/",
    "assets/runtime/ui/components/board_glyphs/",
    "assets/runtime/ui/interfaces/main_hub/",
    "assets/runtime/ui/shared/meta_icons/"
)

$runtimeCandidates = @()
$runtimeFiles = Get-ChildItem -LiteralPath $runtimeRoot -Recurse -File |
    Where-Object {
        $_.Name -notlike "*.import" -and
        $_.Name -notlike "*.uid" -and
        $_.Name -ne ".gdignore" -and
        $_.Extension -ne ".md"
    }

foreach ($file in $runtimeFiles) {
    $relativePath = Get-RepoRelativePath $file.FullName
    $lowerPath = $relativePath.ToLowerInvariant()
    $resourcePath = "res://" + $lowerPath
    $resourceDirectory = "res://" + ([System.IO.Path]::GetDirectoryName($lowerPath).Replace("\", "/")) + "/"
    $fileName = $file.Name.ToLowerInvariant()
    $dynamicProtected = $false
    foreach ($prefix in $dynamicProtectedPrefixes) {
        if ($lowerPath.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            $dynamicProtected = $true
            break
        }
    }
    $exactReference = $corpus.Contains($resourcePath)
    $composedReference = $corpus.Contains($resourceDirectory) -and $corpus.Contains($fileName)
    if (-not $dynamicProtected -and -not $exactReference -and -not $composedReference) {
        $runtimeCandidates += [pscustomobject]@{
            File = $file
            Reason = "no_runtime_or_test_reference"
        }
    }
}

$legacyUiCandidates = @()
if (Test-Path -LiteralPath $legacyUiRoot) {
    foreach ($file in Get-ChildItem -LiteralPath $legacyUiRoot -Recurse -File) {
        $legacyUiCandidates += [pscustomobject]@{
            File = $file
            Reason = "legacy_ui_source_not_runtime_referenced"
        }
    }
}

$moveItems = [System.Collections.Generic.List[object]]::new()
foreach ($candidate in @($runtimeCandidates) + @($legacyUiCandidates)) {
    $file = $candidate.File
    $relativePath = Get-RepoRelativePath $file.FullName
    $moveItems.Add([pscustomobject]@{
        File = $file
        RelativePath = $relativePath
        Reason = $candidate.Reason
    })
    if ($file.Name -notlike "*.import") {
        $sidecarPath = $file.FullName + ".import"
        if (Test-Path -LiteralPath $sidecarPath) {
            $sidecar = Get-Item -LiteralPath $sidecarPath
            $moveItems.Add([pscustomobject]@{
                File = $sidecar
                RelativePath = Get-RepoRelativePath $sidecar.FullName
                Reason = "import_sidecar_of_" + $candidate.Reason
            })
        }
    }
}

$moveItems = @($moveItems | Sort-Object RelativePath -Unique)
$primaryCount = @($moveItems | Where-Object { $_.RelativePath -notlike "*.import" }).Count
$sidecarCount = @($moveItems | Where-Object { $_.RelativePath -like "*.import" }).Count
$totalBytes = ($moveItems | ForEach-Object { $_.File.Length } | Measure-Object -Sum).Sum

Write-Output ("mode={0} primary={1} sidecars={2} total_files={3} total_mb={4}" -f `
    $Mode, $primaryCount, $sidecarCount, $moveItems.Count, [math]::Round($totalBytes / 1MB, 2))
$moveItems |
    Where-Object { $_.RelativePath -notlike "*.import" } |
    Group-Object { Split-Path $_.RelativePath -Parent } |
    Sort-Object Count -Descending |
    ForEach-Object { Write-Output ("{0}`t{1}" -f $_.Count, $_.Name) }

if ($Mode -eq "Analyze") {
    return
}

Assert-PathInside $reviewRoot (Join-Path $repoRoot "asset_review_delete")
if (Test-Path -LiteralPath $reviewRoot) {
    throw "Review batch already exists: $reviewRoot"
}
[void](New-Item -ItemType Directory -Path $reviewRoot -Force)

$manifestRows = [System.Collections.Generic.List[object]]::new()
foreach ($item in $moveItems) {
    $sourcePath = $item.File.FullName
    Assert-PathInside $sourcePath (Join-Path $repoRoot "assets")
    $targetPath = Join-Path $reviewRoot $item.RelativePath.Replace("/", "\")
    Assert-PathInside $targetPath $reviewRoot
    if (Test-Path -LiteralPath $targetPath) {
        throw "Target collision: $targetPath"
    }
    $targetDirectory = Split-Path -Parent $targetPath
    [void](New-Item -ItemType Directory -Path $targetDirectory -Force)
    $hash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToLowerInvariant()
    $manifestRows.Add([pscustomobject]@{
        original_path = $item.RelativePath
        target_path = Get-RepoRelativePath $targetPath
        action = "move_review"
        reason = $item.Reason
        bytes = $item.File.Length
        sha256 = $hash
    })
    Move-Item -LiteralPath $sourcePath -Destination $targetPath
}

foreach ($sourceRoot in @($legacyUiRoot, $runtimeRoot)) {
    if (-not (Test-Path -LiteralPath $sourceRoot)) {
        continue
    }
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -Directory |
        Sort-Object FullName -Descending |
        ForEach-Object {
            if ((Get-ChildItem -LiteralPath $_.FullName -Force | Measure-Object).Count -eq 0) {
                Remove-Item -LiteralPath $_.FullName
            }
        }
}
if (Test-Path -LiteralPath $legacyUiRoot) {
    if ((Get-ChildItem -LiteralPath $legacyUiRoot -Force | Measure-Object).Count -eq 0) {
        Remove-Item -LiteralPath $legacyUiRoot
    }
}

$manifestPath = Join-Path (Split-Path -Parent $reviewRoot) "manifest.csv"
$manifestRows | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding utf8
Write-Output ("manifest={0}" -f (Get-RepoRelativePath $manifestPath))
