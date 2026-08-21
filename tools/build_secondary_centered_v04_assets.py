#!/usr/bin/env python3
"""Rebuild the historical centered-secondary package into production staging.

The current runtime is split by interface under assets/runtime/ui/interfaces
and shared. This legacy generator must never recreate secondary_centered_v04
inside the runtime tree; active interface assets are maintained in place.
"""

from pathlib import Path
import json
import shutil

from PIL import Image, ImageChops, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/runtime/ui/secondary_complete_v03"
PRODUCTION = ROOT / "art/production/ui/chapter01/2026-08-13_centered_interfaces_runtime_v04"
OUT = PRODUCTION / "generated_legacy_package"
REFERENCE_COMPOSITES = ROOT / "art/production/ui/chapter01/2026-08-13_centered_interfaces_v01/reference_composites"

PAGES = {
    "ui_battle_pause_shell_v03.png": (384, 282),
    "ui_exit_confirm_shell_v03.png": (299, 176),
    "ui_settings_shell_v03.png": (512, 717),
    "ui_clear_data_confirm_shell_v03.png": (326, 189),
    "ui_daily_signin_shell_v03.png": (915, 453),
    # Export at 2x so the 700x714 runtime presentation downsamples cleanly
    # instead of magnifying a 445px review composite.
    "ui_benefits_shell_v03.png": (890, 908),
    "ui_first_purchase_gift_shell_v03.png": (461, 454),
    "ui_piggy_bank_shell_v03.png": (445, 493),
    "ui_shop_shell_v03.png": (465, 493),
}

# Pause and exit confirmation are fixed-copy interfaces.  Their V03 generated
# masters drifted from the approved effect image (most visibly the two pause
# icons and action-tile vertical placement).  Build their runtime shells from
# the repository-owned visual-truth composites, then erase only the text bands
# so Godot can continue to draw accessible, scalable text at runtime.
FIXED_MODAL_REFERENCES = {
    "ui_battle_pause_shell_v03.png": REFERENCE_COMPOSITES / "ui_battle_pause_reference.png",
    "ui_exit_confirm_shell_v03.png": REFERENCE_COMPOSITES / "ui_exit_confirm_reference.png",
    # The approved benefits composition has the compact title ribbon and the
    # two cards 24 px higher than the generated V03 shell.  Use it as the
    # geometry source, then remove all baked copy and the obsolete four-state
    # showcase before Godot adds live text and the single purchase action.
    "ui_benefits_shell_v03.png": REFERENCE_COMPOSITES / "ui_benefits_reference.png",
}

TEXT_BANDS = {
    "ui_battle_pause_shell_v03.png": [
        # box (left, top, right, bottom), axis, clean samples on both sides.
        ((132, 29, 251, 74), "vertical", 24, 80),
        # Horizontal reconstruction avoids dragging the icon drop shadows down
        # through the lower half of the two action tiles.
        ((72, 204, 143, 241), "horizontal", 66, 149),
        ((239, 204, 313, 241), "horizontal", 230, 322),
    ],
    "ui_exit_confirm_shell_v03.png": [
        ((42, 20, 255, 51), "vertical", 16, 55),
        ((25, 101, 132, 135), "vertical", 97, 139),
        ((164, 101, 269, 135), "vertical", 97, 139),
    ],
    "ui_benefits_shell_v03.png": [
        # Ribbon title.
        ((91, 18, 181, 62), "horizontal", 87, 190),
    ],
}


def erase_text_bands(image: Image.Image, filename: str) -> Image.Image:
    """Restore the smooth painted surface underneath fixed reference text."""
    result = image.copy().convert("RGBA")
    source = image.convert("RGBA")
    source_pixels = source.load()
    target_pixels = result.load()
    for box, axis, sample_start, sample_end in TEXT_BANDS.get(filename, []):
        x0, y0, x1, y1 = box
        span = max(1, sample_end - sample_start)
        for y in range(y0, y1):
            for x in range(x0, x1):
                if axis == "horizontal":
                    t = max(0.0, min(1.0, (x - sample_start) / span))
                    start = source_pixels[sample_start, y]
                    end = source_pixels[sample_end, y]
                else:
                    t = max(0.0, min(1.0, (y - sample_start) / span))
                    start = source_pixels[x, sample_start]
                    end = source_pixels[x, sample_end]
                target_pixels[x, y] = tuple(round(start[channel] * (1.0 - t) + end[channel] * t) for channel in range(4))
    return result


def clear_benefits_state_showcase(image: Image.Image) -> Image.Image:
    """Remove the four art-review states while retaining the painted frame."""
    result = image.copy().convert("RGBA")
    pixels = result.load()
    # The old row lives entirely inside the outer frame.  Rebuild that inner
    # field with the panel's subtle blue-white vertical gradient, leaving the
    # border and lower bevel untouched for a clean single CTA overlay.
    top = (213, 223, 234, 255)
    bottom = (214, 226, 237, 255)
    y0, y1 = 350, 438
    for y in range(y0, y1):
        t = (y - y0) / max(1, y1 - y0 - 1)
        color = tuple(round(top[channel] * (1.0 - t) + bottom[channel] * t) for channel in range(4))
        for x in range(14, 431):
            pixels[x, y] = color
    return result


def restore_benefits_bottom_edge(image: Image.Image) -> Image.Image:
    """Replace the keyed green hairline with the complete formal blue bevel."""
    result = image.copy().convert("RGBA")
    donor_path = SOURCE / "frames/ui_benefits_shell_v03.png"
    if not donor_path.exists():
        return result
    donor = Image.open(donor_path).convert("RGBA").resize(result.size, Image.Resampling.LANCZOS)
    donor = remove_magenta_edge(donor)
    strip_y = max(0, result.height - 16)
    result.paste(donor.crop((0, strip_y, result.width, result.height)), (0, strip_y))
    return result


def restore_benefits_card_interiors(image: Image.Image) -> Image.Image:
    """Erase baked card copy without replacing the approved borders or icons."""
    result = image.copy().convert("RGBA")
    source = image.convert("RGBA")
    source_pixels = source.load()
    target_pixels = result.load()

    def erase_copy(box: tuple[int, int, int, int], sample_span: tuple[int, int]) -> None:
        x0, y0, x1, y1 = box
        sx0, sx1 = sample_span
        for y in range(y0, y1):
            samples = []
            for x in range(sx0, sx1):
                r, g, b, a = source_pixels[x, y]
                # Card paint is bright and near-neutral; dark or saturated
                # pixels belong to glyphs and their outline/shadow.
                if a > 240 and min(r, g, b) > 175 and max(r, g, b) - min(r, g, b) < 52:
                    samples.append((r, g, b, a))
            if not samples:
                continue
            samples.sort(key=lambda pixel: sum(pixel[:3]))
            color = samples[len(samples) // 2]
            for x in range(x0, x1):
                target_pixels[x, y] = color

    erase_copy((56, 210, 183, 243), (29, 208))
    erase_copy((273, 210, 376, 243), (237, 416))
    erase_copy((31, 252, 209, 295), (29, 208))
    erase_copy((247, 252, 407, 322), (237, 416))

    # Keep the reference pill's exact border, highlights and shadow.  Erase
    # only the baked glyphs by extending the untouched green paint across the
    # centre of each scanline; compositing another button here creates a
    # visible second left edge after runtime scaling.
    for y in range(301, 329):
        left = source_pixels[66, y]
        right = source_pixels[174, y]
        for x in range(67, 174):
            t = (x - 67) / 106.0
            target_pixels[x, y] = tuple(
                round(left[channel] * (1.0 - t) + right[channel] * t)
                for channel in range(4)
            )
    return result


def fixed_modal_shell(filename: str, size: tuple[int, int]) -> Image.Image | None:
    reference_path = FIXED_MODAL_REFERENCES.get(filename)
    if reference_path is None or not reference_path.exists():
        return None
    logical_size = (445, 454) if filename == "ui_benefits_shell_v03.png" else size
    image = Image.open(reference_path).convert("RGBA")
    if image.size != logical_size:
        image = image.resize(logical_size, Image.Resampling.LANCZOS)
    image = erase_text_bands(image, filename)
    if filename == "ui_benefits_shell_v03.png":
        image = restore_benefits_card_interiors(image)
        image = clear_benefits_state_showcase(image)
        image = clear_connected_green_backdrop(image)
    if image.size != size:
        image = image.resize(size, Image.Resampling.LANCZOS)
    return image

COMMERCIAL_REFERENCE = Path(r"C:\Users\PC\.codex\attachments\e113723b-1fb5-4076-8547-4edec247b367\image-1.png")
PAUSE_REFERENCE = Path(r"C:\Users\PC\.codex\attachments\e113723b-1fb5-4076-8547-4edec247b367\image-2.png")
DAILY_REFERENCE = Path(r"C:\Users\PC\.codex\attachments\e113723b-1fb5-4076-8547-4edec247b367\image-3.png")
COMMERCIAL_CROPS = {
    "ui_benefits_shell_v03.png": (13, 704, 458, 1158),
    "ui_first_purchase_gift_shell_v03.png": (468, 704, 929, 1158),
    "ui_piggy_bank_shell_v03.png": (13, 1165, 458, 1658),
    "ui_shop_shell_v03.png": (464, 1165, 929, 1658),
}

APPROVED_CROPS = {
    "ui_battle_pause_shell_v03.png": (PAUSE_REFERENCE, (276, 317, 660, 599), 27),
    "ui_exit_confirm_shell_v03.png": (PAUSE_REFERENCE, (604, 629, 903, 805), 23),
    "ui_settings_shell_v03.png": (PAUSE_REFERENCE, (65, 873, 577, 1590), 31),
    "ui_clear_data_confirm_shell_v03.png": (PAUSE_REFERENCE, (579, 1403, 905, 1592), 27),
    "ui_daily_signin_shell_v03.png": (DAILY_REFERENCE, (13, 1212, 928, 1665), 0),
    "ui_benefits_shell_v03.png": (COMMERCIAL_REFERENCE, (13, 704, 458, 1158), 26),
    "ui_first_purchase_gift_shell_v03.png": (COMMERCIAL_REFERENCE, (468, 704, 929, 1158), 26),
    "ui_piggy_bank_shell_v03.png": (COMMERCIAL_REFERENCE, (13, 1165, 458, 1658), 27),
    "ui_shop_shell_v03.png": (COMMERCIAL_REFERENCE, (464, 1165, 929, 1658), 27),
}


def edge_qa(image: Image.Image, out_path: Path) -> None:
    tile_w = image.width + 24
    qa = Image.new("RGB", (tile_w * 3, image.height + 24), "white")
    for index, color in enumerate(("white", "#aeb5c0", "black")):
        bg = Image.new("RGB", (tile_w, image.height + 24), color)
        bg.paste(image, (12, 12), image)
        qa.paste(bg, (index * tile_w, 0))
    qa.save(out_path, optimize=True)


def remove_magenta_edge(image: Image.Image) -> Image.Image:
    """Remove the chroma-key hairline left on transparent outer contours."""
    result = image.copy()
    pixels = result.load()
    candidates = set()
    seeds = []
    for y in range(result.height):
        for x in range(result.width):
            r, g, b, a = pixels[x, y]
            if a > 0 and min(r, b) - g >= 28:
                candidates.add((x, y))
    for x, y in candidates:
        touches_transparency = x == 0 or y == 0 or x == result.width - 1 or y == result.height - 1
        if not touches_transparency:
            for ny in range(max(0, y - 1), min(result.height, y + 2)):
                for nx in range(max(0, x - 1), min(result.width, x + 2)):
                    if pixels[nx, ny][3] < 24:
                        touches_transparency = True
                        break
                if touches_transparency:
                    break
        if touches_transparency:
            seeds.append((x, y))
    connected = set(seeds)
    stack = list(seeds)
    while stack:
        x, y = stack.pop()
        for point in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if point in candidates and point not in connected:
                connected.add(point)
                stack.append(point)
    for x, y in connected:
        r, g, b, _a = pixels[x, y]
        pixels[x, y] = (r, g, b, 0)
    return result


def make_panel_opaque(image: Image.Image) -> Image.Image:
    """Generated shells use transparency only outside/at antialiased edges."""
    result = image.copy()
    pixels = result.load()
    for y in range(result.height):
        for x in range(result.width):
            r, g, b, a = pixels[x, y]
            if a >= 72:
                pixels[x, y] = (r, g, b, 255)
    return result


def overlay_approved_header(target: Image.Image, filename: str, reference: Image.Image | None) -> Image.Image:
    if reference is None or filename not in COMMERCIAL_CROPS:
        return target
    crop = reference.crop(COMMERCIAL_CROPS[filename]).convert("RGBA")
    if crop.size != target.size:
        crop = crop.resize(target.size, Image.Resampling.LANCZOS)
    header_height = min(104, target.height)
    header = crop.crop((0, 0, target.width, header_height))
    pixels = header.load()
    green = set()
    stack = []
    for x in range(header.width):
        stack.extend(((x, 0), (x, header.height - 1)))
    for y in range(header.height):
        stack.extend(((0, y), (header.width - 1, y)))
    while stack:
        x, y = stack.pop()
        if (x, y) in green:
            continue
        r, g, b, _a = pixels[x, y]
        looks_like_green_backdrop = g > r * 1.12 and g > b * 1.08 and g > 62
        if not looks_like_green_backdrop:
            continue
        green.add((x, y))
        for point in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= point[0] < header.width and 0 <= point[1] < header.height:
                stack.append(point)
    for x, y in green:
        r, g, b, _a = pixels[x, y]
        pixels[x, y] = (r, g, b, 0)
    result = target.copy()
    clear = Image.new("RGBA", (target.width, header_height), (0, 0, 0, 0))
    result.paste(clear, (0, 0))
    result.alpha_composite(header, (0, 0))
    return result


def rounded_alpha(image: Image.Image, radius: int) -> Image.Image:
    if radius <= 0:
        return image
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, image.width - 1, image.height - 1), radius=radius, fill=255)
    image.putalpha(ImageChops.multiply(image.getchannel("A"), mask))
    return image


def clear_connected_green_backdrop(image: Image.Image) -> Image.Image:
    """Remove only green scene pixels connected to the crop boundary."""
    result = image.copy()
    pixels = result.load()
    backdrop: set[tuple[int, int]] = set()
    stack: list[tuple[int, int]] = []
    for x in range(result.width):
        stack.extend(((x, 0), (x, result.height - 1)))
    for y in range(result.height):
        stack.extend(((0, y), (result.width - 1, y)))
    while stack:
        x, y = stack.pop()
        if (x, y) in backdrop:
            continue
        r, g, b, _a = pixels[x, y]
        if not (g >= 38 and g > r * 1.10 and g > b * 1.06):
            continue
        backdrop.add((x, y))
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < result.width and 0 <= ny < result.height:
                stack.append((nx, ny))
    for x, y in backdrop:
        r, g, b, _a = pixels[x, y]
        pixels[x, y] = (r, g, b, 0)
    return result


def approved_shell(filename: str, size: tuple[int, int]) -> Image.Image | None:
    if filename not in APPROVED_CROPS:
        return None
    source_path, box, radius = APPROVED_CROPS[filename]
    if not source_path.exists():
        return None
    image = Image.open(source_path).convert("RGBA").crop(box)
    if image.size != size:
        image = image.resize(size, Image.Resampling.LANCZOS)
    if filename == "ui_daily_signin_shell_v03.png":
        mask = Image.new("L", image.size, 0)
        draw = ImageDraw.Draw(mask)
        draw.rounded_rectangle((24, 0, 278, 104), radius=26, fill=255)
        draw.rounded_rectangle((280, 0, 580, 116), radius=28, fill=255)
        draw.rounded_rectangle((0, 80, 914, 431), radius=41, fill=255)
        image.putalpha(mask)
        return image
    if source_path == COMMERCIAL_REFERENCE:
        image = clear_connected_green_backdrop(image)
    return rounded_alpha(image, radius)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    shutil.copytree(SOURCE / "elements", OUT / "elements", dirs_exist_ok=True, ignore=shutil.ignore_patterns("*.import"))
    frames = OUT / "frames"
    frames.mkdir(parents=True, exist_ok=True)
    qa = PRODUCTION / "qa/edge"
    qa.mkdir(parents=True, exist_ok=True)
    records = []
    commercial_reference = Image.open(COMMERCIAL_REFERENCE).convert("RGBA") if COMMERCIAL_REFERENCE.exists() else None

    for filename, size in PAGES.items():
        target = fixed_modal_shell(filename, size)
        if target is None:
            source = Image.open(SOURCE / "frames" / filename).convert("RGBA")
            target = remove_magenta_edge(source.resize(size, Image.Resampling.LANCZOS))
        target.save(frames / filename, optimize=True)
        edge_qa(target, qa / filename)
        records.append({
            "file": f"art/production/ui/chapter01/2026-08-13_centered_interfaces_runtime_v04/generated_legacy_package/frames/{filename}",
            "size": list(size),
            "alpha": True,
            "text_baked": False,
            "pivot": [0.5, 0.5],
            "opening_anchor": "screen_center",
            "uniform_scale_only": True,
        })

    # Preserve the source's row-safe split while exporting at logical size.
    task_parts = (("top", 396), ("middle", 396), ("bottom", 395))
    assembled = Image.new("RGBA", (915, 1187), (0, 0, 0, 0))
    y = 0
    for suffix, height in task_parts:
        filename = f"ui_daily_tasks_shell_v03_{suffix}.png"
        source_part = Image.open(SOURCE / "frames" / filename).convert("RGBA")
        part = remove_magenta_edge(source_part.resize((915, height), Image.Resampling.LANCZOS))
        part.save(frames / filename, optimize=True)
        assembled.alpha_composite(part, (0, y))
        y += height
        records.append({"file": f"art/production/ui/chapter01/2026-08-13_centered_interfaces_runtime_v04/generated_legacy_package/frames/{filename}", "size": list(part.size), "alpha": True, "text_baked": False})
    edge_qa(assembled, qa / "ui_daily_tasks_shell_v03.png")

    manifest = {
        "purpose": "centered-secondary-ui-runtime",
        "version": "v09",
        "date": "2026-08-13",
        "source": "assets/runtime/ui/secondary_complete_v03",
        "source_overrides": {
            "ui_battle_pause_shell_v03.png": "art/production/ui/chapter01/2026-08-13_centered_interfaces_v01/reference_composites/ui_battle_pause_reference.png",
            "ui_exit_confirm_shell_v03.png": "art/production/ui/chapter01/2026-08-13_centered_interfaces_v01/reference_composites/ui_exit_confirm_reference.png",
            "ui_benefits_shell_v03.png": "art/production/ui/chapter01/2026-08-13_centered_interfaces_v01/reference_composites/ui_benefits_reference.png",
        },
        "visual_truth": [
            "C:/Users/PC/.codex/attachments/e113723b-1fb5-4076-8547-4edec247b367/image-1.png",
            "C:/Users/PC/.codex/attachments/e113723b-1fb5-4076-8547-4edec247b367/image-2.png",
            "C:/Users/PC/.codex/attachments/e113723b-1fb5-4076-8547-4edec247b367/image-3.png",
        ],
        "assets": records,
        "qa": {"white": "generated", "gray": "generated", "black": "generated", "in_game": "pending final visual audit", "dynamic_text": True},
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"assets": len(records), "runtime": str(OUT), "production": str(PRODUCTION)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
