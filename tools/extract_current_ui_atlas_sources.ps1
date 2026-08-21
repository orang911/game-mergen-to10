param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputRootRelative = "art/production/ui/runtime_atlas_sources/2026-08-20"
$outputRoot = Join-Path $repoRoot $outputRootRelative.Replace("/", "\")

$groups = @(
    @{
        Name = "board_tiles"
        RegionRoot = "assets/runtime/ui/components/board_tiles/atlas_regions"
    },
    @{
        Name = "board_glyphs"
        RegionRoot = "assets/runtime/ui/components/board_glyphs/atlas_regions"
    },
    @{
        Name = "card_icons"
        RegionRoot = "assets/runtime/ui/components/card_icons/atlas_regions"
    },
    @{
        Name = "meta_icons"
        RegionRoot = "assets/runtime/ui/shared/meta_icons/atlas_regions"
    }
)

function Resolve-RepoPath([string]$relativePath) {
    $absolute = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $relativePath.Replace("/", "\")))
    $rootPrefix = $repoRoot.TrimEnd("\") + "\"
    if (-not $absolute.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path escapes repository: $relativePath"
    }
    return $absolute
}

function Parse-AtlasRegion([string]$regionPath) {
    $text = [System.IO.File]::ReadAllText($regionPath)
    $atlasMatch = [regex]::Match($text, 'path\s*=\s*"res://([^"]+)"')
    $regionMatch = [regex]::Match($text, 'region\s*=\s*Rect2\(\s*([0-9.-]+)\s*,\s*([0-9.-]+)\s*,\s*([0-9.-]+)\s*,\s*([0-9.-]+)\s*\)')
    if (-not $atlasMatch.Success -or -not $regionMatch.Success) {
        throw "Unable to parse AtlasTexture resource: $regionPath"
    }
    return @{
        Atlas = $atlasMatch.Groups[1].Value.Replace("\", "/")
        X = [int][double]$regionMatch.Groups[1].Value
        Y = [int][double]$regionMatch.Groups[2].Value
        Width = [int][double]$regionMatch.Groups[3].Value
        Height = [int][double]$regionMatch.Groups[4].Value
    }
}

$plans = [System.Collections.Generic.List[object]]::new()
foreach ($group in $groups) {
    $regionRoot = Resolve-RepoPath $group.RegionRoot
    if (-not (Test-Path -LiteralPath $regionRoot -PathType Container)) {
        throw "Region directory is missing: $($group.RegionRoot)"
    }
    $regionFiles = @(Get-ChildItem -LiteralPath $regionRoot -Filter "*.tres" -File | Sort-Object Name)
    if ($regionFiles.Count -eq 0) {
        throw "No AtlasTexture resources found: $($group.RegionRoot)"
    }
    foreach ($regionFile in $regionFiles) {
        $parsed = Parse-AtlasRegion $regionFile.FullName
        $atlasAbsolute = Resolve-RepoPath $parsed.Atlas
        if (-not (Test-Path -LiteralPath $atlasAbsolute -PathType Leaf)) {
            throw "Atlas sheet is missing: $($parsed.Atlas)"
        }
        $outputRelative = "$outputRootRelative/$($group.Name)/$($regionFile.BaseName).png"
        $plans.Add([pscustomobject]@{
            Group = $group.Name
            Region = $group.RegionRoot + "/" + $regionFile.Name
            Atlas = $parsed.Atlas
            AtlasAbsolute = $atlasAbsolute
            Output = $outputRelative
            OutputAbsolute = Resolve-RepoPath $outputRelative
            X = $parsed.X
            Y = $parsed.Y
            Width = $parsed.Width
            Height = $parsed.Height
        })
    }
}

if ($plans.Count -ne 72) {
    throw "Expected 72 UI AtlasTexture regions, found $($plans.Count)."
}

$duplicateOutputs = @($plans | Group-Object Output | Where-Object Count -gt 1)
if ($duplicateOutputs.Count -gt 0) {
    throw "Duplicate extracted-source paths: $($duplicateOutputs.Name -join ', ')"
}

foreach ($plan in $plans) {
    $bitmap = [System.Drawing.Bitmap]::new($plan.AtlasAbsolute)
    try {
        if ($plan.X -lt 0 -or $plan.Y -lt 0 -or $plan.Width -le 0 -or $plan.Height -le 0 -or
            ($plan.X + $plan.Width) -gt $bitmap.Width -or ($plan.Y + $plan.Height) -gt $bitmap.Height) {
            throw "Region is outside atlas bounds: $($plan.Region)"
        }
    } finally {
        $bitmap.Dispose()
    }
    if ((Test-Path -LiteralPath $plan.OutputAbsolute) -and -not $Force) {
        throw "Output already exists; pass -Force to replace this exact source: $($plan.Output)"
    }
}

$records = [System.Collections.Generic.List[object]]::new()
foreach ($plan in $plans) {
    $parent = Split-Path -Parent $plan.OutputAbsolute
    if (-not (Test-Path -LiteralPath $parent)) {
        [void](New-Item -ItemType Directory -Path $parent -Force)
    }
    $bitmap = [System.Drawing.Bitmap]::new($plan.AtlasAbsolute)
    try {
        $rect = [System.Drawing.Rectangle]::new($plan.X, $plan.Y, $plan.Width, $plan.Height)
        $crop = $bitmap.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $crop.Save($plan.OutputAbsolute, [System.Drawing.Imaging.ImageFormat]::Png)
        } finally {
            $crop.Dispose()
        }
    } finally {
        $bitmap.Dispose()
    }
    $hash = (Get-FileHash -LiteralPath $plan.OutputAbsolute -Algorithm SHA256).Hash.ToLowerInvariant()
    $records.Add([pscustomobject]@{
        group = $plan.Group
        output_path = $plan.Output
        atlas_path = $plan.Atlas
        atlas_region_resource = $plan.Region
        x = $plan.X
        y = $plan.Y
        width = $plan.Width
        height = $plan.Height
        sha256 = $hash
        provenance = "lossless_crop_from_current_runtime_atlas"
    })
}

$manifestPath = Join-Path $outputRoot "manifest.csv"
$records | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding utf8

$groupSummary = $records | Group-Object group | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Count)" }
Write-Output ("UI_ATLAS_SOURCES_EXTRACTED total={0} {1}" -f $records.Count, ($groupSummary -join " "))
Write-Output ("MANIFEST {0}" -f ($manifestPath.Substring($repoRoot.Length + 1).Replace("\", "/")))
