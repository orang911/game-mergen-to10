from pathlib import Path
import sys
root = Path(__file__).resolve().parent
sys.path.insert(0, str(root / "PythonDeps"))
from fontTools.ttLib import TTFont
font = TTFont(root / "resonance_default.woff2")
font.flavor = None
output = root.parent.parent / "Assets/MergeTo10/Resources/M2Art/resonance_default.ttf"
font.save(output)
print(font["name"].getDebugName(1), "converted to", output)
# Preserve embedded attribution/license alongside the migrated runtime font.
license_text = "\n".join(str(font["name"].getDebugName(i) or "") for i in (0,7,8,9,13,14))
(output.parent / "resonance_default_license.txt").write_text(license_text, encoding="utf-8")
