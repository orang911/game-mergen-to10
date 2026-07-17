# Post-export HTML patch: apply fixed 941x1672 canvas scaling + black letterbox.
# Run after each Godot Web export.

param([string]$HtmlPath = "index.html")

$html = Get-Content $HtmlPath -Raw

# 1. Add width/height attributes to canvas tag
$html = $html -replace '(<canvas id="canvas")', '$1 width="941" height="1672"'

# 2. Replace CSS block: add html/body full-size + grid centering
$oldCss = @'
html, body, #canvas {
	margin: 0;
	padding: 0;
	border: 0;
}

body {
	color: white;
	background-color: black;
	overflow: hidden;
	touch-action: none;
}
'@
$newCss = @'
html, body, #canvas {
	margin: 0;
	padding: 0;
	border: 0;
}

html, body {
	width: 100%;
	height: 100%;
}

body {
	color: white;
	background-color: black;
	overflow: hidden;
	touch-action: none;
	display: grid;
	place-items: center;
}
'@
$html = $html -replace ([regex]::Escape($oldCss)), $newCss

# 3. Insert fitCanvas JS block before GODOT_CONFIG
$fitJs = @'
const DESIGN_W = 941;
const DESIGN_H = 1672;

function fitCanvas() {
	const canvas = document.getElementById("canvas");
	const scale = Math.min(1, window.innerWidth / DESIGN_W, window.innerHeight / DESIGN_H);
	const w = Math.floor(DESIGN_W * scale);
	const h = Math.floor(DESIGN_H * scale);
	canvas.style.width = w + "px";
	canvas.style.height = h + "px";
}

window.addEventListener("resize", fitCanvas);

'@
$html = $html -replace 'const GODOT_CONFIG =', ($fitJs + "const GODOT_CONFIG =")

# 4. ensureCrossOriginIsolationHeaders -> false
$html = $html -replace '"ensureCrossOriginIsolationHeaders":true', '"ensureCrossOriginIsolationHeaders":false'

# 5. Call fitCanvas() on game start
$oldHidden = "`t`t`t`tinitializing = false;`r`n`t`t`t`treturn;"
$newHidden = "`t`t`t`tinitializing = false;`r`n`t`t`t`tfitCanvas();`r`n`t`t`t`treturn;"
$html = $html -replace ([regex]::Escape($oldHidden)), $newHidden

Set-Content $HtmlPath -Value $html -NoNewline
Write-Host "Patched: $HtmlPath (fixed canvas, fitCanvas, letterbox, crossOrigin=false)"
