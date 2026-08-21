param(
    [string]$BaselineRoot = ".tmp/atlas_verify_baseline_2026-08-20"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Resolve-RepoPath([string]$relativePath) {
    $absolute = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $relativePath.Replace("/", "\")))
    $rootPrefix = $repoRoot.TrimEnd("\") + "\"
    if (-not $absolute.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path escapes repository: $relativePath"
    }
    return $absolute
}

$atlasPaths = @(
    "assets/runtime/characters/monsters/atlases/slime_stage_01_walk_sheet.png",
    "assets/runtime/characters/monsters/atlases/slime_stage_01_hit_sheet.png",
    "assets/runtime/characters/monsters/atlases/monster_death_sheet.png",
    "assets/runtime/characters/monsters/atlases/tutorial_armored_walk_sheet.png",
    "assets/runtime/characters/monsters/atlases/tutorial_armored_hit_sheet.png",
    "assets/runtime/fx/merge/atlases/merge_sheet.png",
    "assets/runtime/fx/elements/lightning/atlases/beam_sheet.png",
    "assets/runtime/fx/portal/atlases/gate_portal_sheet_mobile.png",
    "assets/runtime/ui/components/board_tiles/atlases/block_tiles_sheet.png",
    "assets/runtime/ui/components/board_glyphs/atlases/block_glyphs_sheet.png",
    "assets/runtime/ui/components/card_icons/atlases/card_icons_sheet.png",
    "assets/runtime/ui/shared/meta_icons/atlases/lobby_icons_sheet.png"
)

function Compare-Pixels([string]$aPath, [string]$bPath) {
    $a = [System.Drawing.Bitmap]::new($aPath)
    try {
        $b = [System.Drawing.Bitmap]::new($bPath)
        try {
            if ($a.Width -ne $b.Width -or $a.Height -ne $b.Height) {
                return "DIMENSION_MISMATCH a=$($a.Width)x$($a.Height) b=$($b.Width)x$($b.Height)"
            }
            $rect = [System.Drawing.Rectangle]::new(0, 0, $a.Width, $a.Height)
            $aData = $a.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            try {
                $bData = $b.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
                try {
                    $byteCount = [Math]::Abs($aData.Stride) * $a.Height
                    $aBytes = [byte[]]::new($byteCount)
                    $bBytes = [byte[]]::new($byteCount)
                    [System.Runtime.InteropServices.Marshal]::Copy($aData.Scan0, $aBytes, 0, $byteCount)
                    [System.Runtime.InteropServices.Marshal]::Copy($bData.Scan0, $bBytes, 0, $byteCount)
                    for ($i = 0; $i -lt $byteCount; $i++) {
                        if ($aBytes[$i] -ne $bBytes[$i]) {
                            $pixelIndex = [Math]::Floor($i / 4)
                            $x = $pixelIndex % $a.Width
                            $y = [Math]::Floor($pixelIndex / $a.Width)
                            return "PIXEL_MISMATCH at ($x,$y) byte=$i"
                        }
                    }
                    return "PIXEL_MATCH"
                } finally {
                    $b.UnlockBits($bData)
                }
            } finally {
                $a.UnlockBits($aData)
            }
        } finally {
            $b.Dispose()
        }
    } finally {
        $a.Dispose()
    }
}

$allMatch = $true
foreach ($rel in $atlasPaths) {
    $baseline = Resolve-RepoPath (Join-Path $BaselineRoot $rel)
    $current = Resolve-RepoPath $rel
    $result = Compare-Pixels $baseline $current
    if ($result -ne "PIXEL_MATCH") {
        $allMatch = $false
    }
    Write-Output ("{0} {1}" -f $result, $rel)
}

if ($allMatch) {
    Write-Output "ATLAS_PIXEL_COMPARE_OK all=$($atlasPaths.Count)"
} else {
    Write-Output "ATLAS_PIXEL_COMPARE_MISMATCH"
    exit 1
}
