from __future__ import annotations

from pathlib import Path
from typing import Dict, Iterable, Tuple
from collections import deque

import numpy as np
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "source"
CUTOUTS = ROOT / "cutouts"
PREVIEWS = ROOT / "previews"
QA = ROOT / "qa"

PAD = 12


def trim_alpha(image: Image.Image, padding: int = PAD) -> Image.Image:
    rgba = image.convert("RGBA")
    alpha = np.asarray(rgba.getchannel("A"))
    ys, xs = np.where(alpha > 8)
    if len(xs) == 0:
        raise ValueError("No visible alpha pixels found")
    left = max(0, int(xs.min()) - padding)
    top = max(0, int(ys.min()) - padding)
    right = min(rgba.width, int(xs.max()) + 1 + padding)
    bottom = min(rgba.height, int(ys.max()) + 1 + padding)
    return rgba.crop((left, top, right, bottom))


def crop_trim(source: Image.Image, box: Tuple[int, int, int, int]) -> Image.Image:
    return trim_alpha(keep_largest_component(source.crop(box)))


def keep_largest_component(image: Image.Image) -> Image.Image:
    """Remove faint grid seams and isolated chroma-removal specks."""
    rgba = image.convert("RGBA")
    visible = np.asarray(rgba.getchannel("A")) > 8
    height, width = visible.shape
    visited = np.zeros_like(visible, dtype=bool)
    largest: list[tuple[int, int]] = []
    for y in range(height):
        for x in range(width):
            if not visible[y, x] or visited[y, x]:
                continue
            queue = deque([(x, y)])
            visited[y, x] = True
            component: list[tuple[int, int]] = []
            while queue:
                px, py = queue.popleft()
                component.append((px, py))
                for ny in range(max(0, py - 1), min(height, py + 2)):
                    for nx in range(max(0, px - 1), min(width, px + 2)):
                        if visible[ny, nx] and not visited[ny, nx]:
                            visited[ny, nx] = True
                            queue.append((nx, ny))
            if len(component) > len(largest):
                largest = component
    if not largest:
        raise ValueError("No connected alpha component found")
    keep = np.zeros((height, width), dtype=np.uint8)
    xs, ys = zip(*largest)
    keep[np.asarray(ys), np.asarray(xs)] = 1
    alpha = np.asarray(rgba.getchannel("A"), dtype=np.uint8)
    cleaned_alpha = np.where(keep, alpha, 0).astype(np.uint8)
    rgba.putalpha(Image.fromarray(cleaned_alpha, mode="L"))
    return rgba


def fit_shared_canvas(images: Iterable[Image.Image], padding: int = PAD) -> list[Image.Image]:
    items = [trim_alpha(image, 0) for image in images]
    width = max(image.width for image in items) + padding * 2
    height = max(image.height for image in items) + padding * 2
    result = []
    for image in items:
        canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        x = (width - image.width) // 2
        y = (height - image.height) // 2
        canvas.alpha_composite(image, (x, y))
        result.append(canvas)
    return result


def save(name: str, image: Image.Image) -> None:
    CUTOUTS.mkdir(parents=True, exist_ok=True)
    image.save(CUTOUTS / name, "PNG", optimize=True)


def make_contact_sheet(assets: Dict[str, Image.Image], background: Tuple[int, int, int], out: Path) -> None:
    tile_w, tile_h = 420, 330
    cols = 3
    rows = (len(assets) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * tile_w, rows * tile_h), background)
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    for index, (name, rgba) in enumerate(assets.items()):
        col, row = index % cols, index // cols
        x0, y0 = col * tile_w, row * tile_h
        max_w, max_h = tile_w - 36, tile_h - 64
        scale = min(max_w / rgba.width, max_h / rgba.height, 1.0)
        display = rgba
        if scale < 1.0:
            display = rgba.resize((round(rgba.width * scale), round(rgba.height * scale)), Image.Resampling.LANCZOS)
        tile = Image.new("RGBA", display.size, (*background, 255))
        tile.alpha_composite(display)
        px = x0 + (tile_w - display.width) // 2
        py = y0 + 14 + (max_h - display.height) // 2
        sheet.paste(tile.convert("RGB"), (px, py))
        draw.text((x0 + 12, y0 + tile_h - 34), f"{name}  {rgba.width}x{rgba.height}", fill=(24, 24, 30), font=font)
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out, "PNG", optimize=True)


def alpha_stats(image: Image.Image) -> dict:
    alpha = np.asarray(image.getchannel("A"))
    return {
        "min": int(alpha.min()),
        "max": int(alpha.max()),
        "transparent": int((alpha == 0).sum()),
        "partial": int(((alpha > 0) & (alpha < 255)).sum()),
        "opaque": int((alpha == 255).sum()),
    }


def make_96px_icon_qa(assets: Dict[str, Image.Image], out: Path) -> None:
    names = [
        "signin_close_icon_v01.png",
        "signin_reward_gem_v01.png",
        "signin_reward_coin_v01.png",
        "signin_reward_chest_v01.png",
        "signin_claimed_check_v01.png",
    ]
    tile_w, tile_h = 160, 138
    sheet = Image.new("RGB", (tile_w * len(names), tile_h), (188, 191, 198))
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    for index, name in enumerate(names):
        icon = assets[name]
        scale = min(96 / icon.width, 96 / icon.height)
        resized = icon.resize((round(icon.width * scale), round(icon.height * scale)), Image.Resampling.LANCZOS)
        tile = Image.new("RGBA", resized.size, (188, 191, 198, 255))
        tile.alpha_composite(resized)
        x = index * tile_w + (tile_w - resized.width) // 2
        y = 4 + (100 - resized.height) // 2
        sheet.paste(tile.convert("RGB"), (x, y))
        draw.text((index * tile_w + 6, 112), name.replace("signin_", ""), fill=(24, 24, 30), font=font)
    sheet.save(out, "PNG", optimize=True)


def main() -> None:
    panel_source = Image.open(SOURCE / "signin_panel_shell_rgba_source_v01.png").convert("RGBA")
    structure = Image.open(SOURCE / "signin_structure_sheet_rgba_source_v01.png").convert("RGBA")
    components = Image.open(SOURCE / "signin_components_sheet_rgba_source_v01.png").convert("RGBA")

    panel = trim_alpha(panel_source)

    tab_inactive = crop_trim(structure, (768, 0, 1536, 420))
    tab_selected = crop_trim(structure, (0, 420, 768, 750))
    tab_inactive, tab_selected = fit_shared_canvas([tab_inactive, tab_selected])

    close_bg = crop_trim(structure, (768, 420, 1536, 750))
    close_icon = crop_trim(structure, (0, 730, 768, 1024))
    claim_button = crop_trim(structure, (768, 730, 1536, 1024))

    card_default = crop_trim(components, (0, 0, 418, 540))
    card_selected = crop_trim(components, (418, 0, 836, 540))
    card_premium = crop_trim(components, (836, 0, 1254, 540))
    card_default, card_selected, card_premium = fit_shared_canvas(
        [card_default, card_selected, card_premium]
    )

    gem = crop_trim(components, (0, 520, 418, 900))
    coin = crop_trim(components, (418, 520, 836, 900))
    chest = crop_trim(components, (836, 520, 1254, 900))
    check = crop_trim(components, (0, 880, 418, 1254))
    selected_rim = crop_trim(components, (836, 880, 1254, 1254))

    assets = {
        "signin_panel_shell_fixed_v01.png": panel,
        "signin_tab_inactive_v01.png": tab_inactive,
        "signin_tab_selected_v01.png": tab_selected,
        "signin_close_button_bg_v01.png": close_bg,
        "signin_close_icon_v01.png": close_icon,
        "signin_claim_button_default_v01.png": claim_button,
        "signin_card_default_v01.png": card_default,
        "signin_card_selected_v01.png": card_selected,
        "signin_card_premium_v01.png": card_premium,
        "signin_reward_gem_v01.png": gem,
        "signin_reward_coin_v01.png": coin,
        "signin_reward_chest_v01.png": chest,
        "signin_claimed_check_v01.png": check,
        "signin_selected_rim_v01.png": selected_rim,
    }

    for name, image in assets.items():
        save(name, image)

    PREVIEWS.mkdir(parents=True, exist_ok=True)
    QA.mkdir(parents=True, exist_ok=True)
    make_contact_sheet(assets, (236, 238, 242), PREVIEWS / "signin_cutouts_contact_sheet_v01.png")
    make_contact_sheet(assets, (255, 255, 255), QA / "signin_cutouts_white_qa_v01.png")
    make_contact_sheet(assets, (185, 188, 194), QA / "signin_cutouts_gray_qa_v01.png")
    make_contact_sheet(assets, (0, 0, 0), QA / "signin_cutouts_black_qa_v01.png")
    make_96px_icon_qa(assets, QA / "signin_icons_96px_qa_v01.png")

    for name, image in assets.items():
        stats = alpha_stats(image)
        print(f"{name}\t{image.width}x{image.height}\talpha={stats}")


if __name__ == "__main__":
    main()
