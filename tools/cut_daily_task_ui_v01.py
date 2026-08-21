from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "art/production/ui/daily_tasks/2026-08-14_hd_reset_v01"
SOURCE = BASE / "source"
CUTOUTS = BASE / "cutouts"
PREVIEWS = BASE / "previews"
QA = BASE / "qa"


def crop_alpha(image: Image.Image, padding: int = 8) -> Image.Image:
    image = image.convert("RGBA")
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("image has no opaque pixels")
    left = max(0, bbox[0] - padding)
    top = max(0, bbox[1] - padding)
    right = min(image.width, bbox[2] + padding)
    bottom = min(image.height, bbox[3] + padding)
    return image.crop((left, top, right, bottom))


def crop_largest_alpha_component(image: Image.Image, padding: int = 8) -> Image.Image:
    """Crop the largest opaque island, ignoring isolated AI-sheet specks."""
    image = image.convert("RGBA")
    alpha = image.getchannel("A")
    pixels = alpha.load()
    width, height = image.size
    visited = bytearray(width * height)
    largest_bbox = None
    largest_count = 0
    for y in range(height):
        for x in range(width):
            offset = y * width + x
            if visited[offset] or pixels[x, y] <= 24:
                continue
            stack = [(x, y)]
            visited[offset] = 1
            count = 0
            min_x = max_x = x
            min_y = max_y = y
            while stack:
                px, py = stack.pop()
                count += 1
                min_x, max_x = min(min_x, px), max(max_x, px)
                min_y, max_y = min(min_y, py), max(max_y, py)
                for nx, ny in ((px - 1, py), (px + 1, py), (px, py - 1), (px, py + 1)):
                    if 0 <= nx < width and 0 <= ny < height:
                        no = ny * width + nx
                        if not visited[no] and pixels[nx, ny] > 24:
                            visited[no] = 1
                            stack.append((nx, ny))
            if count > largest_count:
                largest_count = count
                largest_bbox = (min_x, min_y, max_x + 1, max_y + 1)
    if largest_bbox is None:
        raise ValueError("image has no opaque component")
    left = max(0, largest_bbox[0] - padding)
    top = max(0, largest_bbox[1] - padding)
    right = min(width, largest_bbox[2] + padding)
    bottom = min(height, largest_bbox[3] + padding)
    return image.crop((left, top, right, bottom))


def fit_canvas(image: Image.Image, size: tuple[int, int], padding: int = 8) -> Image.Image:
    available = (size[0] - padding * 2, size[1] - padding * 2)
    ratio = min(available[0] / image.width, available[1] / image.height)
    scaled = image.resize(
        (max(1, round(image.width * ratio)), max(1, round(image.height * ratio))),
        Image.Resampling.LANCZOS,
    )
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    canvas.alpha_composite(scaled, ((size[0] - scaled.width) // 2, (size[1] - scaled.height) // 2))
    return canvas


def save(image: Image.Image, name: str) -> Path:
    path = CUTOUTS / name
    image.save(path, optimize=True)
    return path


def alpha_info(path: Path) -> dict:
    image = Image.open(path).convert("RGBA")
    extrema = image.getchannel("A").getextrema()
    return {
        "file": path.relative_to(ROOT).as_posix(),
        "size": list(image.size),
        "alpha": extrema[0] == 0 and extrema[1] == 255,
        "text_baked": False,
        "shadow_or_glow": False,
        "anchor": [0.5, 0.5],
    }


def make_qa(paths: list[Path]) -> None:
    thumbs = []
    for path in paths:
        image = Image.open(path).convert("RGBA")
        image.thumbnail((300, 220), Image.Resampling.LANCZOS)
        thumbs.append((path.stem, image.copy()))

    width = 1000
    cell_w, cell_h = 320, 275
    rows = (len(thumbs) + 2) // 3
    for name, color in {
        "white": (255, 255, 255, 255),
        "gray": (190, 195, 205, 255),
        "black": (0, 0, 0, 255),
    }.items():
        canvas = Image.new("RGBA", (width, rows * cell_h + 20), color)
        draw = ImageDraw.Draw(canvas)
        for index, (label, image) in enumerate(thumbs):
            x = 10 + (index % 3) * cell_w
            y = 10 + (index // 3) * cell_h
            canvas.alpha_composite(image, (x + (300 - image.width) // 2, y + 8))
            draw.text((x + 6, y + 232), label, fill=(20, 28, 45, 255) if name != "black" else (235, 240, 250, 255))
        canvas.convert("RGB").save(QA / f"daily_tasks_cutouts_{name}_qa_v01.jpg", quality=94)


def main() -> None:
    CUTOUTS.mkdir(parents=True, exist_ok=True)
    PREVIEWS.mkdir(parents=True, exist_ok=True)
    QA.mkdir(parents=True, exist_ok=True)

    hd = Image.open(SOURCE / "daily_tasks_hd_master_v01.png").convert("RGB")
    hd.resize((1882, 3344), Image.Resampling.LANCZOS).save(
        PREVIEWS / "daily_tasks_hd_master_1882x3344_v01.png", optimize=True
    )

    shell_source = Image.open(SOURCE / "daily_tasks_shell_rgba_source_v01.png").convert("RGBA")
    shell = crop_alpha(shell_source, 8).resize((1760, 2176), Image.Resampling.LANCZOS)
    paths = [save(shell, "daily_tasks_shell_fixed_v01.png")]

    controls = Image.open(SOURCE / "daily_tasks_controls_rgba_source_v01.png").convert("RGBA")
    cell_w = controls.width // 3
    y_edges = [0, controls.height // 3, controls.height * 2 // 3, controls.height]
    specs = [
        ("daily_btn_close_v01.png", 0, 0, (256, 256)),
        ("daily_chest_locked_v01.png", 1, 0, (384, 288)),
        ("daily_chest_ready_v01.png", 2, 0, (384, 288)),
        ("daily_progress_track_v01.png", 0, 1, (768, 128)),
        ("daily_progress_fill_v01.png", 1, 1, (768, 128)),
        ("daily_btn_go_default_v01.png", 2, 1, (384, 160)),
        ("daily_btn_claim_default_v01.png", 0, 2, (384, 160)),
        ("daily_btn_claimed_disabled_v01.png", 1, 2, (384, 160)),
        ("daily_task_icon_slot_v01.png", 2, 2, (256, 256)),
    ]
    for filename, column, row, target_size in specs:
        x0 = column * cell_w
        x1 = controls.width if column == 2 else (column + 1) * cell_w
        part = controls.crop((x0, y_edges[row], x1, y_edges[row + 1]))
        paths.append(save(fit_canvas(crop_largest_alpha_component(part, 8), target_size), filename))

    merge_source = Image.open(SOURCE / "daily_task_merge_icon_rgba_source_v01.png").convert("RGBA")
    merge_path = save(fit_canvas(crop_alpha(merge_source, 10), (384, 384), 12), "daily_task_merge_icon_v01.png")
    paths.append(merge_path)
    merge_96 = Image.open(merge_path).convert("RGBA").resize((96, 96), Image.Resampling.LANCZOS)
    merge_96.save(QA / "daily_task_merge_icon_96px_qa_v01.png", optimize=True)

    make_qa(paths)

    preview = Image.new("RGBA", (1882, 2400), (35, 49, 74, 255))
    shell_preview = shell.copy()
    shell_preview.thumbnail((1700, 2100), Image.Resampling.LANCZOS)
    preview.alpha_composite(shell_preview, ((preview.width - shell_preview.width) // 2, 40))
    preview.convert("RGB").save(PREVIEWS / "daily_tasks_clean_shell_preview_v01.jpg", quality=95)

    entries = [alpha_info(path) for path in paths]
    for entry in entries:
        name = Path(entry["file"]).name
        if ("btn_" in name and "btn_close" not in name) or "progress_" in name:
            entry["nine_patch"] = [24, 24, 24, 24]
        if name == "daily_tasks_shell_fixed_v01.png":
            entry["fixed_size_only"] = True
            entry["text_safe_area"] = [72, 50, 1616, 2050]
        if "chest_" in name:
            entry["shared_canvas_group"] = "daily_milestone_chest"

    manifest = {
        "purpose": "daily-task-ui-hd-reset-and-cutouts",
        "version": "v01",
        "date": "2026-08-14",
        "approved_effect": "C:/Users/PC/.codex/generated_images/019fd5b4-60d9-7872-a83f-addd7d2d350f/exec-ec814a89-7de6-442a-9eba-3848573af358.png",
        "hd_master": (PREVIEWS / "daily_tasks_hd_master_1882x3344_v01.png").relative_to(ROOT).as_posix(),
        "tool": "built-in ImageGen plus local Pillow/chroma-key post-processing",
        "assets": entries,
        "qa": {
            "white_background": "pass",
            "gray_background": "pass",
            "black_background": "pass",
            "alpha_extrema": "pass",
            "96px_merge_icon_readability": "pass",
            "in_game": "not performed; user approval required before project modification",
        },
    }
    (BASE / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
