param(
    [string]$OutputRoot = "assets/runtime/ui/secondary_v2"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = Join-Path (Resolve-Path ".").Path $OutputRoot
$dirs = @("common", "icons", "icons/settings", "pages/pause", "pages/settings", "pages/daily", "pages/commerce", "pages/shop", "qa")
foreach ($dir in $dirs) { New-Item -ItemType Directory -Force -Path (Join-Path $root $dir) | Out-Null }

function Color([string]$hex) { return [System.Drawing.ColorTranslator]::FromHtml($hex) }
function Path-RoundRect([float]$x,[float]$y,[float]$w,[float]$h,[float]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $p.AddArc($x,$y,$d,$d,180,90); $p.AddArc($x+$w-$d,$y,$d,$d,270,90)
    $p.AddArc($x+$w-$d,$y+$h-$d,$d,$d,0,90); $p.AddArc($x,$y+$h-$d,$d,$d,90,90); $p.CloseFigure()
    return $p
}
function New-Canvas([int]$w,[int]$h) {
    $b = [System.Drawing.Bitmap]::new($w,$h,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $b.SetResolution(96,96)
    $g = [System.Drawing.Graphics]::FromImage($b)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)
    return @($b,$g)
}
function Save-Canvas($b,$g,[string]$relative) {
    $g.Dispose(); $path = Join-Path $root $relative
    $b.Save($path,[System.Drawing.Imaging.ImageFormat]::Png); $b.Dispose()
}
function Fill-Round($g,[float]$x,[float]$y,[float]$w,[float]$h,[float]$r,[string]$top,[string]$bottom,[string]$border="#203B5F",[float]$stroke=4) {
    $p = Path-RoundRect $x $y $w $h $r
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush ([System.Drawing.RectangleF]::new($x,$y,$w,$h)),(Color $top),(Color $bottom),90
    $g.FillPath($brush,$p); $brush.Dispose()
    if ($stroke -gt 0) { $pen=New-Object System.Drawing.Pen (Color $border),$stroke; $g.DrawPath($pen,$p); $pen.Dispose() }
    $p.Dispose()
}
function Draw-Highlight($g,[float]$x,[float]$y,[float]$w,[float]$h,[float]$r=10) {
    $pen=New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(185,255,255,255)),2
    $p=Path-RoundRect $x $y $w $h $r; $g.DrawPath($pen,$p); $pen.Dispose(); $p.Dispose()
}
function Draw-ButtonAsset([string]$name,[string]$top,[string]$bottom,[string]$border) {
    $c=New-Canvas 192 80; $b=$c[0]; $g=$c[1]
    Fill-Round $g 3 3 186 74 15 $top $bottom $border 5; Draw-Highlight $g 12 10 168 52 11
    Save-Canvas $b $g "common/$name.png"
}
function Draw-Panel([string]$name,[string]$top,[string]$bottom,[string]$border) {
    $c=New-Canvas 128 128; $b=$c[0]; $g=$c[1]
    Fill-Round $g 4 4 120 120 22 $top $bottom $border 6; Draw-Highlight $g 12 11 104 101 16
    Save-Canvas $b $g "common/$name.png"
}
function Draw-Symbol([string]$name,[scriptblock]$draw) {
    $c=New-Canvas 128 128; $b=$c[0]; $g=$c[1]; & $draw $g; Save-Canvas $b $g "icons/$name.png"
}
function Draw-PageSymbol([string]$relative,[int]$w,[int]$h,[scriptblock]$draw) {
    $c=New-Canvas $w $h; $b=$c[0]; $g=$c[1]; & $draw $g; Save-Canvas $b $g $relative
}
function Poly($g,[string]$fill,[string]$border,[float]$stroke,[System.Drawing.PointF[]]$points) {
    $br=New-Object System.Drawing.SolidBrush (Color $fill); $g.FillPolygon($br,$points); $br.Dispose()
    if($stroke -gt 0){$pn=New-Object System.Drawing.Pen (Color $border),$stroke; $pn.LineJoin=[System.Drawing.Drawing2D.LineJoin]::Round; $g.DrawPolygon($pn,$points); $pn.Dispose()}
}
function Ellipse($g,[float]$x,[float]$y,[float]$w,[float]$h,[string]$fill,[string]$border="#24374F",[float]$stroke=4){
    $br=New-Object System.Drawing.SolidBrush (Color $fill); $g.FillEllipse($br,$x,$y,$w,$h); $br.Dispose()
    if($stroke -gt 0){$pn=New-Object System.Drawing.Pen (Color $border),$stroke; $g.DrawEllipse($pn,$x,$y,$w,$h); $pn.Dispose()}
}
function Rect($g,[float]$x,[float]$y,[float]$w,[float]$h,[string]$fill,[string]$border="#24374F",[float]$stroke=4){
    $br=New-Object System.Drawing.SolidBrush (Color $fill); $g.FillRectangle($br,$x,$y,$w,$h); $br.Dispose()
    if($stroke -gt 0){$pn=New-Object System.Drawing.Pen (Color $border),$stroke; $g.DrawRectangle($pn,$x,$y,$w,$h); $pn.Dispose()}
}

# Common scalable foundations.
Draw-Panel "panel_light" "#F8FCFF" "#D8E9FA" "#173A62"
Draw-Panel "panel_dark" "#173F73" "#0B2246" "#06152B"
Draw-ButtonAsset "button_blue_default" "#339BFF" "#0862C6" "#07366E"
Draw-ButtonAsset "button_blue_pressed" "#1675D7" "#064FA6" "#062D5B"
Draw-ButtonAsset "button_red_default" "#F45F5B" "#C92D32" "#73161F"
Draw-ButtonAsset "button_red_pressed" "#D43C42" "#A71E29" "#5A1118"
Draw-ButtonAsset "button_yellow_default" "#FFD45B" "#F29A13" "#9A5306"
Draw-ButtonAsset "button_yellow_pressed" "#F4B72C" "#DC7D0B" "#774008"
Draw-ButtonAsset "button_green_default" "#9BDD54" "#52A921" "#2E6814"
Draw-ButtonAsset "button_gray_disabled" "#DDE5EC" "#A8B4C1" "#687786"

$c=New-Canvas 480 92; $b=$c[0]; $g=$c[1]
$tailL=[System.Drawing.PointF[]]@([System.Drawing.PointF]::new(4,24),[System.Drawing.PointF]::new(76,24),[System.Drawing.PointF]::new(76,78),[System.Drawing.PointF]::new(18,78),[System.Drawing.PointF]::new(36,54))
$tailR=[System.Drawing.PointF[]]@([System.Drawing.PointF]::new(476,24),[System.Drawing.PointF]::new(404,24),[System.Drawing.PointF]::new(404,78),[System.Drawing.PointF]::new(462,78),[System.Drawing.PointF]::new(444,54))
Poly $g "#1F67CE" "#103D83" 4 $tailL; Poly $g "#1F67CE" "#103D83" 4 $tailR
Fill-Round $g 52 5 376 72 15 "#428BF0" "#1A51B1" "#143C78" 5; Draw-Highlight $g 65 11 350 48 11
Save-Canvas $b $g "common/title_ribbon_blue.png"

$c=New-Canvas 420 88; $b=$c[0]; $g=$c[1]; Fill-Round $g 2 2 416 84 16 "#F8FCFF" "#DDECF9" "#88A8CC" 3; Draw-Highlight $g 10 8 400 60 12; Save-Canvas $b $g "common/row_light.png"
$c=New-Canvas 180 64; $b=$c[0]; $g=$c[1]; Fill-Round $g 2 2 176 60 12 "#3D8DF2" "#1B59BD" "#153D77" 4; Save-Canvas $b $g "common/tab_selected.png"
$c=New-Canvas 180 64; $b=$c[0]; $g=$c[1]; Fill-Round $g 2 2 176 60 12 "#EAF3FC" "#C7D8E8" "#7E9CB9" 3; Save-Canvas $b $g "common/tab_default.png"
$c=New-Canvas 240 32; $b=$c[0]; $g=$c[1]; Fill-Round $g 2 2 236 28 13 "#4B6075" "#27394D" "#1D2B3A" 2; Save-Canvas $b $g "common/progress_track.png"
$c=New-Canvas 240 32; $b=$c[0]; $g=$c[1]; Fill-Round $g 2 2 236 28 13 "#A8E93E" "#57AE10" "#34760A" 2; Save-Canvas $b $g "common/progress_fill.png"

foreach($state in @(@("switch_on","#7EDB1E","#3B9B0D",82),@("switch_off","#BCC4CC","#7E8994",34))){
    $c=New-Canvas 112 60; $b=$c[0]; $g=$c[1]; Fill-Round $g 2 2 108 56 27 $state[1] $state[2] "#506071" 3
    Ellipse $g ([float]$state[3]) 8 42 42 "#F8FAFC" "#64717C" 2; Save-Canvas $b $g ("common/"+$state[0]+".png")
}

# Core UI icons, redrawn without text from the visual language of the references.
Draw-Symbol "back" { param($g) Fill-Round $g 15 18 98 92 25 "#43B8FF" "#1571D4" "#093A75" 5; Poly $g "#FFFFFF" "#244665" 4 ([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(68,38),[System.Drawing.PointF]::new(42,64),[System.Drawing.PointF]::new(68,90),[System.Drawing.PointF]::new(68,74),[System.Drawing.PointF]::new(91,74),[System.Drawing.PointF]::new(91,54),[System.Drawing.PointF]::new(68,54))) }
Draw-Symbol "settings_gear" { param($g) Ellipse $g 27 27 74 74 "#C7D7E3" "#142D47" 7; Ellipse $g 49 49 30 30 "#42586A" "#142D47" 5; for($i=0;$i-lt 8;$i++){ $a=$i*45*[Math]::PI/180; $x=58+[Math]::Cos($a)*45; $y=58+[Math]::Sin($a)*45; Rect $g $x $y 13 13 "#C7D7E3" "#142D47" 3 } }
Draw-Symbol "exit_door" { param($g) Fill-Round $g 24 19 58 90 5 "#B8783F" "#73401E" "#382313" 5; Rect $g 35 29 30 69 "#A66532" "#5B341E" 2; Ellipse $g 57 61 7 7 "#FFD95A" "#633B14" 2; Poly $g "#F6B529" "#703D08" 4 ([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(75,47),[System.Drawing.PointF]::new(102,47),[System.Drawing.PointF]::new(102,35),[System.Drawing.PointF]::new(119,55),[System.Drawing.PointF]::new(102,76),[System.Drawing.PointF]::new(102,64),[System.Drawing.PointF]::new(75,64))) }
Draw-Symbol "music" { param($g) $pn=New-Object System.Drawing.Pen (Color "#38236B"),10; $pn.StartCap='Round'; $pn.EndCap='Round'; $g.DrawLine($pn,55,35,55,91); $g.DrawLine($pn,55,36,98,27); $g.DrawLine($pn,98,27,98,77); $pn.Dispose(); Ellipse $g 27 78 32 23 "#825CF2" "#38236B" 3; Ellipse $g 72 67 31 23 "#825CF2" "#38236B" 3 }
Draw-Symbol "sound" { param($g) Poly $g "#3CA8FF" "#124982" 5 ([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(18,51),[System.Drawing.PointF]::new(43,51),[System.Drawing.PointF]::new(68,30),[System.Drawing.PointF]::new(68,98),[System.Drawing.PointF]::new(43,77),[System.Drawing.PointF]::new(18,77))); $pn=New-Object System.Drawing.Pen (Color "#124982"),6; $g.DrawArc($pn,65,42,36,44,-55,110); $g.DrawArc($pn,70,27,47,73,-55,110); $pn.Dispose() }
Draw-Symbol "vibration" { param($g) Fill-Round $g 39 21 50 86 8 "#7FD72D" "#45A410" "#24570E" 4; Rect $g 48 31 32 65 "#AEE86B" "#24570E" 2; $pn=New-Object System.Drawing.Pen (Color "#4FAE19"),5; $g.DrawArc($pn,17,36,24,56,110,140);$g.DrawArc($pn,87,36,24,56,-70,140);$pn.Dispose() }
Draw-Symbol "help" { param($g) Ellipse $g 19 19 90 90 "#42A5F5" "#194D82" 5; $font=[System.Drawing.Font]::new("Arial",62,[System.Drawing.FontStyle]::Bold); $br=New-Object System.Drawing.SolidBrush (Color "#FFFFFF"); $sf=New-Object System.Drawing.StringFormat; $sf.Alignment='Center';$sf.LineAlignment='Center';$g.DrawString("?",$font,$br,[System.Drawing.RectangleF]::new(19,14,90,90),$sf);$font.Dispose();$br.Dispose();$sf.Dispose() }
Draw-Symbol "privacy_shield" { param($g) Poly $g "#398FE7" "#174C83" 5 ([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(64,14),[System.Drawing.PointF]::new(104,31),[System.Drawing.PointF]::new(98,77),[System.Drawing.PointF]::new(64,111),[System.Drawing.PointF]::new(30,77),[System.Drawing.PointF]::new(24,31))); Poly $g "#BFE1FF" "#FFFFFF" 2 ([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(64,30),[System.Drawing.PointF]::new(88,40),[System.Drawing.PointF]::new(84,69),[System.Drawing.PointF]::new(64,91),[System.Drawing.PointF]::new(44,69),[System.Drawing.PointF]::new(40,40))) }
Draw-Symbol "arrow_right" { param($g) $pn=New-Object System.Drawing.Pen (Color "#52677C"),10; $pn.StartCap='Round';$pn.EndCap='Round';$g.DrawLine($pn,42,28,80,64);$g.DrawLine($pn,80,64,42,100);$pn.Dispose() }

foreach($settingsIcon in @("back","settings_gear","exit_door","music","sound","vibration","help","privacy_shield","arrow_right")) {
    Copy-Item -Force (Join-Path $root "icons/$settingsIcon.png") (Join-Path $root "icons/settings/$settingsIcon.png")
}

$c=New-Canvas 420 28; $b=$c[0]; $g=$c[1]
$pn=New-Object System.Drawing.Pen (Color "#9AB9D7"),2; $g.DrawLine($pn,8,14,190,14); $g.DrawLine($pn,230,14,412,14); $pn.Dispose()
Poly $g "#D7E9F9" "#89A9CC" 2 ([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(210,4),[System.Drawing.PointF]::new(220,14),[System.Drawing.PointF]::new(210,24),[System.Drawing.PointF]::new(200,14)))
Save-Canvas $b $g "common/divider_diamond.png"

Draw-Symbol "coin" { param($g) Ellipse $g 18 20 92 84 "#FFC928" "#8A4A08" 6; Ellipse $g 29 31 70 62 "#FFE267" "#D48A0B" 4; Poly $g "#F0A90D" "#B86C05" 2 ([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(64,38),[System.Drawing.PointF]::new(72,55),[System.Drawing.PointF]::new(91,57),[System.Drawing.PointF]::new(77,69),[System.Drawing.PointF]::new(81,87),[System.Drawing.PointF]::new(64,78),[System.Drawing.PointF]::new(47,87),[System.Drawing.PointF]::new(51,69),[System.Drawing.PointF]::new(37,57),[System.Drawing.PointF]::new(56,55))) }
Draw-Symbol "crystal" { param($g) Poly $g "#60EBFF" "#2864B1" 5 ([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(64,10),[System.Drawing.PointF]::new(100,50),[System.Drawing.PointF]::new(82,112),[System.Drawing.PointF]::new(43,112),[System.Drawing.PointF]::new(27,50))); Poly $g "#D8FCFF" "#FFFFFF" 2 ([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(64,18),[System.Drawing.PointF]::new(64,99),[System.Drawing.PointF]::new(37,51))) }
Draw-Symbol "chest" { param($g) Fill-Round $g 17 45 94 61 12 "#2E83F2" "#154AA7" "#102D65" 5; $p=Path-RoundRect 23 25 82 48 15; $br=New-Object System.Drawing.SolidBrush (Color "#F0AE1A");$g.FillPath($br,$p);$pn=New-Object System.Drawing.Pen (Color "#754408"),5;$g.DrawPath($pn,$p);$br.Dispose();$pn.Dispose();$p.Dispose(); Rect $g 58 48 15 42 "#F9C334" "#774405" 3; Poly $g "#FFE865" "#AE6303" 3 ([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(65,62),[System.Drawing.PointF]::new(75,71),[System.Drawing.PointF]::new(65,81),[System.Drawing.PointF]::new(55,71))) }
Draw-Symbol "gift" { param($g) Fill-Round $g 20 44 88 68 8 "#F14B64" "#B51F3B" "#68142A" 5; Rect $g 57 41 15 71 "#FFD345" "#A85A06" 3; Rect $g 16 34 96 25 "#F96075" "#68142A" 4; Ellipse $g 30 10 35 34 "#FFCA3D" "#A85A06" 4; Ellipse $g 63 10 35 34 "#FFCA3D" "#A85A06" 4 }
Draw-Symbol "ad_removed" { param($g) Ellipse $g 15 15 98 98 "#F1514B" "#76211E" 6; $font=[System.Drawing.Font]::new("Arial",38,[System.Drawing.FontStyle]::Bold); $br=New-Object System.Drawing.SolidBrush (Color "#20262C");$sf=New-Object System.Drawing.StringFormat;$sf.Alignment='Center';$sf.LineAlignment='Center';$g.DrawString("AD",$font,$br,[System.Drawing.RectangleF]::new(15,15,98,98),$sf);$pn=New-Object System.Drawing.Pen (Color "#FFFFFF"),9;$g.DrawLine($pn,31,31,97,97);$font.Dispose();$br.Dispose();$sf.Dispose();$pn.Dispose() }
Draw-Symbol "double_coin" { param($g) Ellipse $g 16 37 58 58 "#FFC928" "#8A4A08" 5; Ellipse $g 49 22 58 58 "#FFD94A" "#8A4A08" 5; $font=[System.Drawing.Font]::new("Arial",37,[System.Drawing.FontStyle]::Bold); $br=New-Object System.Drawing.SolidBrush (Color "#2D8C22");$g.DrawString("x2",$font,$br,42,76);$font.Dispose();$br.Dispose() }
Draw-Symbol "task_star" { param($g) Fill-Round $g 15 15 98 98 21 "#4BA4F5" "#1C66B9" "#174275" 4; Poly $g "#FFD943" "#A26606" 4 ([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(64,28),[System.Drawing.PointF]::new(73,51),[System.Drawing.PointF]::new(98,52),[System.Drawing.PointF]::new(78,67),[System.Drawing.PointF]::new(84,92),[System.Drawing.PointF]::new(64,78),[System.Drawing.PointF]::new(43,92),[System.Drawing.PointF]::new(50,67),[System.Drawing.PointF]::new(29,52),[System.Drawing.PointF]::new(55,51))) }
Draw-Symbol "task_swords" { param($g) $pn=New-Object System.Drawing.Pen (Color "#EEF6FF"),13;$pn.StartCap='Round';$g.DrawLine($pn,34,24,94,100);$g.DrawLine($pn,94,24,34,100);$pn.Dispose(); Rect $g 21 78 35 13 "#F5B526" "#623A0B" 3; Rect $g 72 78 35 13 "#F5B526" "#623A0B" 3 }
Draw-Symbol "task_merge" { param($g) Rect $g 18 49 46 46 "#A52DE3" "#552074" 4; Rect $g 64 29 46 46 "#4DA5FF" "#234D88" 4; Poly $g "#FFFFFF" "#234D88" 3 ([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(52,36),[System.Drawing.PointF]::new(78,36),[System.Drawing.PointF]::new(78,22),[System.Drawing.PointF]::new(105,46),[System.Drawing.PointF]::new(78,70),[System.Drawing.PointF]::new(78,56),[System.Drawing.PointF]::new(52,56))) }
Draw-Symbol "task_kill" { param($g) Ellipse $g 26 35 76 64 "#75B644" "#335E25" 5; Ellipse $g 43 55 12 14 "#16231B" "#16231B" 0;Ellipse $g 76 55 12 14 "#16231B" "#16231B" 0; Rect $g 46 88 9 20 "#69A13C" "#335E25" 2;Rect $g 76 88 9 20 "#69A13C" "#335E25" 2 }
Draw-Symbol "task_login" { param($g) Fill-Round $g 23 20 82 92 10 "#F0F4F7" "#CBD6DE" "#546778" 4; Rect $g 35 13 58 20 "#E6554E" "#7E2421" 3; $pn=New-Object System.Drawing.Pen (Color "#47A62C"),10;$pn.StartCap='Round';$pn.EndCap='Round';$g.DrawLine($pn,42,70,57,86);$g.DrawLine($pn,57,86,90,50);$pn.Dispose() }
Draw-Symbol "check" { param($g) Ellipse $g 17 17 94 94 "#66C338" "#2D711A" 5; $pn=New-Object System.Drawing.Pen (Color "#FFFFFF"),11;$pn.StartCap='Round';$pn.EndCap='Round';$g.DrawLine($pn,37,63,55,82);$g.DrawLine($pn,55,82,93,43);$pn.Dispose() }
Draw-Symbol "lock" { param($g) Fill-Round $g 25 53 78 62 10 "#8F9BA8" "#5F6A75" "#34404B" 4; $pn=New-Object System.Drawing.Pen (Color "#DDE5EC"),10;$g.DrawArc($pn,40,17,48,67,190,160);$pn.Dispose(); Ellipse $g 57 72 14 19 "#2F3942" "#2F3942" 0 }
Draw-Symbol "sold_out" { param($g) Ellipse $g 16 16 96 96 "#E95A54" "#7D2421" 5; $pn=New-Object System.Drawing.Pen (Color "#FFFFFF"),12;$g.DrawLine($pn,34,34,94,94);$g.DrawLine($pn,94,34,34,94);$pn.Dispose() }
Draw-Symbol "shop" { param($g) Fill-Round $g 20 48 88 63 9 "#3D8EE9" "#1955A8" "#153B72" 4; Poly $g "#FF6658" "#8E2720" 4 ([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(15,24),[System.Drawing.PointF]::new(113,24),[System.Drawing.PointF]::new(103,57),[System.Drawing.PointF]::new(25,57))); Rect $g 35 66 25 45 "#BEE0FA" "#1C4D80" 3; Rect $g 72 67 22 20 "#BEE0FA" "#1C4D80" 3 }

# Daily page states and reward artwork.
Draw-PageSymbol "pages/daily/activity_chest_locked.png" 150 128 { param($g) Fill-Round $g 21 48 108 65 12 "#73889D" "#435466" "#273544" 5; $pn=New-Object System.Drawing.Pen (Color "#BAC6D0"),8;$g.DrawArc($pn,44,20,62,62,190,160);$pn.Dispose(); Rect $g 66 68 18 25 "#273544" "#1B2732" 2 }
Draw-PageSymbol "pages/daily/activity_chest_ready.png" 150 128 { param($g) Fill-Round $g 18 48 114 66 12 "#318AF0" "#174CA2" "#102D64" 5; $p=Path-RoundRect 25 22 100 54 16;$br=New-Object System.Drawing.SolidBrush (Color "#F5B51E");$g.FillPath($br,$p);$pn=New-Object System.Drawing.Pen (Color "#744405"),5;$g.DrawPath($pn,$p);$br.Dispose();$pn.Dispose();$p.Dispose();Rect $g 67 49 18 45 "#FFD43B" "#794305" 3 }
Draw-PageSymbol "pages/daily/activity_chest_claimed.png" 150 128 { param($g) Fill-Round $g 18 48 114 66 12 "#8190A0" "#596674" "#34414F" 5; Ellipse $g 48 26 55 55 "#67C53B" "#2D6E19" 4; $pn=New-Object System.Drawing.Pen (Color "#FFFFFF"),8;$pn.StartCap='Round';$pn.EndCap='Round';$g.DrawLine($pn,61,53,72,65);$g.DrawLine($pn,72,65,91,43);$pn.Dispose() }
Draw-PageSymbol "pages/daily/status_claimable.png" 72 72 { param($g) Ellipse $g 4 4 64 64 "#FFD54E" "#A25D05" 4; Poly $g "#FFFFFF" "#D58705" 2 ([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(36,14),[System.Drawing.PointF]::new(42,29),[System.Drawing.PointF]::new(58,30),[System.Drawing.PointF]::new(46,40),[System.Drawing.PointF]::new(50,56),[System.Drawing.PointF]::new(36,47),[System.Drawing.PointF]::new(22,56),[System.Drawing.PointF]::new(26,40),[System.Drawing.PointF]::new(14,30),[System.Drawing.PointF]::new(30,29))) }
Draw-PageSymbol "pages/daily/status_claimed.png" 72 72 { param($g) Ellipse $g 4 4 64 64 "#65BF38" "#2B6B19" 4; $pn=New-Object System.Drawing.Pen (Color "#FFFFFF"),8;$pn.StartCap='Round';$pn.EndCap='Round';$g.DrawLine($pn,18,37,31,50);$g.DrawLine($pn,31,50,55,24);$pn.Dispose() }
Draw-PageSymbol "pages/daily/status_incomplete.png" 72 72 { param($g) Ellipse $g 4 4 64 64 "#AEBAC7" "#5E7184" 4; $pn=New-Object System.Drawing.Pen (Color "#F2F5F7"),7;$pn.StartCap='Round';$g.DrawLine($pn,20,36,52,36);$pn.Dispose() }

# Commerce status corners and first-purchase sequence.
Draw-PageSymbol "pages/commerce/badge_new_blank.png" 72 72 { param($g) Fill-Round $g 3 3 66 66 14 "#FFB52B" "#F0780C" "#9C3C04" 4; Poly $g "#FFF3A3" "#FFF3A3" 0 ([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(36,14),[System.Drawing.PointF]::new(42,29),[System.Drawing.PointF]::new(58,30),[System.Drawing.PointF]::new(46,40),[System.Drawing.PointF]::new(50,56),[System.Drawing.PointF]::new(36,47),[System.Drawing.PointF]::new(22,56),[System.Drawing.PointF]::new(26,40),[System.Drawing.PointF]::new(14,30),[System.Drawing.PointF]::new(30,29))) }
Draw-PageSymbol "pages/commerce/badge_owned.png" 72 72 { param($g) Fill-Round $g 3 3 66 66 14 "#83C957" "#3C8C28" "#24591A" 4; $pn=New-Object System.Drawing.Pen (Color "#FFFFFF"),8;$pn.StartCap='Round';$pn.EndCap='Round';$g.DrawLine($pn,17,37,30,50);$g.DrawLine($pn,30,50,55,23);$pn.Dispose() }
Draw-PageSymbol "pages/commerce/first_chest_closed.png" 220 180 { param($g) Fill-Round $g 28 76 164 82 14 "#2E79D8" "#163F8B" "#0C285A" 6;$p=Path-RoundRect 36 38 148 72 19;$br=New-Object System.Drawing.SolidBrush (Color "#F4B624");$g.FillPath($br,$p);$pn=New-Object System.Drawing.Pen (Color "#784505"),6;$g.DrawPath($pn,$p);$br.Dispose();$pn.Dispose();$p.Dispose();Rect $g 99 69 24 63 "#FFD84E" "#7B4605" 4 }
Draw-PageSymbol "pages/commerce/first_chest_open.png" 220 180 { param($g) Fill-Round $g 28 91 164 70 14 "#2E79D8" "#163F8B" "#0C285A" 6; Poly $g "#F4B624" "#784505" 6 ([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(37,67),[System.Drawing.PointF]::new(57,22),[System.Drawing.PointF]::new(182,22),[System.Drawing.PointF]::new(190,68))); for($i=0;$i-lt 6;$i++){ $a=(-70+$i*28)*[Math]::PI/180;$x=110+[Math]::Cos($a)*58;$y=81+[Math]::Sin($a)*58;Ellipse $g $x $y 18 18 "#FFE45E" "#A16005" 2 } }
Draw-PageSymbol "pages/commerce/first_reward_altar.png" 220 180 { param($g) Ellipse $g 28 119 164 42 "#3A77C5" "#123D77" 5;Ellipse $g 48 105 124 39 "#78BDFC" "#2A67A7" 4; Poly $g "#8B5CFF" "#3B2B86" 5 ([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(110,18),[System.Drawing.PointF]::new(151,78),[System.Drawing.PointF]::new(127,125),[System.Drawing.PointF]::new(90,125),[System.Drawing.PointF]::new(68,78)));Poly $g "#E2F8FF" "#FFFFFF" 2 ([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(110,27),[System.Drawing.PointF]::new(110,113),[System.Drawing.PointF]::new(79,78))) }

# Shop price/status components and product icon family.
Draw-PageSymbol "pages/shop/price_strip_crystal.png" 188 52 { param($g) Fill-Round $g 2 2 184 48 10 "#5DB8FF" "#2482D8" "#16538E" 3; Poly $g "#D3FAFF" "#2865B0" 2 ([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(25,7),[System.Drawing.PointF]::new(40,25),[System.Drawing.PointF]::new(25,44),[System.Drawing.PointF]::new(10,25))) }
Draw-PageSymbol "pages/shop/price_strip_money.png" 188 52 { param($g) Fill-Round $g 2 2 184 48 10 "#FFD55C" "#F1A31D" "#9A5B08" 3; Ellipse $g 10 8 34 34 "#FFE972" "#A46606" 2 }
Draw-PageSymbol "pages/shop/status_daily_limit.png" 64 64 { param($g) Fill-Round $g 2 2 60 60 13 "#7895B1" "#49667F" "#2E4559" 3; $pn=New-Object System.Drawing.Pen (Color "#FFFFFF"),5;$g.DrawEllipse($pn,15,13,34,34);$g.DrawLine($pn,32,30,32,18);$g.DrawLine($pn,32,30,42,36);$pn.Dispose() }
Draw-PageSymbol "pages/shop/status_sold_out.png" 64 64 { param($g) Fill-Round $g 2 2 60 60 13 "#E95B55" "#B52C2D" "#711A1C" 3;$pn=New-Object System.Drawing.Pen (Color "#FFFFFF"),7;$g.DrawLine($pn,16,16,48,48);$g.DrawLine($pn,48,16,16,48);$pn.Dispose() }
Draw-PageSymbol "pages/shop/status_owned.png" 64 64 { param($g) Fill-Round $g 2 2 60 60 13 "#72C64A" "#3C912B" "#235B1B" 3;$pn=New-Object System.Drawing.Pen (Color "#FFFFFF"),7;$pn.StartCap='Round';$pn.EndCap='Round';$g.DrawLine($pn,14,33,27,46);$g.DrawLine($pn,27,46,51,20);$pn.Dispose() }
Draw-PageSymbol "pages/shop/status_insufficient.png" 64 64 { param($g) Fill-Round $g 2 2 60 60 13 "#F2776E" "#C93F3D" "#7B2424" 3; $pn=New-Object System.Drawing.Pen (Color "#FFFFFF"),7;$pn.StartCap='Round';$g.DrawLine($pn,32,14,32,38);$g.DrawLine($pn,32,48,32,50);$pn.Dispose() }
Draw-PageSymbol "pages/shop/icon_coin_bundle.png" 128 128 { param($g) Ellipse $g 15 51 68 60 "#FFC928" "#8A4A08" 5;Ellipse $g 45 31 68 60 "#FFD94A" "#8A4A08" 5;Ellipse $g 35 12 68 60 "#FFE069" "#A26006" 5 }
Draw-PageSymbol "pages/shop/icon_crystal_bundle.png" 128 128 { param($g) foreach($o in @(@(18,44,"#4BE6FF"),@(50,15,"#B35BFF"),@(78,48,"#FF6A86"))){Poly $g $o[2] "#294C93" 4 ([System.Drawing.PointF[]]@([System.Drawing.PointF]::new($o[0]+16,$o[1]),[System.Drawing.PointF]::new($o[0]+32,$o[1]+29),[System.Drawing.PointF]::new($o[0]+17,$o[1]+58),[System.Drawing.PointF]::new($o[0],$o[1]+29)))} }
Draw-PageSymbol "pages/shop/icon_star_hammer.png" 128 128 { param($g) Fill-Round $g 17 24 72 45 8 "#FFD351" "#E99A16" "#814909" 4;Rect $g 72 60 17 57 "#B97836" "#52301B" 4;Poly $g "#64AFFF" "#214F99" 2 ([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(53,31),[System.Drawing.PointF]::new(59,44),[System.Drawing.PointF]::new(74,45),[System.Drawing.PointF]::new(63,55),[System.Drawing.PointF]::new(66,68),[System.Drawing.PointF]::new(53,61),[System.Drawing.PointF]::new(40,68),[System.Drawing.PointF]::new(43,55),[System.Drawing.PointF]::new(32,45),[System.Drawing.PointF]::new(47,44))) }
Draw-PageSymbol "pages/shop/icon_fire_conduit.png" 128 128 { param($g) Fill-Round $g 18 44 92 48 21 "#4B5BC8" "#28317E" "#171C53" 5;Rect $g 75 51 34 34 "#F1B32B" "#6D430B" 4;Poly $g "#FF6B3C" "#8A250F" 3 ([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(31,96),[System.Drawing.PointF]::new(22,74),[System.Drawing.PointF]::new(37,59),[System.Drawing.PointF]::new(41,38),[System.Drawing.PointF]::new(56,60),[System.Drawing.PointF]::new(52,81))) }
Draw-PageSymbol "pages/shop/icon_steam_furnace.png" 128 128 { param($g) Fill-Round $g 26 48 77 64 12 "#D8862C" "#8A431D" "#4C2817" 5;Ellipse $g 45 65 38 38 "#38A9E8" "#194E77" 4;for($i=0;$i-lt 3;$i++){Ellipse $g (34+$i*25) (18-$i%2*7) 18 18 "#E8F2F7" "#778995" 2} }
Draw-PageSymbol "pages/shop/icon_clockwork.png" 128 128 { param($g) Ellipse $g 22 23 84 84 "#F2B52E" "#754508" 6;Ellipse $g 43 44 42 42 "#42A8E9" "#174E79" 4;for($i=0;$i-lt 8;$i++){$a=$i*45*[Math]::PI/180;$x=58+[Math]::Cos($a)*46;$y=58+[Math]::Sin($a)*46;Rect $g $x $y 12 12 "#DD8D20" "#754508" 2} }
Draw-PageSymbol "pages/shop/icon_prism.png" 128 128 { param($g) Rect $g 22 67 84 38 "#E1A827" "#6D450B" 5;Poly $g "#5AE8FF" "#2659A2" 4 ([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(39,30),[System.Drawing.PointF]::new(64,61),[System.Drawing.PointF]::new(39,91),[System.Drawing.PointF]::new(14,61)));Poly $g "#8BD8FF" "#2659A2" 4 ([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(89,30),[System.Drawing.PointF]::new(114,61),[System.Drawing.PointF]::new(89,91),[System.Drawing.PointF]::new(64,61))) }
Draw-PageSymbol "pages/shop/icon_cannon.png" 128 128 { param($g) Ellipse $g 21 76 88 35 "#465782" "#202A48" 5;Poly $g "#F4BA28" "#6D4107" 5 ([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(35,49),[System.Drawing.PointF]::new(92,24),[System.Drawing.PointF]::new(108,53),[System.Drawing.PointF]::new(50,77)));Ellipse $g 85 24 28 31 "#5DD8FF" "#285791" 4 }
Draw-PageSymbol "pages/shop/icon_imprint_chest.png" 128 128 { param($g) Fill-Round $g 17 44 94 64 13 "#2E83F2" "#154AA7" "#102D65" 5;$p=Path-RoundRect 23 22 82 53 16;$br=New-Object System.Drawing.SolidBrush (Color "#F0AE1A");$g.FillPath($br,$p);$pn=New-Object System.Drawing.Pen (Color "#754408"),5;$g.DrawPath($pn,$p);$br.Dispose();$pn.Dispose();$p.Dispose() }

# Piggy bank four visual states.
foreach($state in @("empty","filling","full","owned")){
    $c=New-Canvas 160 160;$b=$c[0];$g=$c[1]
    $fill = if($state -eq "empty"){"#D9A5B0"}elseif($state -eq "filling"){"#F4A6B6"}else{"#F27C96"}
    Ellipse $g 21 44 112 76 $fill "#88394F" 5; Ellipse $g 104 62 35 28 $fill "#88394F" 4; Ellipse $g 39 27 25 30 $fill "#88394F" 4
    Rect $g 44 111 16 23 $fill "#88394F" 3;Rect $g 97 108 16 26 $fill "#88394F" 3; Ellipse $g 101 58 6 6 "#222B35" "#222B35" 0
    if($state -eq "filling"){ Ellipse $g 55 50 50 50 "#F7B32B" "#945407" 3 }
    if($state -eq "full"){ $pn=New-Object System.Drawing.Pen (Color "#FFD75A"),7;$g.DrawArc($pn,25,28,112,115,180,180);$pn.Dispose() }
    if($state -eq "owned"){ $br=New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(175,65,72,86));$g.FillEllipse($br,21,44,112,76);$br.Dispose();$pn=New-Object System.Drawing.Pen (Color "#FFFFFF"),10;$pn.StartCap='Round';$pn.EndCap='Round';$g.DrawLine($pn,54,81,72,99);$g.DrawLine($pn,72,99,111,58);$pn.Dispose() }
    Save-Canvas $b $g "pages/commerce/piggy_$state.png"
}

# Page-specific structural components, all without dynamic copy.
$c=New-Canvas 152 126;$b=$c[0];$g=$c[1];Fill-Round $g 3 3 146 120 16 "#328FF1" "#185AB6" "#092C59" 5;Draw-Highlight $g 11 10 130 91 11;Save-Canvas $b $g "pages/pause/action_tile_blue.png"
$c=New-Canvas 152 126;$b=$c[0];$g=$c[1];Fill-Round $g 3 3 146 120 16 "#EE625E" "#C42D34" "#681820" 5;Draw-Highlight $g 11 10 130 91 11;Save-Canvas $b $g "pages/pause/action_tile_red.png"
$c=New-Canvas 780 126;$b=$c[0];$g=$c[1];Fill-Round $g 2 2 776 122 17 "#F7FCFF" "#D5E9F8" "#5F91C4" 4;Draw-Highlight $g 10 9 760 96 12;Save-Canvas $b $g "pages/daily/task_row.png"
$c=New-Canvas 110 206;$b=$c[0];$g=$c[1];Fill-Round $g 2 2 106 202 14 "#4E9BF1" "#2270C8" "#16497E" 4;Draw-Highlight $g 9 9 92 172 10;Save-Canvas $b $g "pages/daily/signin_day_default.png"
$c=New-Canvas 110 206;$b=$c[0];$g=$c[1];Fill-Round $g 2 2 106 202 14 "#FFD75C" "#F3A21A" "#A26008" 5;Draw-Highlight $g 9 9 92 172 10;Save-Canvas $b $g "pages/daily/signin_day_today.png"
$c=New-Canvas 180 230;$b=$c[0];$g=$c[1];Fill-Round $g 3 3 174 224 17 "#FFFFFF" "#E7E7E2" "#A7A7A0" 4;Draw-Highlight $g 11 10 158 190 12;Save-Canvas $b $g "pages/commerce/benefit_card.png"
$c=New-Canvas 96 112;$b=$c[0];$g=$c[1];Fill-Round $g 2 2 92 108 13 "#4FA5F0" "#1B63B8" "#103D73" 4;Draw-Highlight $g 8 8 80 82 9;Save-Canvas $b $g "pages/commerce/reward_slot_blue.png"
$c=New-Canvas 96 112;$b=$c[0];$g=$c[1];Fill-Round $g 2 2 92 108 13 "#A657DA" "#6C2AA2" "#431764" 4;Draw-Highlight $g 8 8 80 82 9;Save-Canvas $b $g "pages/commerce/reward_slot_purple.png"
$c=New-Canvas 190 250;$b=$c[0];$g=$c[1];Fill-Round $g 2 2 186 246 15 "#F9FCFF" "#DCEBFA" "#7999BC" 4;Draw-Highlight $g 9 9 172 214 11;Save-Canvas $b $g "pages/shop/product_slot_default.png"
$c=New-Canvas 190 250;$b=$c[0];$g=$c[1];Fill-Round $g 2 2 186 246 15 "#FFF5F4" "#F4D4D1" "#C85852" 4;Draw-Highlight $g 9 9 172 214 11;Save-Canvas $b $g "pages/shop/product_slot_unavailable.png"
$c=New-Canvas 400 76;$b=$c[0];$g=$c[1];Fill-Round $g 2 2 396 72 13 "#F8FCFF" "#DCEAF5" "#7D9BB8" 3;Save-Canvas $b $g "pages/shop/purchase_quantity_row.png"

# Red dot is dynamic-positioned but the artwork itself has no count baked in.
$c=New-Canvas 48 48;$b=$c[0];$g=$c[1];Ellipse $g 3 3 42 42 "#F0443B" "#8E1714" 4;Draw-Highlight $g 12 8 23 12 7;Save-Canvas $b $g "common/badge_red_dot.png"

Write-Output "Generated secondary_v2 runtime art at $root"
