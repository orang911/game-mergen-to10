from __future__ import annotations

from collections import deque
from pathlib import Path
from typing import Dict, Iterable

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "source"
BACKPLATES = ROOT / "cutouts" / "backplates"
ICONS = ROOT / "cutouts" / "icons"
PREVIEWS = ROOT / "previews"
QA = ROOT / "qa"
PAD = 12


def checker_to_rgba(image: Image.Image) -> Image.Image:
    """Remove only border-connected neutral checker pixels.

    The generated sources have thick closed navy contours. Border-connected
    segmentation therefore preserves pale blue/white surfaces enclosed by the
    contour while removing the baked checker outside the asset.
    """
    rgb = np.asarray(image.convert("RGB"), dtype=np.uint8)
    maxc = rgb.max(axis=2)
    minc = rgb.min(axis=2)
    chroma = maxc.astype(np.int16) - minc.astype(np.int16)
    candidate = (minc >= 220) & (chroma <= 24)
    height, width = candidate.shape
    background = np.zeros_like(candidate, dtype=bool)
    queue: deque[tuple[int, int]] = deque()

    for x in range(width):
        if candidate[0, x]:
            background[0, x] = True
            queue.append((x, 0))
        if candidate[height - 1, x] and not background[height - 1, x]:
            background[height - 1, x] = True
            queue.append((x, height - 1))
    for y in range(height):
        if candidate[y, 0] and not background[y, 0]:
            background[y, 0] = True
            queue.append((0, y))
        if candidate[y, width - 1] and not background[y, width - 1]:
            background[y, width - 1] = True
            queue.append((width - 1, y))

    while queue:
        x, y = queue.popleft()
        for ny in range(max(0, y - 1), min(height, y + 2)):
            for nx in range(max(0, x - 1), min(width, x + 2)):
                if candidate[ny, nx] and not background[ny, nx]:
                    background[ny, nx] = True
                    queue.append((nx, ny))

    alpha = np.where(background, 0, 255).astype(np.uint8)
    # Contract the matte by one pixel so checker-gray antialiasing cannot
    # survive as a light halo on black. The approved navy contour is thick
    # enough that this does not alter the perceived silhouette.
    alpha_img = (
        Image.fromarray(alpha, mode="L")
        .filter(ImageFilter.MinFilter(3))
        .filter(ImageFilter.GaussianBlur(0.22))
    )
    rgba = image.convert("RGBA")
    rgba.putalpha(alpha_img)
    return rgba


def keep_largest_component(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    visible = np.asarray(rgba.getchannel("A")) > 20
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
        raise ValueError("No foreground component found")
    keep = np.zeros((height, width), dtype=np.uint8)
    xs, ys = zip(*largest)
    keep[np.asarray(ys), np.asarray(xs)] = 1
    alpha = np.asarray(rgba.getchannel("A"), dtype=np.uint8)
    rgba.putalpha(Image.fromarray(np.where(keep, alpha, 0).astype(np.uint8), mode="L"))
    return rgba


def trim(image: Image.Image, padding: int = PAD) -> Image.Image:
    rgba = keep_largest_component(image)
    alpha = np.asarray(rgba.getchannel("A"))
    ys, xs = np.where(alpha > 8)
    if not len(xs):
        raise ValueError("No alpha content")
    box = (
        max(0, int(xs.min()) - padding),
        max(0, int(ys.min()) - padding),
        min(rgba.width, int(xs.max()) + 1 + padding),
        min(rgba.height, int(ys.max()) + 1 + padding),
    )
    return rgba.crop(box)


def extract_cell(sheet: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    return trim(checker_to_rgba(sheet.crop(box)))


def shared_canvas(images: Iterable[Image.Image], padding: int = PAD) -> list[Image.Image]:
    items = [trim(image, 0) for image in images]
    width = max(image.width for image in items) + padding * 2
    height = max(image.height for image in items) + padding * 2
    output = []
    for image in items:
        canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        canvas.alpha_composite(image, ((width - image.width) // 2, (height - image.height) // 2))
        output.append(canvas)
    return output


def normalize_icon(image: Image.Image, size: int = 512, subject_max: int = 440) -> Image.Image:
    item = trim(image, 0)
    scale = min(subject_max / item.width, subject_max / item.height, 1.0)
    if scale < 1.0:
        item = item.resize((round(item.width * scale), round(item.height * scale)), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(item, ((size - item.width) // 2, (size - item.height) // 2))
    return canvas


def save_all(folder: Path, assets: Dict[str, Image.Image]) -> None:
    folder.mkdir(parents=True, exist_ok=True)
    for name, image in assets.items():
        image.save(folder / name, "PNG", optimize=True)


def make_contact_sheet(assets: Dict[str, Image.Image], bg: tuple[int, int, int], out: Path) -> None:
    tile_w, tile_h, cols = 360, 300, 4
    rows = (len(assets) + cols - 1) // cols
    sheet = Image.new("RGB", (tile_w * cols, tile_h * rows), bg)
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    for index, (name, rgba) in enumerate(assets.items()):
        col, row = index % cols, index // cols
        x0, y0 = col * tile_w, row * tile_h
        max_w, max_h = tile_w - 32, tile_h - 58
        scale = min(max_w / rgba.width, max_h / rgba.height, 1.0)
        display = rgba if scale >= 1 else rgba.resize(
            (round(rgba.width * scale), round(rgba.height * scale)), Image.Resampling.LANCZOS
        )
        tile = Image.new("RGBA", display.size, (*bg, 255))
        tile.alpha_composite(display)
        sheet.paste(tile.convert("RGB"), (
            x0 + (tile_w - display.width) // 2,
            y0 + 8 + (max_h - display.height) // 2,
        ))
        draw.text((x0 + 8, y0 + tile_h - 34), f"{name} {rgba.width}x{rgba.height}", fill=(26, 26, 32), font=font)
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out, "PNG", optimize=True)


def make_icon_96_qa(icons: Dict[str, Image.Image], out: Path) -> None:
    tile_w, tile_h = 150, 132
    sheet = Image.new("RGB", (tile_w * len(icons), tile_h), (188, 191, 198))
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    for i, (name, rgba) in enumerate(icons.items()):
        bbox = rgba.getchannel("A").getbbox()
        item = rgba.crop(bbox) if bbox else rgba
        scale = min(96 / item.width, 96 / item.height)
        item = item.resize((round(item.width * scale), round(item.height * scale)), Image.Resampling.LANCZOS)
        tile = Image.new("RGBA", item.size, (188, 191, 198, 255))
        tile.alpha_composite(item)
        sheet.paste(tile.convert("RGB"), (i * tile_w + (tile_w - item.width) // 2, 2 + (100 - item.height) // 2))
        draw.text((i * tile_w + 5, 108), name.replace("daily_icon_", ""), fill=(24, 24, 30), font=font)
    sheet.save(out, "PNG", optimize=True)


def main() -> None:
    task_shell_source = Image.open(SOURCE / "task_shell_checker_source_v01.png")
    signin_shell_source = Image.open(SOURCE / "signin_shell_checker_source_v01.png")
    controls_source = Image.open(SOURCE / "controls_checker_source_v01.png")
    icons_source = Image.open(SOURCE / "icons_checker_source_v01.png")
    cards_source = Image.open(SOURCE / "signin_cards_checker_source_v01.png")

    backplates: Dict[str, Image.Image] = {
        "daily_task_panel_shell_fixed_v01.png": trim(checker_to_rgba(task_shell_source)),
        "daily_signin_panel_shell_fixed_v01.png": trim(checker_to_rgba(signin_shell_source)),
    }

    controls = [
        extract_cell(controls_source, (col * 418, row * 418, (col + 1) * 418, (row + 1) * 418))
        for row in range(3) for col in range(3)
    ]
    title_tab = controls[0]
    row_default, row_selected = shared_canvas(controls[1:3])
    button_disabled, button_claimed, button_claim = shared_canvas(controls[3:6])
    progress_track, progress_fill = shared_canvas(controls[6:8])
    icon_slot = controls[8]
    backplates.update({
        "daily_title_tab_v01.png": title_tab,
        "daily_task_row_default_v01.png": row_default,
        "daily_task_row_selected_v01.png": row_selected,
        "daily_button_disabled_v01.png": button_disabled,
        "daily_button_claimed_v01.png": button_claimed,
        "daily_button_claim_v01.png": button_claim,
        "daily_progress_track_v01.png": progress_track,
        "daily_progress_fill_v01.png": progress_fill,
        "daily_icon_slot_v01.png": icon_slot,
    })

    cards = [extract_cell(cards_source, (i * 627, 0, (i + 1) * 627, 836)) for i in range(3)]
    card_default, card_selected, card_premium = shared_canvas(cards)
    backplates.update({
        "daily_signin_card_default_v01.png": card_default,
        "daily_signin_card_selected_v01.png": card_selected,
        "daily_signin_card_premium_v01.png": card_premium,
    })

    icon_names = [
        "daily_icon_activity_star_v01.png",
        "daily_icon_challenge_v01.png",
        "daily_icon_merge_v01.png",
        "daily_icon_monster_v01.png",
        "daily_icon_login_v01.png",
        "daily_icon_gem_v01.png",
        "daily_icon_coin_v01.png",
        "daily_icon_chest_v01.png",
        "daily_icon_claimed_check_v01.png",
    ]
    icon_cells = [
        extract_cell(icons_source, (col * 418, row * 418, (col + 1) * 418, (row + 1) * 418))
        for row in range(3) for col in range(3)
    ]
    icons = {name: normalize_icon(image) for name, image in zip(icon_names, icon_cells)}

    save_all(BACKPLATES, backplates)
    save_all(ICONS, icons)
    all_assets = {**backplates, **icons}
    make_contact_sheet(all_assets, (255, 255, 255), QA / "daily_program_assets_white_qa_v01.png")
    make_contact_sheet(all_assets, (188, 191, 198), QA / "daily_program_assets_gray_qa_v01.png")
    make_contact_sheet(all_assets, (0, 0, 0), QA / "daily_program_assets_black_qa_v01.png")
    make_contact_sheet(all_assets, (226, 229, 235), PREVIEWS / "daily_program_assets_contact_sheet_v01.png")
    make_icon_96_qa(icons, QA / "daily_program_icons_96px_qa_v01.png")

    for name, image in all_assets.items():
        alpha = np.asarray(image.getchannel("A"))
        print(
            f"{name}\t{image.width}x{image.height}"
            f"\talpha=({int(alpha.min())},{int(alpha.max())})"
            f"\tpartial={int(((alpha > 0) & (alpha < 255)).sum())}"
        )


if __name__ == "__main__":
    main()
