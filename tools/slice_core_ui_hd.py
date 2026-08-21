"""Slice the high-definition core battle UI into transparent, non-destructive PNG assets.

The script deliberately retains the original source bounds for program placement and
uses a border-connected grass mask instead of global chroma keying, so green UI
icons remain intact.
"""

from __future__ import annotations

import json
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


ROOT = Path.cwd()
SOURCE = (
    ROOT
    / "game_mergenTo10_published"
    / "art"
    / "ai_generated"
    / "imagegen"
    / "2026-07-29"
    / "core-battle-ui-hd-redraw-v01"
    / "20260729_core_battle_ui_hd_redraw_v01.png"
)
OUT = (
    ROOT
    / "game_mergenTo10_published"
    / "art"
    / "ai_generated"
    / "slices"
    / "2026-07-29"
    / "core-battle-ui-hd-v01"
)

# x, y, right, bottom in the 941 x 1672 design canvas. Bounds include a small
# amount of background so the foreground masking has clean antialiased edges.
SLICES = {
    "top/pause_button_baked": (18, 8, 113, 106),
    "top/wave_status_baked": (194, 8, 467, 101),
    "top/time_status_baked": (468, 8, 651, 101),
    "top/currency_status_baked": (658, 8, 894, 104),
    "bottom/skill_panel_baked": (23, 1448, 421, 1604),
    "bottom/item_refresh_baked": (499, 1448, 638, 1590),
    "bottom/item_wand_baked": (628, 1448, 759, 1590),
    "bottom/item_lock_baked": (750, 1448, 891, 1590),
    "core/crystal_tower_baked": (256, 492, 429, 638),
    "core/crystal_hp_bar_baked": (270, 627, 431, 667),
}


def is_grass(pixel: np.ndarray) -> bool:
    """Recognise the connected grass backdrop without keying green UI glyphs."""
    r, g, b = (int(v) for v in pixel[:3])
    # The field includes sunlit and shadowed greens.  We intentionally keep this
    # broad; connected-component masking prevents it from touching green glyphs
    # enclosed by a button or a crystal base.
    return g >= 38 and (g - max(r, b)) >= 10


def is_cream_road(pixel: np.ndarray) -> bool:
    """Recognise the pale stone path behind the crystal tower."""
    r, g, b = (int(v) for v in pixel[:3])
    return r >= 120 and g >= 112 and b >= 72 and r > b * 1.12 and g > b * 1.08


def remove_border_grass(crop: Image.Image, *, include_cream_road: bool = False) -> Image.Image:
    """Make only border-connected grass transparent, preserving enclosed UI greens."""
    rgb = np.asarray(crop.convert("RGBA"), dtype=np.uint8).copy()
    height, width = rgb.shape[:2]
    background = np.zeros((height, width), dtype=bool)
    queue: deque[tuple[int, int]] = deque()

    for x in range(width):
        queue.append((x, 0))
        queue.append((x, height - 1))
    for y in range(height):
        queue.append((0, y))
        queue.append((width - 1, y))

    while queue:
        x, y = queue.popleft()
        if x < 0 or y < 0 or x >= width or y >= height or background[y, x]:
            continue
        is_background = is_grass(rgb[y, x]) or (
            include_cream_road and is_cream_road(rgb[y, x])
        )
        if not is_background:
            continue
        background[y, x] = True
        queue.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))

    # Slightly soften pixels immediately bordering the mask for non-stair-stepped edges.
    alpha = rgb[:, :, 3]
    alpha[background] = 0
    for y in range(1, height - 1):
        for x in range(1, width - 1):
            if background[y, x]:
                continue
            neighbours = background[y - 1 : y + 2, x - 1 : x + 2]
            count = int(neighbours.sum())
            if count:
                alpha[y, x] = min(int(alpha[y, x]), max(96, 255 - count * 28))
    rgb[:, :, 3] = alpha
    # Prevent the original grass RGB from bleeding through partially transparent
    # antialiased pixels in engines that use premultiplied-alpha sampling.
    fringe = alpha < 255
    rgb[:, :, 1][fringe] = np.minimum(
        rgb[:, :, 1][fringe],
        np.maximum(rgb[:, :, 0][fringe], rgb[:, :, 2][fringe]),
    )
    return Image.fromarray(rgb, "RGBA")


def make_program_bases(source: Image.Image) -> None:
    """Export text-free base plates; labels and values are intended for program UI."""
    base_dir = OUT / "runtime_bases"
    base_dir.mkdir(parents=True, exist_ok=True)

    # Copy exact structural plates and cover only volatile label/value interiors.
    # These flat fills stay strictly inside panel borders; they do not alter the baked
    # reference slices above.
    edits = {
        "wave_status_base": ((194, 8, 467, 101), [(26, 21, 247, 71, (20, 63, 105, 255))]),
        "time_status_base": ((468, 8, 651, 101), [(23, 22, 160, 70, (20, 63, 105, 255))]),
        "currency_status_base": ((658, 8, 894, 104), [(76, 22, 221, 72, (19, 30, 48, 255))]),
    }
    for name, (bounds, rectangles) in edits.items():
        crop = remove_border_grass(source.crop(bounds).convert("RGBA"))
        draw = ImageDraw.Draw(crop, "RGBA")
        for x0, y0, x1, y1, color in rectangles:
            draw.rounded_rectangle((x0, y0, x1, y1), radius=14, fill=color)
        crop.save(base_dir / f"{name}.png")

    # Compact button and bottom-panel bases.  The source's outer highlight and
    # silhouette are retained, while only volatile icon/text interiors are reset.
    reset_bases = {
        "pause_button_base": ((18, 8, 113, 106), (11, 11, 84, 84, (24, 148, 223, 255), 18)),
        "skill_panel_base": ((23, 1448, 421, 1604), (14, 15, 383, 141, (40, 61, 88, 255), 22)),
        "item_refresh_base": ((499, 1448, 638, 1590), (12, 12, 126, 126, (17, 89, 151, 255), 20)),
        "item_wand_base": ((628, 1448, 759, 1590), (12, 12, 118, 126, (80, 53, 151, 255), 20)),
        "item_lock_base": ((750, 1448, 891, 1590), (12, 12, 128, 126, (71, 74, 92, 255), 20)),
    }
    for name, (bounds, rectangle) in reset_bases.items():
        crop = remove_border_grass(source.crop(bounds).convert("RGBA"))
        x0, y0, x1, y1, color, radius = rectangle
        ImageDraw.Draw(crop, "RGBA").rounded_rectangle(
            (x0, y0, x1, y1), radius=radius, fill=color
        )
        crop.save(base_dir / f"{name}.png")


def main() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(SOURCE)
    OUT.mkdir(parents=True, exist_ok=True)
    source = Image.open(SOURCE).convert("RGBA")
    manifest = {
        "source": str(SOURCE),
        "canvas": {"width": source.width, "height": source.height},
        "assets": [],
    }
    for name, bounds in SLICES.items():
        target = OUT / f"{name}.png"
        target.parent.mkdir(parents=True, exist_ok=True)
        result = remove_border_grass(
            source.crop(bounds).convert("RGBA"), include_cream_road=name.startswith("core/")
        )
        result.save(target)
        manifest["assets"].append(
            {"file": str(target.relative_to(OUT)).replace("\\", "/"), "bounds": bounds}
        )
    make_program_bases(source)
    (OUT / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8"
    )


if __name__ == "__main__":
    main()
