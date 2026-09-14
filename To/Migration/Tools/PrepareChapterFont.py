from pathlib import Path
import sys
root = Path(__file__).resolve().parent
sys.path.insert(0, str(root / "PythonDeps"))
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
from fontTools import subset
out = root.parent.parent / "Assets/MergeTo10/Resources/Campaign"
text = "0123456789- /第一章完成水晶、棋盘与能量状态将带入下一关。继续前进挑战仍将继续。下一站：续战返回大厅"
source = root.parent / "Baselines/godot_2026-09-11_v01/Source/scripts"
for script in source.glob("*.gd"):
    text += script.read_text(encoding="utf-8")
for weight in (700, 900):
    font = TTFont("C:/Windows/Fonts/NotoSansSC-VF.ttf")
    license_text = "\n".join(str(font["name"].getDebugName(i) or "") for i in (0,7,8,9,13,14))
    assert "Open Font License" in license_text
    font = instantiateVariableFont(font, {"wght": weight}, inplace=True)
    options = subset.Options()
    options.name_IDs = ["*"]
    worker = subset.Subsetter(options=options)
    worker.populate(text=text)
    worker.subset(font)
    font.save(out / f"chapter_{weight}.ttf")
(out / "chapter_font_license.txt").write_text(license_text, encoding="utf-8")
