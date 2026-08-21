from __future__ import annotations

from collections import deque
from pathlib import Path
from typing import Dict

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "source"
BACKPLATES = ROOT / "cutouts" / "backplates"
ICONS = ROOT / "cutouts" / "icons"
PREVIEWS = ROOT / "previews"
QA = ROOT / "qa"
PAD = 12


def components(image: Image.Image, threshold: int = 18) -> list[tuple[int, int, int, int]]:
    visible = np.asarray(image.convert("RGBA").getchannel("A")) > threshold
    h, w = visible.shape
    seen = np.zeros_like(visible, dtype=bool)
    found: list[tuple[int, int, int, int, int]] = []
    for y in range(h):
        for x in range(w):
            if not visible[y, x] or seen[y, x]:
                continue
            queue = deque([(x, y)])
            seen[y, x] = True
            xs: list[int] = []
            ys: list[int] = []
            while queue:
                px, py = queue.popleft()
                xs.append(px)
                ys.append(py)
                for ny in range(max(0, py - 1), min(h, py + 2)):
                    for nx in range(max(0, px - 1), min(w, px + 2)):
                        if visible[ny, nx] and not seen[ny, nx]:
                            seen[ny, nx] = True
                            queue.append((nx, ny))
            if len(xs) > 400:
                found.append((min(xs), min(ys), max(xs) + 1, max(ys) + 1, len(xs)))
    found.sort(key=lambda b: b[4], reverse=True)
    return [(a, b, c, d) for a, b, c, d, _ in found]


def trim(image: Image.Image, padding: int = PAD) -> Image.Image:
    rgba = image.convert("RGBA")
    box = rgba.getchannel("A").getbbox()
    if not box:
        raise ValueError("No visible pixels")
    return rgba.crop((max(0, box[0] - padding), max(0, box[1] - padding),
                      min(rgba.width, box[2] + padding), min(rgba.height, box[3] + padding)))


def remove_border_magenta(image: Image.Image) -> Image.Image:
    """Remove only magenta pixels connected to the outer border.

    The generic soft-key helper over-removed the warm-gold button interior.
    Border flood-fill avoids deleting non-background colors inside controls.
    """
    rgb = np.asarray(image.convert("RGB"), dtype=np.uint8)
    r = rgb[:, :, 0].astype(np.int16)
    g = rgb[:, :, 1].astype(np.int16)
    b = rgb[:, :, 2].astype(np.int16)
    candidate = (r > 205) & (b > 155) & (g < 125) & ((r - g) > 95) & ((b - g) > 70)
    h, w = candidate.shape
    background = np.zeros_like(candidate, dtype=bool)
    queue: deque[tuple[int, int]] = deque()
    for x in range(w):
        for y in (0, h - 1):
            if candidate[y, x] and not background[y, x]:
                background[y, x] = True
                queue.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if candidate[y, x] and not background[y, x]:
                background[y, x] = True
                queue.append((x, y))
    while queue:
        x, y = queue.popleft()
        for ny in range(max(0, y - 1), min(h, y + 2)):
            for nx in range(max(0, x - 1), min(w, x + 2)):
                if candidate[ny, nx] and not background[ny, nx]:
                    background[ny, nx] = True
                    queue.append((nx, ny))
    alpha = np.where(background, 0, 255).astype(np.uint8)
    alpha = np.asarray(Image.fromarray(alpha, "L").filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.22)))
    rgba = image.convert("RGBA")
    rgba.putalpha(Image.fromarray(alpha.astype(np.uint8), "L"))
    return rgba


def shared_canvas(items: list[Image.Image], padding: int = PAD) -> list[Image.Image]:
    cropped = [trim(item, 0) for item in items]
    w = max(item.width for item in cropped) + padding * 2
    h = max(item.height for item in cropped) + padding * 2
    output = []
    for item in cropped:
        canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        canvas.alpha_composite(item, ((w - item.width) // 2, (h - item.height) // 2))
        output.append(canvas)
    return output


def create_dividers() -> Dict[str, Image.Image]:
    color = (164, 197, 237, 210)
    horizontal = Image.new("RGBA", (640, 28), (0, 0, 0, 0))
    draw = ImageDraw.Draw(horizontal)
    draw.rounded_rectangle((12, 12, 294, 15), radius=2, fill=color)
    draw.polygon([(320, 4), (330, 14), (320, 24), (310, 14)], fill=(185, 213, 247, 235))
    draw.polygon([(320, 8), (326, 14), (320, 20), (314, 14)], fill=(232, 243, 255, 245))
    draw.rounded_rectangle((346, 12, 628, 15), radius=2, fill=color)
    vertical = Image.new("RGBA", (28, 320), (0, 0, 0, 0))
    draw = ImageDraw.Draw(vertical)
    draw.rounded_rectangle((12, 8, 15, 312), radius=2, fill=color)
    return {
        "purchase_divider_horizontal_v01.png": horizontal,
        "purchase_divider_vertical_v01.png": vertical,
    }


def save_all(folder: Path, assets: Dict[str, Image.Image]) -> None:
    folder.mkdir(parents=True, exist_ok=True)
    for name, image in assets.items():
        image.save(folder / name, "PNG", optimize=True)


def contact_sheet(assets: Dict[str, Image.Image], bg: tuple[int, int, int], out: Path) -> None:
    tile_w, tile_h, cols = 420, 340, 4
    rows = (len(assets) + cols - 1) // cols
    sheet = Image.new("RGB", (tile_w * cols, tile_h * rows), bg)
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    for i, (name, rgba) in enumerate(assets.items()):
        x0, y0 = (i % cols) * tile_w, (i // cols) * tile_h
        max_w, max_h = tile_w - 36, tile_h - 60
        scale = min(max_w / rgba.width, max_h / rgba.height, 1.0)
        shown = rgba if scale >= 1 else rgba.resize((round(rgba.width * scale), round(rgba.height * scale)), Image.Resampling.LANCZOS)
        tile = Image.new("RGBA", shown.size, (*bg, 255))
        tile.alpha_composite(shown)
        sheet.paste(tile.convert("RGB"), (x0 + (tile_w - shown.width) // 2, y0 + 6 + (max_h - shown.height) // 2))
        ink = (24, 24, 30) if sum(bg) > 300 else (232, 232, 238)
        draw.text((x0 + 8, y0 + tile_h - 34), f"{name} {rgba.width}x{rgba.height}", fill=ink, font=font)
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out, "PNG", optimize=True)


def icon_96_qa(icons: Dict[str, Image.Image], out: Path) -> None:
    tile_w, tile_h = 200, 132
    sheet = Image.new("RGB", (tile_w * len(icons), tile_h), (188, 191, 198))
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    for i, (name, rgba) in enumerate(icons.items()):
        box = rgba.getchannel("A").getbbox()
        item = rgba.crop(box) if box else rgba
        scale = min(96 / item.width, 96 / item.height)
        item = item.resize((round(item.width * scale), round(item.height * scale)), Image.Resampling.LANCZOS)
        tile = Image.new("RGBA", item.size, (188, 191, 198, 255))
        tile.alpha_composite(item)
        sheet.paste(tile.convert("RGB"), (i * tile_w + (tile_w - item.width) // 2, 2 + (100 - item.height) // 2))
        draw.text((i * tile_w + 6, 108), name, fill=(24, 24, 30), font=font)
    sheet.save(out, "PNG", optimize=True)


def main() -> None:
    shell_source = Image.open(SOURCE / "purchase_popup_shell_rgba_source_v01.png").convert("RGBA")
    controls_source = remove_border_magenta(Image.open(ROOT / "chroma" / "purchase_controls_magenta_v01.png"))
    shell_boxes = components(shell_source)
    if not shell_boxes:
        raise ValueError("Shell component missing")
    shell = trim(shell_source.crop(shell_boxes[0]))
    control_boxes = sorted(components(controls_source)[:3], key=lambda box: box[0])
    if len(control_boxes) != 3:
        raise ValueError(f"Expected 3 controls, got {len(control_boxes)}")
    controls = [trim(controls_source.crop(box), 0) for box in control_boxes]
    cancel, confirm = shared_canvas(controls[:2])
    status = trim(controls[2])
    backplates: Dict[str, Image.Image] = {
        "purchase_popup_shell_fixed_v01.png": shell,
        "purchase_button_cancel_default_v01.png": cancel,
        "purchase_button_confirm_default_v01.png": confirm,
        "purchase_status_tag_permanent_v01.png": status,
        **create_dividers(),
    }
    icon_source_root = ROOT.parent.parent / "benefits_popup" / "2026-08-16_program_composition_cutouts_v01" / "cutouts" / "icons"
    icons = {
        "purchase_icon_double_coin_base_v01.png": Image.open(icon_source_root / "benefits_icon_coin_stack_v01.png").convert("RGBA"),
        "purchase_icon_no_ad_base_v01.png": Image.open(icon_source_root / "benefits_icon_no_ad_base_v01.png").convert("RGBA"),
    }
    save_all(BACKPLATES, backplates)
    save_all(ICONS, icons)
    all_assets = {**backplates, **icons}
    contact_sheet(all_assets, (255, 255, 255), QA / "purchase_bundle_assets_white_qa_v01.png")
    contact_sheet(all_assets, (188, 191, 198), QA / "purchase_bundle_assets_gray_qa_v01.png")
    contact_sheet(all_assets, (0, 0, 0), QA / "purchase_bundle_assets_black_qa_v01.png")
    contact_sheet(all_assets, (226, 229, 235), PREVIEWS / "purchase_bundle_assets_contact_sheet_v01.png")
    icon_96_qa(icons, QA / "purchase_bundle_icons_96px_qa_v01.png")
    for name, image in all_assets.items():
        alpha = np.asarray(image.getchannel("A"))
        print(f"{name}\t{image.width}x{image.height}\talpha=({int(alpha.min())},{int(alpha.max())})\tpartial={int(((alpha > 0) & (alpha < 255)).sum())}")


if __name__ == "__main__":
    main()
