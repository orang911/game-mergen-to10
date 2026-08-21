$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
$project = (Resolve-Path ".").Path
$root = Join-Path $project "assets/runtime/ui/secondary_v2"
$out = Join-Path $root "contact_sheet_batch1.png"
$items = @(
    @("Pause panel","common/panel_dark.png"), @("Settings panel","common/panel_light.png"),
    @("Blue button","common/button_blue_default.png"), @("Red button","common/button_red_default.png"),
    @("Switch on","common/switch_on.png"), @("Switch off","common/switch_off.png"),
    @("Divider","common/divider_diamond.png"), @("Back","icons/settings/back.png"),
    @("Gear","icons/settings/settings_gear.png"), @("Exit","icons/settings/exit_door.png"),
    @("Music","icons/settings/music.png"), @("Sound","icons/settings/sound.png"),
    @("Vibration","icons/settings/vibration.png"), @("Help","icons/settings/help.png"),
    @("Privacy","icons/settings/privacy_shield.png"), @("Arrow","icons/settings/arrow_right.png"),
    @("Pause blue tile","pages/pause/action_tile_blue.png"), @("Pause red tile","pages/pause/action_tile_red.png")
)
$bmp=[System.Drawing.Bitmap]::new(1200,850,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$bmp.SetResolution(96,96)
$g=[System.Drawing.Graphics]::FromImage($bmp);$g.SmoothingMode='AntiAlias';$g.Clear([System.Drawing.ColorTranslator]::FromHtml("#E7EDF5"))
$title=[System.Drawing.Font]::new("Arial",28,[System.Drawing.FontStyle]::Bold);$label=[System.Drawing.Font]::new("Arial",15,[System.Drawing.FontStyle]::Regular);$dark=New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml("#19334F"))
$g.DrawString("Secondary UI V2 - Batch 1 runtime assets",$title,$dark,34,22)
for($i=0;$i-lt $items.Count;$i++){
    $col=$i%6;$row=[Math]::Floor($i/6);$x=30+$col*195;$y=90+$row*245
    $panel=New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White);$g.FillRectangle($panel,$x,$y,175,218);$panel.Dispose()
    $pen=New-Object System.Drawing.Pen ([System.Drawing.ColorTranslator]::FromHtml("#B7C6D8"),2);$g.DrawRectangle($pen,$x,$y,175,218);$pen.Dispose()
    $path=Join-Path $root $items[$i][1];$img=[System.Drawing.Image]::FromFile($path)
    $maxW=145.0;$maxH=155.0;$scale=[Math]::Min($maxW/$img.Width,$maxH/$img.Height);$dw=[int]($img.Width*$scale);$dh=[int]($img.Height*$scale)
    $g.DrawImage($img,$x+[int]((175-$dw)/2),$y+13+[int]((155-$dh)/2),$dw,$dh);$img.Dispose()
    $sf=New-Object System.Drawing.StringFormat;$sf.Alignment='Center';$sf.LineAlignment='Center';$g.DrawString($items[$i][0],$label,$dark,[System.Drawing.RectangleF]::new($x+5,$y+174,165,36),$sf);$sf.Dispose()
}
$g.Dispose();$bmp.Save($out,[System.Drawing.Imaging.ImageFormat]::Png);$bmp.Dispose();$title.Dispose();$label.Dispose();$dark.Dispose()
Write-Output $out
