"""Verify approved secondary UI shells and their in-game centered placement."""

from pathlib import Path
import json
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
UI_ROOT = ROOT / "assets/runtime/ui"
CAPTURES = ROOT / "art/production/ui/chapter01/2026-08-14_secondary_in_game_acceptance"
VIEWPORT = (941, 1672)

PAGES = {
    "battle/pause.png": ("interfaces/battle_pause/backplates/ui_battle_pause_shell_v03.png", (384, 282)),
    "battle/exit_confirm.png": ("interfaces/exit_confirm/backplates/ui_exit_confirm_shell_v03.png", (299, 176)),
    "hub/settings.png": ("interfaces/settings/backplates/ui_settings_shell_v03.png", (512, 717)),
    "hub/clear_confirm.png": ("shared/confirmation/backplates/ui_clear_data_confirm_shell_v03.png", (326, 189)),
    "hub/first_purchase.png": ("interfaces/first_purchase/backplates/ui_first_purchase_gift_shell_v03.png", (461, 454)),
    "hub/piggy.png": ("interfaces/piggy_bank/backplates/piggy_bank_panel_v01.png", (539, 583)),
    "hub/shop.png": ("interfaces/shop/backplates/ui_shop_shell_v03.png", (465, 493)),
}
TASK_CAPTURE = "hub/daily_combined.png"
TASK_SIZE = (915, 1513)


def snapped_center(size: tuple[int, int]) -> tuple[int, int]:
    return ((VIEWPORT[0] - size[0] + 1) // 2, (VIEWPORT[1] - size[1] + 1) // 2)


def main() -> None:
    errors: list[str] = []
    for capture_name, (asset_name, expected_size) in PAGES.items():
        asset_path = UI_ROOT / asset_name
        capture_path = CAPTURES / capture_name
        if not asset_path.exists() or not capture_path.exists():
            errors.append(f"missing: {asset_path if not asset_path.exists() else capture_path}")
            continue
        asset = Image.open(asset_path).convert("RGBA")
        capture = Image.open(capture_path).convert("RGB")
        if asset.size != expected_size:
            errors.append(f"{asset_name}: {asset.size} != {expected_size}")
        if capture.size != VIEWPORT:
            errors.append(f"{capture_name}: {capture.size} != {VIEWPORT}")
        x, y = snapped_center(expected_size)
        if not (0 <= x <= VIEWPORT[0] - expected_size[0] and 0 <= y <= VIEWPORT[1] - expected_size[1]):
            errors.append(f"{capture_name}: centered rect out of bounds at {(x, y)}")
        if asset.getchannel("A").getextrema() != (0, 255):
            errors.append(f"{asset_name}: transparent edge contract failed")

    task_capture = CAPTURES / TASK_CAPTURE
    if not task_capture.exists():
        errors.append(f"missing: {task_capture}")
    else:
        task_image = Image.open(task_capture).convert("RGB")
        if task_image.size != VIEWPORT:
            errors.append(f"{TASK_CAPTURE}: {task_image.size} != {VIEWPORT}")
        daily_rect = (13, 78, *TASK_SIZE)
        if daily_rect[0] + daily_rect[2] > VIEWPORT[0] or daily_rect[1] + daily_rect[3] > VIEWPORT[1]:
            errors.append(f"{TASK_CAPTURE}: approved daily rect out of bounds at {daily_rect}")

    manifest_path = ROOT / "art/production/ui/chapter01/2026-08-13_centered_interfaces_runtime_v04/manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("version") != "v04" or manifest.get("manifest_revision") != "v10":
        errors.append("runtime manifest must identify physical package v04 with manifest_revision v10")
    benefits_path = UI_ROOT / "interfaces/benefits/backplates/benefits_popup_shell_fixed_v01.png"
    if not benefits_path.exists():
        errors.append(f"missing: {benefits_path}")
        benefits = None
    else:
        benefits = Image.open(benefits_path).convert("RGBA")
    if benefits is not None and (benefits.getchannel("A").getbbox() is None or benefits.getchannel("A").getbbox()[3] < benefits.height - 4):
        errors.append("benefits shell is missing the formal bottom bevel")
    baked = [entry["file"] for entry in manifest.get("assets", []) if entry.get("text_baked")]
    if baked:
        errors.append(f"formal runtime frames must not bake dynamic text: {baked}")

    daily_manifest_path = UI_ROOT / "interfaces/daily_program/manifest.json"
    if not daily_manifest_path.exists():
        errors.append("daily program-composition runtime manifest is missing")
    else:
        daily_manifest = json.loads(daily_manifest_path.read_text(encoding="utf-8"))
        if daily_manifest.get("version") != "v03" or not daily_manifest.get("runtime_integrated"):
            errors.append("daily runtime manifest must identify the integrated v03 export")
        daily_assets = daily_manifest.get("assets", [])
        if len(daily_assets) != 24:
            errors.append(f"daily runtime should contain 24 active assets, got {len(daily_assets)}")
        for entry in daily_assets:
            asset_path = ROOT / entry["file"]
            if not asset_path.exists():
                errors.append(f"daily runtime asset missing: {entry['file']}")
                continue
            image = Image.open(asset_path).convert("RGBA")
            if max(image.size) > 2048:
                errors.append(f"daily runtime asset exceeds 2048: {entry['file']} {image.size}")
            if image.getchannel("A").getbbox() is None:
                errors.append(f"daily runtime asset is transparent: {entry['file']}")
            if entry.get("text_baked"):
                errors.append(f"daily runtime asset must remain text-free: {entry['file']}")
            rgba = list(image.getdata())
            if any(alpha == 0 and (red != 0 or green != 0 or blue != 0) for red, green, blue, alpha in rgba):
                errors.append(f"daily runtime transparent RGB is contaminated: {entry['file']}")
            partial = {alpha for _, _, _, alpha in rgba if 0 < alpha < 255}
            if not partial or min(partial) > 24 or len(partial) < 32:
                errors.append(f"daily runtime edge coverage is too hard: {entry['file']}")
            if asset_path.name.startswith("daily_progress_"):
                alpha = image.getchannel("A")
                for row_y in range(alpha.height):
                    xs = [x for x in range(alpha.width) if alpha.getpixel((x, row_y)) > 8]
                    if len(xs) > 1 and any(right - left > 1 for left, right in zip(xs, xs[1:])):
                        errors.append(f"daily progress scanline is fragmented: {entry['file']} y={row_y}")
                        break
        daily_names = {Path(entry["file"]).name for entry in daily_assets}
        required = {"daily_icon_slot_selected_v01.png", "daily_return_button_v03.png", "daily_signin_card_claimed_v02.png"}
        if not required.issubset(daily_names):
            errors.append("daily runtime is missing active selected-slot, return-button, or claimed-card states")

    if errors:
        raise SystemExit("SECONDARY_CENTERED_ACCEPTANCE_FAILED\n" + "\n".join(errors))
    print(f"SECONDARY_CENTERED_ACCEPTANCE_OK pages={len(PAGES) + 1} viewport={VIEWPORT}")


if __name__ == "__main__":
    main()
