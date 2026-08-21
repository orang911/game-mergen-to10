param(
    [ValidateSet("Build", "Verify", "ArchiveSources", "ExtractSources")]
    [string]$Mode = "Build",
    [ValidateSet("All", "UI")]
    [string]$Scope = "All"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$archiveSourceRoot = Join-Path $repoRoot "asset_review_delete\2026-08-11_android_packaging\atlas_sources"
$mobileFixSourceRoot = Join-Path $repoRoot "asset_review_delete\2026-08-11_android_mobile_fix\atlas_sources"
$mobileAtlasLimit = 2048
$uiAtlasSourceRoot = "art/production/ui/runtime_atlas_sources/2026-08-20"
$characterAtlasSourceRoot = "art/production/characters/runtime_atlas_sources/2026-08-20"
$fxAtlasSourceRoot = "art/production/fx/runtime_atlas_sources/2026-08-20"

function Resolve-RepoPath([string]$relativePath) {
    return Join-Path $repoRoot $relativePath.Replace("/", "\")
}

function Resolve-AtlasSourcePath([string]$relativePath) {
    $runtimePath = Resolve-RepoPath $relativePath
    if (Test-Path -LiteralPath $runtimePath) {
        return $runtimePath
    }
    $archivedPath = Join-Path $archiveSourceRoot $relativePath.Replace("/", "\")
    if (Test-Path -LiteralPath $archivedPath) {
        return $archivedPath
    }
    $mobileFixPath = Join-Path $mobileFixSourceRoot $relativePath.Replace("/", "\")
    if (Test-Path -LiteralPath $mobileFixPath) {
        return $mobileFixPath
    }
    throw "Missing atlas source: $relativePath"
}

function Ensure-Parent([string]$path) {
    $parent = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $parent)) {
        [void](New-Item -ItemType Directory -Path $parent -Force)
    }
}

function Write-AtlasRegion(
    [string]$atlasResourcePath,
    [string]$regionResourcePath,
    [int]$x,
    [int]$y,
    [int]$width,
    [int]$height
) {
    $absolutePath = Resolve-RepoPath $regionResourcePath
    Ensure-Parent $absolutePath
    $content = @"
[gd_resource type="AtlasTexture" load_steps=2 format=3]

[ext_resource type="Texture2D" path="res://$atlasResourcePath" id="1_atlas"]

[resource]
atlas = ExtResource("1_atlas")
region = Rect2($x, $y, $width, $height)
filter_clip = true
"@
    [System.IO.File]::WriteAllText($absolutePath, $content.Replace("`r`n", "`n"), [System.Text.UTF8Encoding]::new($false))
}

function Test-RegionHasAlpha(
    [System.Drawing.Bitmap]$bitmap,
    [System.Drawing.Rectangle]$region
) {
    $data = $bitmap.LockBits(
        $region,
        [System.Drawing.Imaging.ImageLockMode]::ReadOnly,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )
    try {
        $byteCount = [Math]::Abs($data.Stride) * $region.Height
        $bytes = [byte[]]::new($byteCount)
        [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $byteCount)
        for ($row = 0; $row -lt $region.Height; $row++) {
            $rowOffset = $row * [Math]::Abs($data.Stride)
            for ($column = 0; $column -lt $region.Width; $column++) {
                if ($bytes[$rowOffset + $column * 4 + 3] -gt 0) {
                    return $true
                }
            }
        }
        return $false
    } finally {
        $bitmap.UnlockBits($data)
    }
}

function Build-Atlas([hashtable]$group) {
    $sources = @($group.Sources)
    $columns = [int]$group.Columns
    $cellWidth = [int]$group.CellWidth
    $cellHeight = [int]$group.CellHeight
    $padding = if ($group.ContainsKey("Padding")) { [int]$group.Padding } else { 0 }
    $resizeSources = $group.ContainsKey("ResizeSources") -and [bool]$group.ResizeSources
    $pitchWidth = $cellWidth + $padding * 2
    $pitchHeight = $cellHeight + $padding * 2
    $rows = [int][Math]::Ceiling($sources.Count / [double]$columns)
    $atlasWidth = $columns * $pitchWidth
    $atlasHeight = $rows * $pitchHeight
    $outputPath = Resolve-RepoPath $group.Output
    Ensure-Parent $outputPath

    if ($atlasWidth -gt $mobileAtlasLimit -or $atlasHeight -gt $mobileAtlasLimit) {
        throw "Mobile atlas exceeds ${mobileAtlasLimit}px: $($group.Output) ${atlasWidth}x${atlasHeight}"
    }

    if ($Mode -eq "Verify") {
        if (-not (Test-Path -LiteralPath $outputPath)) {
            throw "Missing atlas: $($group.Output)"
        }
        $atlas = [System.Drawing.Bitmap]::new($outputPath)
        try {
            if ($atlas.Width -ne $atlasWidth -or $atlas.Height -ne $atlasHeight) {
                throw "Unexpected atlas dimensions: $($group.Output)"
            }
            for ($index = 0; $index -lt $sources.Count; $index++) {
                $source = $sources[$index]
                $sourcePath = Resolve-AtlasSourcePath $source.Path
                $image = [System.Drawing.Image]::FromFile($sourcePath)
                try {
                    $frameWidth = if ($resizeSources -or $source.ContainsKey("SourceRect")) { $cellWidth } else { $image.Width }
                    $frameHeight = if ($resizeSources -or $source.ContainsKey("SourceRect")) { $cellHeight } else { $image.Height }
                    $x = ($index % $columns) * $pitchWidth + $padding
                    $y = [Math]::Floor($index / $columns) * $pitchHeight + $padding
                    if (-not (Test-RegionHasAlpha $atlas ([System.Drawing.Rectangle]::new($x, $y, $frameWidth, $frameHeight)))) {
                        throw "Transparent atlas frame: $($group.Output) index=$index source=$($source.Path)"
                    }
                } finally {
                    $image.Dispose()
                }
            }
        } finally {
            $atlas.Dispose()
        }
        return
    }

    $bitmap = [System.Drawing.Bitmap]::new(
        $atlasWidth,
        $atlasHeight,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )
    $bitmap.SetResolution(96.0, 96.0)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.Clear([System.Drawing.Color]::Transparent)
        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        for ($index = 0; $index -lt $sources.Count; $index++) {
            $source = $sources[$index]
            $sourcePath = Resolve-AtlasSourcePath $source.Path
            $image = [System.Drawing.Image]::FromFile($sourcePath)
            try {
                if (-not $resizeSources -and -not $source.ContainsKey("SourceRect") -and ($image.Width -gt $cellWidth -or $image.Height -gt $cellHeight)) {
                    throw "Atlas cell too small for $($source.Path)"
                }
                $frameWidth = if ($resizeSources -or $source.ContainsKey("SourceRect")) { $cellWidth } else { $image.Width }
                $frameHeight = if ($resizeSources -or $source.ContainsKey("SourceRect")) { $cellHeight } else { $image.Height }
                $x = ($index % $columns) * $pitchWidth + $padding
                $y = [Math]::Floor($index / $columns) * $pitchHeight + $padding
                $sourceRect = if ($source.ContainsKey("SourceRect")) {
                    $source.SourceRect
                } else {
                    [System.Drawing.Rectangle]::new(0, 0, $image.Width, $image.Height)
                }
                $graphics.DrawImage(
                    $image,
                    [System.Drawing.Rectangle]::new($x, $y, $frameWidth, $frameHeight),
                    $sourceRect.X,
                    $sourceRect.Y,
                    $sourceRect.Width,
                    $sourceRect.Height,
                    [System.Drawing.GraphicsUnit]::Pixel
                )
                if ($source.ContainsKey("Region")) {
                    Write-AtlasRegion $group.Output $source.Region $x $y $frameWidth $frameHeight
                }
            } finally {
                $image.Dispose()
            }
        }
    } finally {
        $graphics.Dispose()
    }
    try {
        for ($index = 0; $index -lt $sources.Count; $index++) {
            $source = $sources[$index]
            $sourcePath = Resolve-AtlasSourcePath $source.Path
            $image = [System.Drawing.Image]::FromFile($sourcePath)
            try {
                $frameWidth = if ($resizeSources -or $source.ContainsKey("SourceRect")) { $cellWidth } else { $image.Width }
                $frameHeight = if ($resizeSources -or $source.ContainsKey("SourceRect")) { $cellHeight } else { $image.Height }
                $x = ($index % $columns) * $pitchWidth + $padding
                $y = [Math]::Floor($index / $columns) * $pitchHeight + $padding
                if (-not (Test-RegionHasAlpha $bitmap ([System.Drawing.Rectangle]::new($x, $y, $frameWidth, $frameHeight)))) {
                    throw "Generated transparent atlas frame: $($group.Output) index=$index source=$($source.Path)"
                }
            } finally {
                $image.Dispose()
            }
        }
        $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $bitmap.Dispose()
    }
    Write-Output ("BUILT {0} {1}x{2} frames={3}" -f @(
        $group.Output,
        $atlasWidth,
        $atlasHeight,
        $sources.Count
    ))
}

function Numbered-Sources([string]$format, [int]$start, [int]$count) {
    $items = @()
    for ($index = $start; $index -lt $start + $count; $index++) {
        $items += @{ Path = $format -f $index }
    }
    return $items
}

function Extract-Sources {
    $nonUiGroups = @($groups | Where-Object { $_.Output -notlike "assets/runtime/ui/*" })
    if ($nonUiGroups.Count -ne 8) {
        throw "Expected 8 non-UI atlas groups, found $($nonUiGroups.Count)."
    }
    $records = [System.Collections.Generic.List[object]]::new()
    foreach ($group in $nonUiGroups) {
        $outputPath = Resolve-RepoPath $group.Output
        if (-not (Test-Path -LiteralPath $outputPath -PathType Leaf)) {
            throw "Missing atlas for source extraction: $($group.Output)"
        }
        $sources = @($group.Sources)
        $columns = [int]$group.Columns
        $cellWidth = [int]$group.CellWidth
        $cellHeight = [int]$group.CellHeight
        $padding = if ($group.ContainsKey("Padding")) { [int]$group.Padding } else { 0 }
        $pitchWidth = $cellWidth + $padding * 2
        $pitchHeight = $cellHeight + $padding * 2
        $atlas = [System.Drawing.Bitmap]::new($outputPath)
        try {
            for ($index = 0; $index -lt $sources.Count; $index++) {
                $source = $sources[$index]
                $x = ($index % $columns) * $pitchWidth + $padding
                $y = [Math]::Floor($index / $columns) * $pitchHeight + $padding
                $rect = [System.Drawing.Rectangle]::new($x, $y, $cellWidth, $cellHeight)
                if (($rect.X + $rect.Width) -gt $atlas.Width -or ($rect.Y + $rect.Height) -gt $atlas.Height) {
                    throw "Frame rect outside atlas bounds: $($group.Output) index=$index"
                }
                $crop = $atlas.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
                try {
                    $sourceAbsolute = Resolve-RepoPath $source.Path
                    Ensure-Parent $sourceAbsolute
                    $crop.Save($sourceAbsolute, [System.Drawing.Imaging.ImageFormat]::Png)
                } finally {
                    $crop.Dispose()
                }
                $hash = (Get-FileHash -LiteralPath $sourceAbsolute -Algorithm SHA256).Hash.ToLowerInvariant()
                $records.Add([pscustomobject]@{
                    output_atlas = $group.Output
                    source_path = $source.Path
                    x = $x
                    y = $y
                    width = $cellWidth
                    height = $cellHeight
                    sha256 = $hash
                    provenance = "lossless_crop_from_current_runtime_atlas"
                })
            }
        } finally {
            $atlas.Dispose()
        }
    }
    if ($records.Count -ne 114) {
        throw "Expected 114 non-UI atlas source frames, extracted $($records.Count)."
    }
    $manifestPath = Resolve-RepoPath "art/production/non_ui_runtime_atlas_sources_manifest_2026-08-20.csv"
    $records | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding utf8
    Write-Output ("NON_UI_ATLAS_SOURCES_EXTRACTED total={0}" -f $records.Count)
    Write-Output ("MANIFEST {0}" -f ($manifestPath.Substring($repoRoot.Length + 1).Replace("\", "/")))
}

$groups = @(
    @{
        Output = "assets/runtime/characters/monsters/atlases/slime_stage_01_walk_sheet.png"
        CellWidth = 320; CellHeight = 320; Columns = 6; Padding = 4; ResizeSources = $true
        Sources = Numbered-Sources "$characterAtlasSourceRoot/slime_stage_01/walk/frame_{0:00}.png" 0 18
    },
    @{
        Output = "assets/runtime/characters/monsters/atlases/slime_stage_01_hit_sheet.png"
        CellWidth = 320; CellHeight = 320; Columns = 4; Padding = 4; ResizeSources = $true
        Sources = Numbered-Sources "$characterAtlasSourceRoot/slime_stage_01/hit/frame_{0:00}.png" 0 8
    },
    @{
        Output = "assets/runtime/characters/monsters/atlases/monster_death_sheet.png"
        CellWidth = 320; CellHeight = 320; Columns = 5; Padding = 4; ResizeSources = $true
        Sources = Numbered-Sources "$characterAtlasSourceRoot/die/C-{0}.png" 1 19
    },
    @{
        Output = "assets/runtime/characters/monsters/atlases/tutorial_armored_walk_sheet.png"
        CellWidth = 320; CellHeight = 320; Columns = 6; Padding = 4; ResizeSources = $true
        Sources = Numbered-Sources "$characterAtlasSourceRoot/xingzou_boos/goblin_stage_03_{0:00000}.png" 0 28
    },
    @{
        Output = "assets/runtime/characters/monsters/atlases/tutorial_armored_hit_sheet.png"
        CellWidth = 320; CellHeight = 320; Columns = 5; Padding = 4; ResizeSources = $true
        Sources = Numbered-Sources "$characterAtlasSourceRoot/xingzou_boos/shyouji-{0}.png" 1 5
    },
    @{
        Output = "assets/runtime/fx/merge/atlases/merge_sheet.png"
        CellWidth = 200; CellHeight = 200; Columns = 4; Padding = 4
        Sources = Numbered-Sources "$fxAtlasSourceRoot/merge/frame_{0:00}.png" 0 13
    },
    @{
        Output = "assets/runtime/fx/elements/lightning/atlases/beam_sheet.png"
        CellWidth = 258; CellHeight = 516; Columns = 3; Padding = 4
        Sources = Numbered-Sources "$fxAtlasSourceRoot/lightning_beam/frame_{0:00}.png" 0 3
    }
)

$blockSources = @()
foreach ($name in @("green", "blue", "yellow", "purple", "red")) {
    $blockSources += @{
        Path = "$uiAtlasSourceRoot/board_tiles/block_$name.png"
        Region = "assets/runtime/ui/components/board_tiles/atlas_regions/block_$name.tres"
    }
}
$groups += @{
    Output = "assets/runtime/ui/components/board_tiles/atlases/block_tiles_sheet.png"
    CellWidth = 304; CellHeight = 304; Columns = 5; Padding = 4; ResizeSources = $true; Sources = $blockSources
}

$glyphSources = @()
foreach ($number in 1..10) {
    $glyphSources += @{
        Path = "$uiAtlasSourceRoot/board_glyphs/number_$number.png"
        Region = "assets/runtime/ui/components/board_glyphs/atlas_regions/number_$number.tres"
    }
}
foreach ($letter in [char[]]([char]'a'..[char]'z')) {
    $glyphSources += @{
        Path = "$uiAtlasSourceRoot/board_glyphs/letter_$letter.png"
        Region = "assets/runtime/ui/components/board_glyphs/atlas_regions/letter_$letter.tres"
    }
}
$groups += @{
    Output = "assets/runtime/ui/components/board_glyphs/atlases/block_glyphs_sheet.png"
    CellWidth = 192; CellHeight = 160; Columns = 6; Padding = 4; Sources = $glyphSources
}

$cardIconNames = @(
    "castle_cannon", "dragon_catapult", "fire_conduit", "frost_bell",
    "frost_prism", "piercing_cannon", "poison_tank", "rapid_clockwork",
    "star_boiler", "thunder_ballista", "thunder_spire", "twin_lens",
    "ascension_hammer", "fate_shuffler", "twin_mold", "unity_dial"
)
$cardSources = @()
foreach ($name in $cardIconNames) {
    $cardSources += @{
        Path = "$uiAtlasSourceRoot/card_icons/$name.png"
        Region = "assets/runtime/ui/components/card_icons/atlas_regions/$name.tres"
    }
}
$groups += @{
    Output = "assets/runtime/ui/components/card_icons/atlases/card_icons_sheet.png"
    CellWidth = 384; CellHeight = 384; Columns = 4; Padding = 4; ResizeSources = $true; Sources = $cardSources
}

$hubSources = @()
$hubIconNames = @(
    "lobby_badge_alert_v01", "lobby_icon_ad_tv_v01", "lobby_icon_battle_crystal_v01",
    "lobby_icon_currency_coin_v01", "lobby_icon_currency_diamond_v01", "lobby_icon_double_coin_x2_v01",
    "lobby_icon_first_purchase_gift_v02", "lobby_icon_locked_v01", "lobby_icon_piggy_bank_v02",
    "lobby_icon_plus_v01", "lobby_icon_reward_star_wand_v01", "lobby_icon_settings_gear_v01",
    "lobby_icon_shop_v01", "lobby_icon_signin_calendar_v01", "lobby_icon_task_notebook_v01"
)
foreach ($name in $hubIconNames) {
    $hubSources += @{
        Path = "$uiAtlasSourceRoot/meta_icons/$name.png"
        Region = "assets/runtime/ui/shared/meta_icons/atlas_regions/$name.tres"
    }
}
$groups += @{
    Output = "assets/runtime/ui/shared/meta_icons/atlases/lobby_icons_sheet.png"
    CellWidth = 288; CellHeight = 288; Columns = 4; Padding = 4; Sources = $hubSources
}

# Portal uses the 20 extracted current-size (320x320) frames from the existing
# mobile runtime atlas. The historical high-resolution gate_portal_sheet.png is
# intentionally not referenced here.
$groups += @{
    Output = "assets/runtime/fx/portal/atlases/gate_portal_sheet_mobile.png"
    CellWidth = 320; CellHeight = 320; Columns = 5; Padding = 4
    Sources = Numbered-Sources "$fxAtlasSourceRoot/portal/frame_{0:00}.png" 0 20
}

if ($Scope -eq "UI") {
    $groups = @($groups | Where-Object { $_.Output.StartsWith("assets/runtime/ui/", [System.StringComparison]::OrdinalIgnoreCase) })
    if ($groups.Count -ne 4) {
        throw "Expected 4 UI atlas groups, found $($groups.Count)."
    }
}
elseif ($Scope -eq "All") {
    if ($groups.Count -ne 12) {
        throw "Expected 12 atlas groups (8 non-UI + 4 UI), found $($groups.Count)."
    }
    $nonUiGroupCount = @($groups | Where-Object { -not $_.Output.StartsWith("assets/runtime/ui/", [System.StringComparison]::OrdinalIgnoreCase) }).Count
    if ($nonUiGroupCount -ne 8) {
        throw "Expected 8 non-UI atlas groups, found $nonUiGroupCount."
    }
}

if ($Mode -eq "ArchiveSources") {
    $reviewRoot = Resolve-RepoPath "asset_review_delete/2026-08-11_android_packaging/atlas_sources"
    if (Test-Path -LiteralPath $reviewRoot) {
        throw "Review target already exists: $reviewRoot"
    }
    [void](New-Item -ItemType Directory -Path $reviewRoot -Force)
    $rows = [System.Collections.Generic.List[object]]::new()
    $sourcePaths = @($groups | ForEach-Object { $_.Sources } | ForEach-Object { $_.Path } | Sort-Object -Unique)
    foreach ($relativePath in $sourcePaths) {
        foreach ($candidate in @($relativePath, "$relativePath.import")) {
            $sourcePath = Resolve-RepoPath $candidate
            if (-not (Test-Path -LiteralPath $sourcePath)) {
                continue
            }
            $targetPath = Join-Path $reviewRoot $candidate.Replace("/", "\")
            Ensure-Parent $targetPath
            $hash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToLowerInvariant()
            $file = Get-Item -LiteralPath $sourcePath
            $rows.Add([pscustomobject]@{
                original_path = $candidate
                target_path = $targetPath.Substring($repoRoot.Length + 1).Replace("\", "/")
                action = "move_review_after_atlas"
                bytes = $file.Length
                sha256 = $hash
            })
            Move-Item -LiteralPath $sourcePath -Destination $targetPath
        }
    }
    $manifestPath = Resolve-RepoPath "asset_review_delete/2026-08-11_android_packaging/manifest.csv"
    $rows | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding utf8
    Write-Output ("ATLAS_SOURCES_ARCHIVED primary={0} total={1}" -f $sourcePaths.Count, $rows.Count)
    return
}

if ($Mode -eq "ExtractSources") {
    if ($Scope -ne "All") {
        throw "ExtractSources only supports -Scope All."
    }
    Extract-Sources
    return
}

foreach ($group in $groups) {
    Build-Atlas $group
}
Write-Output ("ATLAS_{0}_OK scope={1} groups={2}" -f $Mode.ToUpperInvariant(), $Scope.ToUpperInvariant(), $groups.Count)
