param([string]$Root='D:\UGit\T0\To')
$ErrorActionPreference='Stop'
$source=Join-Path $Root 'Migration/Baselines/godot_2026-09-11_v01/Source'
$out=Join-Path $Root 'Assets/MergeTo10/Resources/M1Art'
New-Item -ItemType Directory -Path $out -Force | Out-Null
$regions=@()
$copies=@{}
$oracle=Get-Content (Join-Path $Root 'Migration/Baselines/godot_2026-09-11_v01/Reports/board_oracle.json') -Raw | ConvertFrom-Json
$entries=@()
foreach($color in @('green','blue','yellow','purple','red')){
 $entries+=@{key='tile_'+$color;path=('assets/runtime/ui/components/board_tiles/atlas_regions/block_'+$color+'.tres')}
}
foreach($level in $oracle.levels){$entries+=@{key='glyph_'+$level.level;path=$level.glyph.Replace('res://','')}}
foreach($entry in $entries){
 $text=Get-Content -LiteralPath (Join-Path $source $entry.path) -Raw
 $atlas=[regex]::Match($text,'path="res://([^"]+)"').Groups[1].Value
 $match=[regex]::Match($text,'region = Rect2\(([^)]+)\)')
 if(-not $match.Success){throw 'Unsupported atlas resource'}
 $rect=@($match.Groups[1].Value.Split(',') | ForEach-Object {[float]::Parse($_,[Globalization.CultureInfo]::InvariantCulture)})
 $name=[IO.Path]::GetFileNameWithoutExtension($atlas)
 $copies[$name]=Join-Path $source $atlas
 $regions+=@{key=$entry.key;texture=$name;x=$rect[0];y=$rect[1];width=$rect[2];height=$rect[3]}
}
$copies['background']=Join-Path $source 'assets/runtime/ui/interfaces/battle/standalone/battle_background.png'
$copies['board_plate']=Join-Path $source 'assets/runtime/ui/interfaces/battle/board/standalone/battle_board_backdrop.png'
$copies['merge_sheet']=Join-Path $source 'assets/runtime/fx/merge/atlases/merge_sheet.png'
$records=@()
foreach($name in $copies.Keys){
 $target=Join-Path $out ($name+'.png')
 Copy-Item -LiteralPath $copies[$name] -Destination $target
 $records+=@{target=$target;source=$copies[$name];sha256=(Get-FileHash $target -Algorithm SHA256).Hash}
}
@{regions=$regions} | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $out 'regions.json') -Encoding utf8
$records | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $Root 'Migration/m1_assets_manifest.json') -Encoding utf8
Copy-Item -LiteralPath (Join-Path $source 'assets/runtime/audio/click.mp3'),(Join-Path $source 'assets/runtime/audio/merge.mp3') -Destination $out
Write-Output "M1_ASSETS_READY regions=$($regions.Count) textures=$($copies.Count)"

