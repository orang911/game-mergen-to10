from pathlib import Path
import sys
root = Path(__file__).resolve().parent
sys.path.insert(0, str(root / "PythonDeps"))
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
from fontTools import subset
font = TTFont("C:/Windows/Fonts/NotoSansSC-VF.ttf")
license_text = "\n".join(str(font["name"].getDebugName(i) or "") for i in (0,7,8,9,13,14))
assert "Open Font License" in license_text
font = instantiateVariableFont(font, {"wght": 400}, inplace=True)
options = subset.Options()
options.name_IDs = ["*"]
worker = subset.Subsetter(options=options)
worker.populate(text="湮灭！")
worker.subset(font)
out = root.parent.parent / "Assets/MergeTo10/Resources/M2Art"
font.save(out / "annihilation_text.ttf")
(out / "annihilation_text_license.txt").write_text(license_text, encoding="utf-8")
