#!/usr/bin/env python3
"""Build the secondary_complete_v03 art delivery from approved ImageGen masters.

The script keeps the untouched chroma masters in art/production, derives 4K
transparent masters, crops one 2x runtime shell per page, copies the existing
non-shell v02 runtime pieces as the rollback-safe dynamic layer, and emits QA.
"""

from __future__ import annotations

import json
import shutil
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageChops, ImageDraw, ImageFont


REPO = Path(__file__).resolve().parents[1]
PRODUCTION = REPO / "art/production/ui/chapter01/2026-08-13_centered_interfaces_complete_v03"
RUNTIME = REPO / "assets/runtime/ui/secondary_complete_v03"
V02 = REPO / "assets/runtime/ui/secondary_complete_v02"

GENERATED = Path(r"C:\Users\PC\.codex\generated_images\019fd56b-3f19-7652-ac2a-f9680a706a58")

PAGES = {
    "pause": {
        "source": "exec-39b64e11-f68a-4789-b36d-e35eaf9385db.png",
        "logical": (660, 485), "frame": "ui_battle_pause_shell_v03.png",
    },
    "exit_confirm": {
        "source": "exec-950075ce-fcbc-4c12-9e2e-a0bd65a5315e.png",
        "logical": (660, 388), "frame": "ui_exit_confirm_shell_v03.png",
    },
    "settings": {
        "source": "exec-9a21f0b9-179a-4d30-b0cd-79c31a1a3495.png",
        "logical": (650, 910), "frame": "ui_settings_shell_v03.png",
    },
    "clear_confirm": {
        "source": "exec-9ee69fbe-021a-4375-ad14-514c22f72a07.png",
        "logical": (660, 383), "frame": "ui_clear_data_confirm_shell_v03.png",
    },
    "daily_tasks": {
        "source": "exec-3fe76f66-5436-428a-bb4c-d5468bd4e306.png",
        "logical": (880, 1141), "frame": "ui_daily_tasks_shell_v03.png",
    },
    "daily_signin": {
        "source": "exec-9a348e09-63e5-4bec-a2b9-c2e16c90f583.png",
        "logical": (880, 436), "frame": "ui_daily_signin_shell_v03.png",
    },
    "benefits": {
        "source": "exec-946eeab4-e623-497c-86c3-5dd6fcd6ea18.png",
        "logical": (760, 775), "frame": "ui_benefits_shell_v03.png",
    },
    "first_purchase": {
        "source": "exec-b4d2a8dd-108a-411b-9098-21aefc3babd8.png",
        "logical": (760, 748), "frame": "ui_first_purchase_gift_shell_v03.png",
    },
    "piggy": {
        "source": "exec-7a17d556-c409-4816-8978-e8d49cae4662.png",
        "logical": (760, 842), "frame": "ui_piggy_bank_shell_v03.png",
    },
    "shop": {
        "source": "exec-b65512dd-5c83-40fc-9f30-262d259ea791.png",
        "logical": (850, 901), "frame": "ui_shop_shell_v03.png",
    },
}


def remove_magenta(src: Image.Image) -> Image.Image:
    rgba = src.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = pixels[x, y]
            # The model varies the key slightly. Magenta dominance isolates it
            # without punching holes into the blue/pale UI itself.
            dominance = min(r, b) - g
            if r >= 180 and b >= 150 and dominance >= 65:
                alpha = 0 if dominance >= 125 else max(0, min(255, 255 - (dominance - 65) * 4))
                if alpha == 0:
                    pixels[x, y] = (0, 0, 0, 0)
                else:
                    edge = max(r, b, g)
                    pixels[x, y] = (min(r, edge // 2), min(g, edge // 2), min(b, edge // 2), alpha)
    return rgba


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        raise RuntimeError("transparent master has no visible pixels")
    # Keep the generated shadow and a small safety gutter.
    x0, y0, x1, y1 = bbox
    pad = 8
    return max(0, x0 - pad), max(0, y0 - pad), min(image.width, x1 + pad), min(image.height, y1 + pad)


def contain(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    scale = min(size[0] / image.width, size[1] / image.height)
    resized = image.resize((max(1, round(image.width * scale)), max(1, round(image.height * scale))), Image.Resampling.LANCZOS)
    out.alpha_composite(resized, ((size[0] - resized.width) // 2, (size[1] - resized.height) // 2))
    return out


def make_contact_sheet(rendered: list[tuple[str, Image.Image]]) -> Image.Image:
    cell_w, cell_h = 470, 836
    sheet = Image.new("RGB", (cell_w * 5, cell_h * 2), "#17273c")
    draw = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("arial.ttf", 30)
    except OSError:
        font = ImageFont.load_default()
    for index, (name, image) in enumerate(rendered):
        thumb = contain(image, (430, 740))
        x = (index % 5) * cell_w + 20
        y = (index // 5) * cell_h + 56
        checker = Image.new("RGB", thumb.size, "#dce2ec")
        check_draw = ImageDraw.Draw(checker)
        for cy in range(0, thumb.height, 24):
            for cx in range(0, thumb.width, 24):
                if (cx // 24 + cy // 24) % 2:
                    check_draw.rectangle((cx, cy, cx + 23, cy + 23), fill="#f5f7fb")
        checker.paste(thumb, (0, 0), thumb)
        sheet.paste(checker, (x, y))
        draw.text((x, (index // 5) * cell_h + 14), name, font=font, fill="white")
    return sheet


def make_runtime_screenshot(shell: Image.Image, logical: tuple[int, int]) -> Image.Image:
    canvas = Image.new("RGBA", (941, 1672), (3, 10, 22, 174))
    art = shell.resize(logical, Image.Resampling.LANCZOS)
    canvas.alpha_composite(art, ((941 - logical[0]) // 2, (1672 - logical[1]) // 2))
    return canvas


def pngs(root: Path) -> Iterable[Path]:
    return root.rglob("*.png") if root.exists() else []


def main() -> None:
    masters_chroma = PRODUCTION / "masters_chroma_2160x3840"
    masters_alpha = PRODUCTION / "masters_alpha_2160x3840"
    frames = RUNTIME / "frames"
    qa = PRODUCTION / "qa"
    if RUNTIME.exists():
        shutil.rmtree(RUNTIME)
    for path in (masters_chroma, masters_alpha, frames, qa):
        path.mkdir(parents=True, exist_ok=True)

    # Preserve v02's dynamic element names as a compatibility layer; v03
    # replaces the visible page shells and keeps all business code untouched.
    elements_out = RUNTIME / "elements"
    if elements_out.exists():
        shutil.rmtree(elements_out)
    shutil.copytree(V02 / "elements", elements_out, ignore=shutil.ignore_patterns("*.import"))

    rendered: list[tuple[str, Image.Image]] = []
    runtime_screenshots = qa / "runtime_941x1672"
    runtime_screenshots.mkdir(parents=True, exist_ok=True)
    manifest_pages: list[dict] = []
    for page, spec in PAGES.items():
        source_path = GENERATED / str(spec["source"])
        if not source_path.exists():
            raise FileNotFoundError(source_path)
        source = Image.open(source_path).convert("RGBA")
        chroma_master = source.resize((2160, 3840), Image.Resampling.LANCZOS)
        chroma_path = masters_chroma / f"{page}_master_v03.png"
        chroma_master.save(chroma_path, optimize=True)

        alpha = remove_magenta(chroma_master)
        # Remove the very soft magenta ground shadow the generator sometimes
        # adds despite the flat-key prompt. Keeping it would create a colored
        # fringe over the battle dimmer on device.
        alpha_pixels = alpha.load()
        for y in range(alpha.height):
            for x in range(alpha.width):
                r, g, b, a = alpha_pixels[x, y]
                if a < 150:
                    alpha_pixels[x, y] = (0, 0, 0, 0)
                elif a < 255:
                    alpha_pixels[x, y] = (r, g, b, 255)
        alpha_path = masters_alpha / f"{page}_master_v03.png"
        alpha.save(alpha_path, optimize=True)

        crop = alpha.crop(alpha_bbox(alpha))
        logical = tuple(spec["logical"])
        runtime_size = (logical[0] * 2, logical[1] * 2)
        # The approved controller dimensions are authoritative. The model
        # leaves slightly different outer gutters page-to-page, so normalize
        # each isolated popup to the exact 2x runtime rectangle here.
        shell = crop.resize(runtime_size, Image.Resampling.LANCZOS)
        frame_path = frames / str(spec["frame"])
        runtime_frames: list[str] = []
        if page == "daily_tasks":
            # 880 x 1141 at 2x is taller than the mobile-safe 2048 limit.
            # Split at stable empty/row boundaries; the controller stitches
            # the three pieces at the original pixel positions.
            cuts = (("top", 0, 760), ("middle", 760, 1520), ("bottom", 1520, shell.height))
            for suffix, y0, y1 in cuts:
                split_path = frames / f"ui_daily_tasks_shell_v03_{suffix}.png"
                shell.crop((0, y0, shell.width, y1)).save(split_path, optimize=True)
                runtime_frames.append(str(split_path.relative_to(REPO)).replace("\\", "/"))
        else:
            shell.save(frame_path, optimize=True)
            runtime_frames.append(str(frame_path.relative_to(REPO)).replace("\\", "/"))
        rendered.append((page, shell))
        make_runtime_screenshot(shell, logical).save(runtime_screenshots / f"{page}.png", optimize=True)
        manifest_pages.append({
            "page": page,
            "source": str(chroma_path.relative_to(REPO)).replace("\\", "/"),
            "master_chroma": str(chroma_path.relative_to(REPO)).replace("\\", "/"),
            "master_alpha": str(alpha_path.relative_to(REPO)).replace("\\", "/"),
            "runtime_frames": runtime_frames,
            "logical_size": list(logical),
            "runtime_size": list(runtime_size),
            "text_baked": False,
        })

    contact = make_contact_sheet(rendered)
    contact.save(qa / "secondary_v03_contact_sheet.png", optimize=True)

    checks = []
    for path in pngs(RUNTIME):
        with Image.open(path) as image:
            rgba = image.convert("RGBA")
            alpha = rgba.getchannel("A")
            checks.append({
                "file": str(path.relative_to(REPO)).replace("\\", "/"),
                "size": list(image.size),
                "within_2048": image.width <= 2048 and image.height <= 2048,
                "has_alpha": image.mode in {"RGBA", "LA", "PA"} or "transparency" in image.info,
                "nontransparent_bbox": list(alpha.getbbox() or ()),
                "valid_nontransparent": alpha.getbbox() is not None,
            })
    failures = [item for item in checks if not item["within_2048"] or not item["valid_nontransparent"]]
    if failures:
        raise RuntimeError(f"v03 runtime PNG audit failed: {failures}")

    manifest = {
        "purpose": "secondary-ui-complete-v03",
        "version": "v03",
        "date": "2026-08-13",
        "visual_truth": [
            "art/ai_generated/imagegen/2026-08-13/131530_chapter01_ui_batch2_concepts/pause_and_settings_concept_v01.png",
            "art/ai_generated/imagegen/2026-08-13/131530_chapter01_ui_batch2_concepts/daily_tasks_and_signin_concept_v01.png",
            "art/ai_generated/imagegen/2026-08-13/131530_chapter01_ui_batch2_concepts/lobby_growth_and_commercial_concept_v01.png",
        ],
        "pages": manifest_pages,
        "runtime_root": "assets/runtime/ui/secondary_complete_v03",
        "max_runtime_texture": 2048,
        "all_dynamic_text_programmatic": True,
        "v02_preserved": True,
        "runtime_png_count": len(checks),
        "runtime_audit_pass": True,
    }
    (PRODUCTION / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    (qa / "runtime_png_audit.json").write_text(json.dumps(checks, ensure_ascii=False, indent=2), encoding="utf-8")
    (PRODUCTION / "README.md").write_text(
        "# Secondary UI complete v03\n\n"
        "Ten no-text 4K masters generated from the approved 941×1672 visual references. "
        "Runtime frames are 2× logical size and all dynamic copy remains in Godot. "
        "v02 remains untouched for rollback.\n",
        encoding="utf-8",
    )
    print(json.dumps({"pages": len(manifest_pages), "runtime_pngs": len(checks), "contact_sheet": str(qa / "secondary_v03_contact_sheet.png")}, ensure_ascii=False))


if __name__ == "__main__":
    main()
