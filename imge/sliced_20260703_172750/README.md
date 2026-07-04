# 2026-07-03 17:27:50 素材表切图对照

源图：
`F:\卖肉\godotT10\game_mergenTo10_published\imge\ChatGPT Image 2026年7月3日 下午05_27_50.png`

源图尺寸：`1024x1536`，真透明 `Format32bppArgb`。

输出目录：
`F:\卖肉\godotT10\game_mergenTo10_published\imge\sliced_20260703_172750`

裁切坐标表：
`slice_map.json`

## 可直接使用

- `entrance_gate.png`
- `entrance_label.png`
- `endpoint_castle.png`
- `endpoint_label.png`
- `castle_hit_effect.png`
- `wave_banner.png`
- `top_status_panel.png`
- `mini_castle_icon.png`
- `heart_icon.png`
- `shield_icon.png`
- `setting_button_bg.png`
- `setting_icon.png`
- `board_panel.png`
- `tile_empty_slot.png`
- `monster_*_walk_*.png`
- `monster_*_idle.png`
- `monster_hit_effect.png`
- `monster_die_effect.png`
- `tip_icon_bulb.png`
- `tip_panel.png`
- `decor_*`

## 暂时不直接接入

- `path_loop_sheet_reference.png`
  这张素材中间是黑色占位，不适合作正式路径贴图。当前工程继续用代码绘制外圈路径，后面需要一张完整透明 `path_loop.png` 再替换。

- `layout_preview_reference.png`
  这是组合预览，只作布局对照，不接入游戏。

- `tile_1.png` 到 `tile_5_selected.png`
  已切出，但当前阶段按要求“不换核心数字块”。后面需要统一风格时再替换。

- `bg_scenery_full.png`
  是背景小预览，不是完整竖屏背景。当前工程先保留原背景或代码布局。

## 当前工程坐标对照

Godot 工程基准：`720x1280`，见 `project.godot`。

当前代码布局锚点：

| 元素 | 当前工程位置/尺寸 | 对应切图 |
| --- | --- | --- |
| 棋盘数字区域 | `x=100, y=442, w=520, h=520` | 保留原数字块 |
| 棋盘白色底板 | `x=85, y=427, w=550, h=550` | `board_panel.png`，后续可替换 |
| 外圈路径 | 围绕棋盘，边距 `76` | 当前代码绘制，等待正式 `path_loop.png` |
| Wave 文本 | `x=230, y=74, w=260, h=64` | `wave_banner.png` + 程序文字 |
| 右上耐久面板 | `x=494, y=92, w=176, h=54` | `top_status_panel.png`、`mini_castle_icon.png`、`heart_icon.png`、`shield_icon.png` |
| 入口标签 | 跟随路径起点上方 | `entrance_label.png` |
| 入口门 | 路径起点附近 | `entrance_gate.png` |
| 终点标签 | 跟随路径终点附近 | `endpoint_label.png` |
| 城堡 | 路径终点附近 | `endpoint_castle.png` |
| 怪物 | 沿路径移动 | `monster_green_*`、`monster_blue_*`、`monster_red_*`、`monster_yellow_*` |
| 设置按钮 | 右上角按钮位 | `setting_button_bg.png`、`setting_icon.png` |
| 底部提示 | 底部中心 | `tip_icon_bulb.png`、`tip_panel.png` |

## 下一步接入顺序

1. 先接 `wave_banner.png`、`top_status_panel.png`、`heart_icon.png`、`shield_icon.png`，风险最低。
2. 再接 `entrance_gate.png`、`endpoint_castle.png` 和入口/终点标签。
3. 再把代码绘制怪物换成 `monster_*_idle.png`，动画帧后续再做。
4. 最后等正式 `path_loop.png`，替换当前代码绘制路径。
