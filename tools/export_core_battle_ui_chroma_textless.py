"""Export transparent, text-free UI assets from the chroma-key battle UI sheet.

The source sheet intentionally uses an exact #00FF00 background so the same
foreground separation is deterministic and safe for the green refresh glyph.
Only exact chroma pixels become transparent; green pixels inside enclosed UI
icons remain opaque.  Dynamic labels and numeric values are deliberately
cleared so they can be rendered by Godot.
"""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path.cwd()
SOURCE = (
    ROOT
    / "game_mergenTo10_published"
    / "art"
    / "ai_generated"
    / "imagegen"
    / "2026-07-29"
    / "core-battle-ui-chroma-v01"
    / "20260729_core_battle_ui_top_bottom_chroma_v01.png"
)
OUT = (
    ROOT
    / "game_mergenTo10_published"
    / "art"
    / "ai_generated"
    / "slices"
    / "2026-07-29"
    / "core-battle-ui-chroma-textless-v03"
)
KEY = (0, 255, 0)


def chroma_to_alpha(image: Image.Image) -> Image.Image:
    """Apply the local cutout tool's chroma-key intent without keying UI greens."""
    rgba = image.convert("RGBA")
    data = list(rgba.getdata())
    rgba.putdata(
        [(r, g, b, 0) if (r, g, b) == KEY else (r, g, b, a) for r, g, b, a in data]
    )
    return rgba


def fill_rounded(
    image: Image.Image,
    rect: tuple[int, int, int, int],
    color: tuple[int, int, int, int],
    radius: int,
) -> None:
    """Clear volatile text while retaining the outside bevel/outline."""
    ImageDraw.Draw(image, "RGBA").rounded_rectangle(rect, radius=radius, fill=color)


def apply_circle_mask(image: Image.Image, bounds: tuple[int, int, int, int]) -> None:
    """Remove captured parent-panel pixels around a circular standalone icon."""
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).ellipse(bounds, fill=255)
    alpha = image.getchannel("A")
    image.putalpha(Image.composite(alpha, Image.new("L", image.size, 0), mask))


def export_crop(
    source: Image.Image,
    relative_path: str,
    bounds: tuple[int, int, int, int],
    edits: list[tuple[tuple[int, int, int, int], tuple[int, int, int, int], int]] | None = None,
) -> dict[str, object]:
    asset = chroma_to_alpha(source.crop(bounds))
    for rect, color, radius in edits or []:
        fill_rounded(asset, rect, color, radius)
    target = OUT / relative_path
    target.parent.mkdir(parents=True, exist_ok=True)
    asset.save(target, optimize=True)
    return {"file": relative_path.replace("\\", "/"), "bounds": bounds}


def write_preview(files: list[str]) -> None:
    """A QA-only contact sheet; this is not a runtime asset."""
    columns, cell_w, cell_h = 2, 440, 220
    rows = (len(files) + columns - 1) // columns
    preview = Image.new("RGBA", (columns * cell_w, rows * cell_h), (231, 232, 240, 255))
    for index, relative_path in enumerate(files):
        asset = Image.open(OUT / relative_path).convert("RGBA")
        asset.thumbnail((cell_w - 34, cell_h - 56), Image.Resampling.LANCZOS)
        x = (index % columns) * cell_w + (cell_w - asset.width) // 2
        y = (index // columns) * cell_h + 35
        preview.alpha_composite(asset, (x, y))
        ImageDraw.Draw(preview).text((index % columns * cell_w + 12, (index // columns) * cell_h + 10), relative_path, fill=(30, 39, 65, 255))
    preview.convert("RGB").save(OUT / "_qa_textless_contact_sheet.png", optimize=True)


def main() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(SOURCE)
    OUT.mkdir(parents=True, exist_ok=True)
    source = Image.open(SOURCE).convert("RGBA")
    manifest: list[dict[str, object]] = []

    # Top bar.  Only volatile labels/values are cleared; structural icons stay.
    manifest.append(export_crop(source, "top/pause_button.png", (22, 14, 113, 104)))
    manifest.append(
        export_crop(
            source,
            "top/wave_status_frame.png",
            (204, 14, 466, 98),
            [((15, 15, 247, 68), (23, 62, 96, 255), 17)],
        )
    )
    manifest.append(
        export_crop(
            source,
            "top/timer_status_frame.png",
            (476, 14, 653, 98),
            [((15, 15, 162, 68), (23, 62, 96, 255), 13)],
        )
    )
    clock = chroma_to_alpha(source.crop((490, 23, 540, 76)))
    apply_circle_mask(clock, (2, 2, 48, 48))
    (OUT / "top").mkdir(parents=True, exist_ok=True)
    clock.save(OUT / "top/timer_clock_icon.png", optimize=True)
    manifest.append({"file": "top/timer_clock_icon.png", "bounds": (490, 23, 540, 76)})

    currency_frame = chroma_to_alpha(source.crop((666, 14, 884, 98)))
    # The coin overlaps the value plate in the source.  Rebuild only the plate so
    # the skull coin can be positioned independently by the scene.
    alpha = currency_frame.getchannel("A")
    ImageDraw.Draw(alpha).rectangle((0, 0, 79, currency_frame.height), fill=0)
    currency_frame.putalpha(alpha)
    fill_rounded(currency_frame, (16, 16, 203, 65), (20, 34, 55, 255), 13)
    currency_frame.save(OUT / "top/currency_status_frame.png", optimize=True)
    manifest.append({"file": "top/currency_status_frame.png", "bounds": (666, 14, 884, 98)})

    skull = chroma_to_alpha(source.crop((669, 16, 747, 95)))
    apply_circle_mask(skull, (3, 3, 75, 75))
    skull.save(OUT / "top/currency_skull_icon.png", optimize=True)
    manifest.append({"file": "top/currency_skull_icon.png", "bounds": (669, 16, 747, 95)})

    # Bottom HUD.  The icon and meter are separately exported to support state swaps.
    manifest.append(
        export_crop(
            source,
            "bottom/skill_panel_frame.png",
            (33, 1451, 418, 1604),
            [((15, 13, 370, 138), (35, 56, 82, 255), 20)],
        )
    )
    manifest.append(export_crop(source, "bottom/skill_disabled_icon.png", (49, 1472, 151, 1577)))
    manifest.append(
        export_crop(
            source,
            "bottom/skill_meter_frame.png",
            (163, 1537, 401, 1586),
            [((6, 8, 232, 40), (15, 31, 51, 255), 10)],
        )
    )
    manifest.append(
        export_crop(
            source,
            "bottom/item_refresh_button.png",
            (512, 1454, 624, 1584),
            [((87, 101, 109, 129), (31, 139, 218, 255), 10)],
        )
    )
    manifest.append(
        export_crop(
            source,
            "bottom/item_wand_button.png",
            (636, 1454, 748, 1584),
            [((86, 101, 109, 129), (31, 139, 218, 255), 10)],
        )
    )
    manifest.append(export_crop(source, "bottom/item_lock_button.png", (762, 1454, 881, 1595)))

    files = [str(item["file"]) for item in manifest]
    (OUT / "manifest.json").write_text(
        json.dumps(
            {
                "source": str(SOURCE),
                "canvas": {"width": source.width, "height": source.height},
                "background_key": "#00FF00",
                "text_policy": "All labels, counters and values are runtime text.",
                "assets": manifest,
            },
            ensure_ascii=False,
            indent=2,
        ),
        encoding="utf-8",
    )
    write_preview(files)


if __name__ == "__main__":
    main()
