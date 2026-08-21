# Core Battle UI HD Slices — v01

来源：`20260729_core_battle_ui_hd_redraw_v01.png`（941 × 1672）。

所有 PNG 均为 RGBA，已清理与图像边缘连通的草地 / 石路背景；原图未被修改。

## 直接切片（保留视觉对照）

- `top/pause_button_baked.png`
- `top/wave_status_baked.png`
- `top/time_status_baked.png`
- `top/currency_status_baked.png`
- `bottom/skill_panel_baked.png`
- `bottom/item_refresh_baked.png`
- `bottom/item_wand_baked.png`
- `bottom/item_lock_baked.png`
- `core/crystal_tower_baked.png`
- `core/crystal_hp_bar_baked.png`

`*_baked` 保留了效果图中的当前图标、文字或数值，仅用于对照、展示与过渡验证。

## 程序动态文字底板

`runtime_bases/` 内的三个状态底板已移除波次、时间和货币数值，适合由程序叠加文字：

- `wave_status_base.png`
- `time_status_base.png`
- `currency_status_base.png`

同目录还包含无图标 / 无文字的可复用底板：

- `pause_button_base.png`
- `skill_panel_base.png`
- `item_refresh_base.png`
- `item_wand_base.png`
- `item_lock_base.png`

## 坐标

`manifest.json` 记录了各直接切片在 941 × 1672 原画布中的裁切边界，方便场景中还原布局。

后续替换到 `assets/runtime/ui` 时，应以底板 + 图标 + 程序文本分层使用，不建议将 `*_baked` 作为长期运行时文字资源。
