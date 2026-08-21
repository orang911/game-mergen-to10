from __future__ import annotations

import colorsys
import json
import shutil
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art/production/ui/daily_program_composition/2026-08-16_cutouts_v01/cutouts"
PRODUCTION = ROOT / "art/production/ui/daily_program_composition/2026-08-16_cutouts_v02"
RUNTIME = ROOT / "assets/runtime/ui/interfaces/daily_program"
GUTTER = 6


SHARED_BACKPLATE_GROUPS = [
    ["daily_task_row_default_v01.png", "daily_task_row_selected_v01.png"],
    ["daily_button_disabled_v01.png", "daily_button_claimed_v01.png", "daily_button_claim_v01.png"],
    ["daily_progress_track_v01.png", "daily_progress_fill_v01.png"],
    ["daily_signin_card_default_v01.png", "daily_signin_card_selected_v01.png", "daily_signin_card_premium_v01.png"],
]


def _shifted(array: np.ndarray, dy: int, dx: int) -> np.ndarray:
    height, width = array.shape[:2]
    pad = np.pad(array, ((1, 1), (1, 1)) + ((0, 0),) * (array.ndim - 2), mode="constant")
    return pad[1 + dy : 1 + dy + height, 1 + dx : 1 + dx + width]


def _bleed_rgb(rgb: np.ndarray, foreground: np.ndarray, radius: int = 5) -> np.ndarray:
    result = rgb.astype(np.float32).copy()
    known = foreground.copy()
    for _ in range(radius):
        sums = np.zeros_like(result)
        counts = np.zeros(known.shape, dtype=np.float32)
        for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (-1, 1), (1, -1), (1, 1)):
            neighbor_known = _shifted(known.astype(np.uint8), dy, dx).astype(bool)
            neighbor_rgb = _shifted(result, dy, dx)
            sums += neighbor_rgb * neighbor_known[:, :, None]
            counts += neighbor_known
        fill = (~known) & (counts > 0)
        result[fill] = sums[fill] / counts[fill, None]
        known |= fill
    return np.clip(np.rint(result), 0, 255).astype(np.uint8)


def _run_count(row: np.ndarray) -> int:
    padded = np.pad(row.astype(np.uint8), (1, 0), mode="constant")
    return int(np.count_nonzero((padded[1:] == 1) & (padded[:-1] == 0)))


def _remove_fragmented_boundary_rows(mask: np.ndarray, remove_sparse: bool = False, ratio: float = 0.82) -> np.ndarray:
    result = mask.copy()
    for _ in range(result.shape[0]):
        visible_rows = np.where(result.any(axis=1))[0]
        if len(visible_rows) < 3:
            break
        first, second = int(visible_rows[0]), int(visible_rows[1])
        fragmented = _run_count(result[first]) > 1
        sparse = remove_sparse and result[first].sum() < result[second].sum() * ratio
        if fragmented or sparse:
            result[first] = False
        else:
            break
    for _ in range(result.shape[0]):
        visible_rows = np.where(result.any(axis=1))[0]
        if len(visible_rows) < 3:
            break
        last, previous = int(visible_rows[-1]), int(visible_rows[-2])
        fragmented = _run_count(result[last]) > 1
        sparse = remove_sparse and result[last].sum() < result[previous].sum() * ratio
        if fragmented or sparse:
            result[last] = False
        else:
            break
    return result


def clean_alpha(
    image: Image.Image,
    remove_sparse_boundary_rows: bool = False,
    preserve_multicomponent_edges: bool = False,
) -> Image.Image:
    rgba = np.asarray(image.convert("RGBA"), dtype=np.uint8)
    hard_array = rgba[:, :, 3] > 24
    # UI plates should have one continuous outer contour, but several icons
    # legitimately begin with two separated tips/feet.  Treating those rows as
    # segmentation noise used to delete half of the crossed swords and trim the
    # chest, coin and calendar artwork.
    if not preserve_multicomponent_edges:
        hard_array = _remove_fragmented_boundary_rows(hard_array, remove_sparse_boundary_rows)
    hard = Image.fromarray(np.where(hard_array, 255, 0).astype(np.uint8), mode="L")
    # Opening removes the one-pixel spikes left by checker-background segmentation.
    opened = hard.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.MaxFilter(3))
    # A real coverage ramp avoids the staircase edge produced by the old 0.22px blur.
    blurred = opened.filter(ImageFilter.GaussianBlur(0.78))
    # The blur is derived from the already cleaned binary silhouette, so letting
    # it extend into transparent pixels cannot bring checker pixels back.  The
    # previous minimum(opened, blurred) clipped the outer half of the coverage
    # ramp and made every contour jump straight from alpha 0 to about 165.
    alpha_array = np.asarray(blurred, dtype=np.uint8)
    rgb = _bleed_rgb(rgba[:, :, :3], np.asarray(opened, dtype=np.uint8) >= 128)
    # Fully transparent pixels must not retain the white checker RGB. Godot's
    # fix_alpha_border importer will create the required color bleed itself.
    rgb[alpha_array == 0] = 0
    output = np.dstack((rgb, alpha_array))
    return Image.fromarray(output, mode="RGBA")


def subject(image: Image.Image) -> Image.Image:
    alpha = np.asarray(image.getchannel("A"), dtype=np.uint8)
    ys, xs = np.where(alpha > 2)
    if not len(xs):
        raise ValueError("Asset has no visible alpha")
    return image.crop((int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1))


def with_gutter(image: Image.Image, gutter: int = GUTTER) -> Image.Image:
    item = subject(image)
    canvas = Image.new("RGBA", (item.width + gutter * 2, item.height + gutter * 2), (0, 0, 0, 0))
    canvas.alpha_composite(item, (gutter, gutter))
    return canvas


def shared_canvas(images: list[Image.Image], gutter: int = GUTTER) -> list[Image.Image]:
    items = [subject(image) for image in images]
    width = max(item.width for item in items) + gutter * 2
    height = max(item.height for item in items) + gutter * 2
    results: list[Image.Image] = []
    for item in items:
        canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        canvas.alpha_composite(item, ((width - item.width) // 2, (height - item.height) // 2))
        results.append(canvas)
    return results


def recolor(image: Image.Image, hue: float, value_scale: float = 1.0) -> Image.Image:
    result = image.copy().convert("RGBA")
    pixels = result.load()
    for y in range(result.height):
        for x in range(result.width):
            red, green, blue, alpha = pixels[x, y]
            if alpha == 0:
                continue
            _old_hue, saturation, value = colorsys.rgb_to_hsv(red / 255.0, green / 255.0, blue / 255.0)
            if saturation <= 0.12:
                continue
            new_red, new_green, new_blue = colorsys.hsv_to_rgb(
                hue, min(1.0, saturation * 1.05), min(1.0, value * value_scale)
            )
            pixels[x, y] = (round(new_red * 255), round(new_green * 255), round(new_blue * 255), alpha)
    return result


def make_return_arrow() -> Image.Image:
    scale = 4
    canvas = Image.new("RGBA", (128 * scale, 128 * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)

    def polygon(points: list[tuple[int, int]], fill: tuple[int, int, int, int], offset=(0, 0)) -> None:
        draw.polygon([((x + offset[0]) * scale, (y + offset[1]) * scale) for x, y in points], fill=fill)

    outer = [(25, 53), (66, 53), (66, 38), (104, 64), (66, 94), (66, 78), (25, 78)]
    inner = [(30, 58), (70, 58), (70, 48), (96, 64), (70, 85), (70, 73), (30, 73)]
    polygon(outer, (9, 23, 47, 190), (2, 4))
    polygon(outer, (103, 119, 153, 255))
    polygon(inner, (255, 255, 255, 255))
    resized = np.asarray(canvas.resize((128, 128), Image.Resampling.LANCZOS), dtype=np.uint8).copy()
    resized[:, :, :3][resized[:, :, 3] == 0] = 0
    return Image.fromarray(resized, mode="RGBA")


def validate_asset(path: Path) -> dict[str, object]:
    image = Image.open(path).convert("RGBA")
    alpha = np.asarray(image.getchannel("A"), dtype=np.uint8)
    if max(image.size) > 2048:
        raise ValueError(f"Mobile texture exceeds 2048px: {path} {image.size}")
    if not np.any(alpha > 0):
        raise ValueError(f"Empty runtime texture: {path}")
    if np.any(alpha[0] > 0) or np.any(alpha[-1] > 0) or np.any(alpha[:, 0] > 0) or np.any(alpha[:, -1] > 0):
        raise ValueError(f"Texture has no transparent isolation gutter: {path}")
    partial = alpha[(alpha > 0) & (alpha < 255)]
    partial_levels = np.unique(partial)
    if not len(partial) or int(partial.min()) > 24 or len(partial_levels) < 32:
        raise ValueError(f"Texture edge lacks a smooth coverage ramp: {path}")
    if path.name.startswith("daily_progress_"):
        for y in range(alpha.shape[0]):
            xs = np.where(alpha[y] > 8)[0]
            if len(xs) > 1 and np.any(np.diff(xs) > 1):
                raise ValueError(f"Progress texture has a broken scanline: {path} y={y}")
    transparent_rgb = np.asarray(image, dtype=np.uint8)[:, :, :3][alpha == 0]
    if np.any(transparent_rgb != 0):
        raise ValueError(f"Transparent pixels retain RGB contamination: {path}")
    return {
        "file": path.relative_to(ROOT).as_posix(),
        "size": list(image.size),
        "alpha": True,
        "alpha_partial_min": int(partial.min()),
        "alpha_partial_max": int(partial.max()),
        "text_baked": False,
    }


def save_asset(image: Image.Image, relative: Path) -> None:
    production_path = PRODUCTION / "cutouts" / relative
    runtime_path = RUNTIME / relative
    production_path.parent.mkdir(parents=True, exist_ok=True)
    runtime_path.parent.mkdir(parents=True, exist_ok=True)
    image.save(production_path, "PNG", optimize=True)
    image.save(runtime_path, "PNG", optimize=True)


def make_qa_contact_sheet(assets: list[tuple[str, Image.Image]], output: Path) -> None:
    tile_width, tile_height, columns = 360, 280, 4
    rows = (len(assets) + columns - 1) // columns
    sheet = Image.new("RGBA", (tile_width * columns, tile_height * rows), (24, 31, 46, 255))
    draw = ImageDraw.Draw(sheet)
    for index, (name, image) in enumerate(assets):
        x = (index % columns) * tile_width
        y = (index // columns) * tile_height
        scale = min((tile_width - 30) / image.width, (tile_height - 55) / image.height, 1.0)
        display = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)
        sheet.alpha_composite(display, (x + (tile_width - display.width) // 2, y + 8))
        draw.text((x + 8, y + tile_height - 30), name, fill=(240, 244, 252, 255))
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.convert("RGB").save(output, "PNG", optimize=True)


def main() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(SOURCE)
    for output in (PRODUCTION, RUNTIME):
        if output.exists():
            shutil.rmtree(output)

    source_backplates = SOURCE / "backplates"
    cleaned_backplates = {}
    for path in sorted(source_backplates.glob("*.png")):
        regularize = path.name.startswith("daily_task_row_") or path.name.startswith("daily_progress_")
        cleaned_backplates[path.name] = clean_alpha(Image.open(path), regularize)
    grouped_names = {name for group in SHARED_BACKPLATE_GROUPS for name in group}
    final_backplates: dict[str, Image.Image] = {}
    for group in SHARED_BACKPLATE_GROUPS:
        # Progress bars are rendered at only 34–36 logical pixels high.  A six
        # pixel transparent gutter on both sides consumed a third of that
        # height and made the approved thick pill look like a thin line.
        group_gutter = 2 if all(name.startswith("daily_progress_") for name in group) else GUTTER
        outputs = shared_canvas([cleaned_backplates[name] for name in group], group_gutter)
        final_backplates.update(dict(zip(group, outputs)))
    for name, image in cleaned_backplates.items():
        if name not in grouped_names:
            final_backplates[name] = with_gutter(image)

    slot = final_backplates["daily_icon_slot_v01.png"]
    final_backplates["daily_icon_slot_selected_v01.png"] = recolor(slot, 0.105, 1.06)
    final_backplates["daily_return_button_v02.png"] = recolor(slot, 0.655, 1.02)

    final_icons = {
        path.name: clean_alpha(Image.open(path), preserve_multicomponent_edges=True)
        for path in sorted((SOURCE / "icons").glob("*.png"))
    }
    final_icons["daily_return_arrow_v02.png"] = make_return_arrow()

    qa_assets: list[tuple[str, Image.Image]] = []
    for name, image in final_backplates.items():
        save_asset(image, Path("backplates") / name)
        qa_assets.append((name, image))
    for name, image in final_icons.items():
        save_asset(image, Path("icons") / name)
        qa_assets.append((name, image))

    records = [validate_asset(path) for path in sorted(RUNTIME.rglob("*.png"))]
    manifest = {
        "purpose": "daily-program-composition-clean-alpha-runtime",
        "version": "v02",
        "source": SOURCE.relative_to(ROOT).as_posix(),
        "assets": records,
        "runtime_integrated": True,
        "approved_viewport": [941, 1672],
        "edge_cleanup": "fragmented-row removal, 3x3 opening, 0.78px full coverage blur, 5px RGB bleed, 6px isolation gutter",
    }
    manifest_text = json.dumps(manifest, ensure_ascii=False, indent=2) + "\n"
    (PRODUCTION / "manifest.json").write_text(manifest_text, encoding="utf-8")
    (RUNTIME / "manifest.json").write_text(manifest_text, encoding="utf-8")
    make_qa_contact_sheet(qa_assets, PRODUCTION / "qa/daily_program_v02_dark_qa.png")
    print(json.dumps({"assets": len(records), "production": str(PRODUCTION), "runtime": str(RUNTIME)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
