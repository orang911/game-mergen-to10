from __future__ import annotations

import json
import shutil
import colorsys
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = (
    ROOT
    / "art/production/ui/daily_program_composition/2026-08-16_cutouts_v01/cutouts"
)
OUT = ROOT / "assets/runtime/ui/daily_program_composition_v01"


def copy_group(group: str) -> list[dict[str, object]]:
    source_dir = SOURCE / group
    target_dir = OUT / group
    target_dir.mkdir(parents=True, exist_ok=True)
    records: list[dict[str, object]] = []
    for source in sorted(source_dir.glob("*.png")):
        with Image.open(source) as image:
            rgba = image.convert("RGBA")
            # The production cutter deliberately kept a 12px QA gutter around
            # every backplate. Runtime layout measures the painted bounds, so
            # retain only a 2px isolation gutter here; otherwise wide
            # NinePatch rows drift 20-30 logical pixels inward after scaling.
            if group == "backplates" and rgba.width > 24 and rgba.height > 24:
                rgba = rgba.crop((10, 10, rgba.width - 10, rgba.height - 10))
            if max(rgba.size) > 2048:
                raise ValueError(f"Mobile texture exceeds 2048px: {source} {rgba.size}")
            if rgba.getchannel("A").getbbox() is None:
                raise ValueError(f"Runtime texture has no visible pixels: {source}")
            target = target_dir / source.name
            rgba.save(target, "PNG", optimize=True)
            records.append(
                {
                    "file": target.relative_to(ROOT).as_posix(),
                    "size": list(rgba.size),
                    "alpha": True,
                    "text_baked": False,
                }
            )
    return records


def recolor_slot(source: Path, target: Path, hue: float, value_scale: float = 1.0) -> dict[str, object]:
    image = Image.open(source).convert("RGBA")
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            _h, s, v = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
            if s > 0.12:
                nr, ng, nb = colorsys.hsv_to_rgb(hue, min(1.0, s * 1.05), min(1.0, v * value_scale))
                pixels[x, y] = (round(nr * 255), round(ng * 255), round(nb * 255), a)
    image.save(target, "PNG", optimize=True)
    return {
        "file": target.relative_to(ROOT).as_posix(),
        "size": list(image.size),
        "alpha": True,
        "text_baked": False,
        "derived_from": source.name,
    }


def main() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(SOURCE)
    if OUT.exists():
        shutil.rmtree(OUT)
    records = copy_group("backplates") + copy_group("icons")
    slot = OUT / "backplates/daily_icon_slot_v01.png"
    records.append(recolor_slot(slot, OUT / "backplates/daily_icon_slot_selected_v01.png", 0.105, 1.06))
    records.append(recolor_slot(slot, OUT / "backplates/daily_close_button_v01.png", 0.655, 1.02))
    manifest = {
        "purpose": "daily-program-composition-runtime",
        "version": "v01",
        "source": SOURCE.parent.relative_to(ROOT).as_posix(),
        "assets": records,
        "runtime_integrated": True,
        "approved_viewport": [941, 1672],
    }
    (OUT / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps({"assets": len(records), "output": str(OUT)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
