from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(r"F:\卖肉\godotT10\game_mergenTo10_published")
SRC = ROOT / "art" / "ai_generated" / "imagegen" / "2026-08-13" / "131530_chapter01_ui_batch2_concepts"
OUT = ROOT / "art" / "production" / "ui" / "chapter01" / "2026-08-13_centered_interfaces_v01"
CUT = OUT / "reference_composites"
QA = OUT / "qa"


def rr(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], radius: int, fill: int = 255) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill)


def crop_with_mask(source: Image.Image, box: tuple[int, int, int, int], shapes: list[tuple[str, tuple[int, int, int, int], int]], name: str) -> dict:
    img = source.crop(box).convert("RGBA")
    mask = Image.new("L", img.size, 0)
    d = ImageDraw.Draw(mask)
    for kind, shape_box, radius in shapes:
        if kind == "rr":
            rr(d, shape_box, radius)
        elif kind == "poly":
            d.polygon(shape_box, fill=255)
        else:
            raise ValueError(kind)
    img.putalpha(mask)
    path = CUT / f"ui_{name}_reference.png"
    img.save(path)
    return {
        "id": name,
        "file": path.relative_to(ROOT).as_posix(),
        "size": list(img.size),
        "aspect_ratio": round(img.width / img.height, 4),
        "pivot": [0.5, 0.5],
        "opening_anchor": "screen_center",
        "source_box": list(box),
        "classification": "effect-image reference composite",
        "runtime_ready": False,
        "note": "Locks the approved effect-image geometry. Contains baked labels/content and is not a runtime shell.",
    }


def checker(size: tuple[int, int], cell: int = 24) -> Image.Image:
    out = Image.new("RGB", size, "white")
    d = ImageDraw.Draw(out)
    for y in range(0, size[1], cell):
        for x in range(0, size[0], cell):
            c = (218, 222, 230) if ((x // cell) + (y // cell)) % 2 else (246, 248, 252)
            d.rectangle((x, y, min(x + cell, size[0]), min(y + cell, size[1])), fill=c)
    return out


def contact_sheet(records: list[dict]) -> None:
    thumbs = []
    for rec in records:
        im = Image.open(ROOT / rec["file"]).convert("RGBA")
        im.thumbnail((440, 440), Image.Resampling.LANCZOS)
        cell = checker((480, 510))
        x = (480 - im.width) // 2
        y = 20 + (440 - im.height) // 2
        cell.paste(im, (x, y), im)
        ImageDraw.Draw(cell).text((18, 475), f'{rec["id"]}  {rec["size"][0]}x{rec["size"][1]}  {rec["aspect_ratio"]}', fill=(18, 32, 60))
        thumbs.append(cell)
    sheet = Image.new("RGB", (960, 510 * 5), (235, 239, 246))
    for i, im in enumerate(thumbs):
        sheet.paste(im, ((i % 2) * 480, (i // 2) * 510))
    sheet.save(QA / "centered_interfaces_reference_contact_sheet.png")


def main() -> None:
    CUT.mkdir(parents=True, exist_ok=True)
    QA.mkdir(parents=True, exist_ok=True)
    pause = Image.open(SRC / "pause_and_settings_concept_v01.png").convert("RGBA")
    daily = Image.open(SRC / "daily_tasks_and_signin_concept_v01.png").convert("RGBA")
    commercial = Image.open(SRC / "lobby_growth_and_commercial_concept_v01.png").convert("RGBA")

    records: list[dict] = []
    records.append(crop_with_mask(pause, (276, 317, 660, 599), [("rr", (0, 0, 383, 281), 27)], "battle_pause"))
    records.append(crop_with_mask(pause, (604, 629, 903, 805), [("rr", (0, 0, 298, 175), 23)], "exit_confirm"))
    records.append(crop_with_mask(pause, (65, 873, 577, 1590), [("rr", (0, 0, 511, 716), 31)], "settings"))
    records.append(crop_with_mask(pause, (579, 1403, 905, 1592), [("rr", (0, 0, 325, 188), 27)], "clear_data_confirm"))

    task_box = (13, 18, 928, 1205)
    records.append(crop_with_mask(daily, task_box, [
        ("rr", (233, 0, 683, 142), 35),
        ("rr", (36, 158, 425, 274), 28),
        ("rr", (445, 172, 770, 270), 25),
        ("rr", (0, 247, 914, 1186), 43),
    ], "daily_tasks"))
    signin_box = (13, 1212, 928, 1665)
    records.append(crop_with_mask(daily, signin_box, [
        ("rr", (24, 0, 278, 104), 26),
        ("rr", (280, 0, 580, 116), 28),
        ("rr", (0, 80, 914, 452), 41),
    ], "daily_signin"))

    records.append(crop_with_mask(commercial, (13, 704, 458, 1158), [("rr", (0, 0, 444, 453), 26)], "benefits"))
    records.append(crop_with_mask(commercial, (468, 704, 929, 1158), [("rr", (0, 0, 460, 453), 26)], "first_purchase_gift"))
    records.append(crop_with_mask(commercial, (13, 1165, 458, 1658), [("rr", (0, 0, 444, 492), 27)], "piggy_bank"))
    records.append(crop_with_mask(commercial, (464, 1165, 929, 1658), [("rr", (0, 0, 464, 492), 27)], "shop"))

    manifest = {
        "batch": "chapter01_centered_interfaces_v01",
        "coordinate_rule": "All popup instances use pivot (0.5, 0.5) and screen-center anchor. Scale uniformly only; non-uniform stretching is forbidden.",
        "status": "reference geometry locked; runtime shell cleanup pending",
        "assets": records,
    }
    (OUT / "manifest_reference_composites.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    contact_sheet(records)


if __name__ == "__main__":
    main()
