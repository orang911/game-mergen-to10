param(
 [string]$UnityDirectory='D:\UGit\T0\To\Builds\M1V02\Verified470x836',
 [string]$ReferenceDirectory='D:\UGit\T0\To\Migration\Reports\M1V02'
)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
function Measure-Region($a,$b,[int]$left,[int]$top,[int]$width,[int]$height) {
 $values=[Collections.Generic.List[double]]::new()
 $max=0.0
 for($y=$top;$y -lt ($top+$height);$y+=2) {
  for($x=$left;$x -lt ($left+$width);$x+=2) {
   $p=$a.GetPixel($x,$y);$q=$b.GetPixel($x,$y)
   $error=([Math]::Abs([int]$p.R-$q.R)+[Math]::Abs([int]$p.G-$q.G)+[Math]::Abs([int]$p.B-$q.B))/3.0
   $values.Add($error);$max=[Math]::Max($max,$error)
  }
 }
 $sorted=$values.ToArray();[Array]::Sort($sorted)
 return @{samples=$values.Count;meanRgbError=($values|Measure-Object -Average).Average;p95RgbError=$sorted[[int][Math]::Floor(.95*($sorted.Length-1))];maxRgbError=$max}
}
$source=[Drawing.Bitmap]::new((Join-Path $ReferenceDirectory 'godot-initial.png'))
$ported=[Drawing.Bitmap]::new((Join-Path $UnityDirectory '01-initial.png'))
$ghostSource=[Drawing.Bitmap]::new((Join-Path $ReferenceDirectory 'godot-ghost-probe.png'))
$ghostPorted=[Drawing.Bitmap]::new((Join-Path $UnityDirectory '04-ghost-probe.png'))
try {
 if($source.Size -ne $ported.Size -or $ghostSource.Size -ne $ghostPorted.Size){throw 'Image dimensions differ; do not rescale reference images to hide layout differences.'}
 $report=@{
  comparison='Godot frozen visual classes vs Unity, same 470x836 fixture, RGB 0..255'
  board=Measure-Region $source $ported 80 365 305 300
  background=Measure-Region $source $ported 0 0 470 340
  ghostProbe=Measure-Region $ghostSource $ghostPorted 235 477 72 72
  note='Informational error metrics, not a declaration of pixel-exact parity. Includes filtering and alpha-blending differences.'
 }
 $json=$report|ConvertTo-Json -Depth 5
 $json|Set-Content -LiteralPath (Join-Path $UnityDirectory 'godot-visual-comparison.json') -Encoding utf8
 $json
} finally {$source.Dispose();$ported.Dispose();$ghostSource.Dispose();$ghostPorted.Dispose()}

