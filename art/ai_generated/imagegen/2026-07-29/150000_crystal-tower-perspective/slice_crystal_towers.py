"""Slice the approved nine-level crystal-tower sheet into clean RGBA sprites.

The source is an AI art sheet with a pale lavender background and numeric badges.
This script estimates the local backdrop, removes it without chroma-key halos, and
keeps the tower contact shadows.  It intentionally does not modify tower colours
or silhouettes.
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image


SOURCE = Path(
    r"C:\Users\PC\.codex\generated_images\019f6905-5ee7-71e0-9823-eaa90fefd4c7"
    r"\exec-b5ec01ba-89cb-40cf-84e3-ca01014ba539.png"
)
OUT_DIR = Path(__file__).with_name("cutouts")

# Bounds were measured from the approved 1254×1254 sheet.  They have generous
# padding around the complete silhouette and contact shadow, while excluding
# neighbouring towers.
TOWERS = {
    1: (85, 125, 380, 425),
    2: (470, 120, 780, 425),
    3: (875, 85, 1195, 435),
    4: (75, 450, 385, 785),
    5: (465, 450, 785, 785),
    6: (870, 450, 1195, 790),
    7: (75, 805, 390, 1160),
    8: (460, 805, 790, 1160),
    9: (865, 800, 1200, 1160),
}

# Number badges are deliberately removed.  Their rectangles do not intersect a
# tower, even where a crop has to extend into a neighbouring grid cell.
BADGES = [
    (35, 35, 135, 135),
    (430, 35, 530, 135),
    (825, 35, 935, 135),
    (35, 420, 135, 520),
    (430, 420, 530, 520),
    (825, 420, 935, 520),
    (35, 780, 135, 890),
    (430, 780, 530, 890),
    (825, 780, 935, 890),
]


def clamp_box(box: tuple[int, int, int, int], width: int, height: int) -> tuple[int, int, int, int]:
    x0, y0, x1, y1 = box
    return max(0, x0), max(0, y0), min(width, x1), min(height, y1)


def fit_background(rgb: np.ndarray, protected: np.ndarray) -> np.ndarray:
    """Fit the smooth lavender background field using only known empty pixels."""
    h, w, _ = rgb.shape
    # Subsampled least squares is more than sufficient for the intentionally
    # smooth painted sheet background and avoids allowing object colours in.
    yy, xx = np.mgrid[0:h:4, 0:w:4]
    usable = protected[0:h:4, 0:w:4] == 0
    x = ((xx[usable] / max(1, w - 1)) * 2.0 - 1.0).astype(np.float32)
    y = ((yy[usable] / max(1, h - 1)) * 2.0 - 1.0).astype(np.float32)
    # The source has a soft, non-linear painted vignette.  A sixth-order field
    # follows it closely without learning object colours from protected cells.
    powers = [(ix, iy) for total in range(7) for ix in range(total + 1) for iy in [total - ix]]
    design = np.stack([x ** ix * y ** iy for ix, iy in powers], axis=1)
    samples = rgb[0:h:4, 0:w:4][usable]
    coefficients, *_ = np.linalg.lstsq(design, samples, rcond=None)

    full_y, full_x = np.mgrid[0:h, 0:w]
    fx = (full_x / max(1, w - 1)) * 2.0 - 1.0
    fy = (full_y / max(1, h - 1)) * 2.0 - 1.0
    full_design = np.stack([fx ** ix * fy ** iy for ix, iy in powers], axis=-1)
    return np.clip(full_design @ coefficients, 0, 255).astype(np.float32)


def matte_from_background(rgb: np.ndarray, background: np.ndarray, badges: list[tuple[int, int, int, int]]) -> np.ndarray:
    """Create a premultiplied-safe RGBA matte, retaining the soft painted shadow."""
    distance = np.sqrt(np.sum((rgb - background) ** 2, axis=2))
    # The small threshold removes paper texture; the gentle ramp keeps the
    # low-contrast contact shadows instead of hard-cutting them.
    opacity = np.clip((distance - 12.0) / 28.0, 0.0, 1.0)
    # Low-alpha colour noise becomes visible on dark game backdrops after
    # un-premultiplication.  This conservative cutoff retains real shadows,
    # whose contrast is significantly higher, while deleting backdrop grain.
    opacity[opacity < 0.10] = 0.0
    for x0, y0, x1, y1 in badges:
        opacity[y0:y1, x0:x1] = 0.0

    safe_opacity = np.maximum(opacity[..., None], 1e-4)
    foreground = (rgb - background * (1.0 - opacity[..., None])) / safe_opacity
    foreground = np.where(opacity[..., None] > 0.0, foreground, 0.0)
    rgba = np.empty((*rgb.shape[:2], 4), dtype=np.uint8)
    rgba[..., :3] = np.clip(foreground, 0, 255).astype(np.uint8)
    rgba[..., 3] = np.rint(opacity * 255).astype(np.uint8)
    return rgba


def trim_rgba(rgba: np.ndarray, padding: int = 12) -> np.ndarray:
    alpha = rgba[..., 3]
    rows, cols = np.where(alpha > 8)
    if len(rows) == 0:
        raise RuntimeError("No foreground found while trimming a tower")
    y0 = max(0, int(rows.min()) - padding)
    y1 = min(rgba.shape[0], int(rows.max()) + padding + 1)
    x0 = max(0, int(cols.min()) - padding)
    x1 = min(rgba.shape[1], int(cols.max()) + padding + 1)
    return rgba[y0:y1, x0:x1]


def make_atlas(sprites: dict[int, Image.Image]) -> Image.Image:
    gap = 28
    max_w = max(image.width for image in sprites.values())
    max_h = max(image.height for image in sprites.values())
    atlas = Image.new("RGBA", (max_w * 3 + gap * 2, max_h * 3 + gap * 2), (0, 0, 0, 0))
    for level, image in sprites.items():
        idx = level - 1
        row, col = divmod(idx, 3)
        x = col * (max_w + gap) + (max_w - image.width) // 2
        y = row * (max_h + gap) + (max_h - image.height) // 2
        atlas.alpha_composite(image, (x, y))
    return atlas


def main() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(f"Missing approved source sheet: {SOURCE}")
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    image = Image.open(SOURCE).convert("RGB")
    rgb = np.asarray(image).astype(np.float32)
    h, w, _ = rgb.shape
    if (w, h) != (1254, 1254):
        raise RuntimeError(f"Expected the approved 1254×1254 sheet, got {w}×{h}")

    protected = np.zeros((h, w), dtype=np.uint8)
    for box in list(TOWERS.values()) + BADGES:
        x0, y0, x1, y1 = clamp_box(box, w, h)
        protected[max(0, y0 - 16):min(h, y1 + 16), max(0, x0 - 16):min(w, x1 + 16)] = 1
    background = fit_background(rgb, protected)
    rgba = matte_from_background(rgb, background, BADGES)

    sprites: dict[int, Image.Image] = {}
    manifest: dict[str, object] = {
        "source": str(SOURCE),
        "source_size": [w, h],
        "notes": "Numeric badges and lavender background removed; contact shadows retained.",
        "sprites": {},
    }
    for level, raw_box in TOWERS.items():
        x0, y0, x1, y1 = clamp_box(raw_box, w, h)
        sprite = trim_rgba(rgba[y0:y1, x0:x1])
        path = OUT_DIR / f"crystal_tower_lv{level:02d}.png"
        output = Image.fromarray(sprite, "RGBA")
        output.save(path)
        sprites[level] = output
        manifest["sprites"][f"lv{level:02d}"] = {
            "file": path.name,
            "size": [output.width, output.height],
            "source_crop": [x0, y0, x1, y1],
        }

    atlas_path = OUT_DIR / "crystal_tower_levels_3x3_transparent.png"
    make_atlas(sprites).save(atlas_path)
    manifest["atlas"] = atlas_path.name
    (OUT_DIR / "crystal_tower_levels_manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"Exported {len(sprites)} tower cutouts to {OUT_DIR}")


if __name__ == "__main__":
    main()
