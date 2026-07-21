# 游戏资源目录整理说明

本目录记录 2026-07-21 资源整理的迁移、审计和图集分组结果。整理只做移动、改名和隔离，没有物理删除美术资源。

## 当前分区

- `assets/runtime/`：Godot 运行时资源，共 185 个有效文件。文件和目录统一使用小写英文 `snake_case`。
- `art_source/`：效果图、检查图、视频、GIF、源序列和未接入的新素材，共 158 个有效文件。根目录含 `.gdignore`，不会被 Godot 导入或打包。
- `asset_review_delete/2026-07-21/`：已替换资源、旧 Cocos 遗留和 Git 基线中已删除的旧资源，共 299 个有效文件。根目录含 `.gdignore`，用户审核前不得删除。

“有效文件”不包含 `.import`、清单、说明文件和 `.gdignore`。完整审计表共 642 条。

## 清单

- `asset_inventory.csv`：完整资源清单，包含原路径、现路径、分区、Git 状态、尺寸、SHA-256、引用位置、图集组和迁移理由。
- `asset_move_map.csv`：185 个运行时资源的旧路径到新路径映射。
- `art_source_map.csv`：美术源文件迁移和版本号规范化映射。
- `atlas_groups.csv`：运行时图片的建议图集分组与排除项。
- `../../asset_review_delete/2026-07-21/manifest.csv`：待删除审核清单，包含替代关系和判定理由。

## 命名规则

- 运行时文件：小写英文 `snake_case`，序列帧使用 `frame_00.png`。
- 运行时正式资源不保留 `_v1`、`_v2`；历史版本进入 `art_source` 或待删除审核区。
- 美术源文件可保留中文，但版本号统一为 `_v01`、`_v02`。
- 禁止在 `assets/runtime` 使用空格、方括号、中文、大写字母和无语义 `layer_001` 名称。

## 图集规则

- `atlas_ui_common`、`atlas_ui_battle`、`atlas_ui_cards`、`atlas_ui_skill_choice`、`atlas_ui_wave_choice`、`atlas_ui_settlement` 分组可分别制作图集。
- 大背景、Shader 采样图、序列帧、序列拼图和怪物动画保持独立，不并入普通 UI 图集。
- 本次仅生成分组清单，没有生成或修改实际图集。

## 审核约束

- `asset_review_delete` 中的文件都只是隔离，未获用户确认不得物理删除。
- 冰冻受击运行时资源使用用户替换的 10 帧拼图；被替换的旧图保存在审核区，并在审核清单中注明。
- 新增资源、修改资源、明确运行时引用和动态加载资源均按受保护资源处理。
