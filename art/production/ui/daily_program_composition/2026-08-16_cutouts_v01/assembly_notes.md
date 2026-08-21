# Daily UI program-composition notes

## Task panel

Layer order:

1. `daily_task_panel_shell_fixed_v01.png`
2. `daily_title_tab_v01.png`
3. Five instances of `daily_task_row_default_v01.png`; replace the active row with
   `daily_task_row_selected_v01.png`
4. Task icon, program text, progress track/fill, reward icon and state button
5. Optional program-drawn sparkle effect

Button mapping:

- unavailable: `daily_button_disabled_v01.png`
- claimed: `daily_button_claimed_v01.png`
- claimable: `daily_button_claim_v01.png`

## Sign-in panel

Layer order:

1. `daily_signin_panel_shell_fixed_v01.png`
2. `daily_title_tab_v01.png`
3. Seven card instances using default/selected/premium states
4. Day label, reward icon, amount, claimed check and current-day button text

Card mapping:

- normal: `daily_signin_card_default_v01.png`
- current day: `daily_signin_card_selected_v01.png`
- day-seven premium: `daily_signin_card_premium_v01.png`

## Shared rules

- All Chinese text, numbers, reward counts and progress values are program drawn.
- All icon textures use a shared 512x512 canvas and center pivot `(0.5, 0.5)`.
- Same-state backplates share canvas size and center to avoid visual jumping.
- The task/sign-in panel shells are fixed-proportion assets; do not use NinePatch on them.
- Suggested texture filtering: linear; use mipmaps only if the asset is substantially downscaled.

