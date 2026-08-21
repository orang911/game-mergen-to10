from pathlib import Path
from PIL import Image

p = Path(r"F:\卖肉\godotT10\game_mergenTo10_published\assets\runtime\ui\secondary_v2")
for f in sorted(p.rglob("*.png")):
    if "contact_sheet" in f.name:
        continue
    im = Image.open(f)
    print(f.relative_to(p).as_posix(), im.size, im.mode)
