# 游戏资源目录整理说明

## 2026-08-20 当前资源事实来源

截至 `2026-08-20`，全项目资源状态以本目录下的新双语总账为准：

- `resource_directory_cross_reference_bilingual_2026-08-20.md`：面向策划、美术和审核的目录对照入口；先按功能找到运行目录、生产目录、原始来源和版本替代关系。
- `directory_structure_cross_reference_detailed_2026-08-21.md`：逐子目录树与对照表，覆盖 `assets/runtime`、`shaders`、`art/production`、AI 原图和历史来源共 359 个目录。
- `directory_structure_register_detailed_2026-08-21.csv`：上述 359 个目录的可筛选登记表，含父目录、状态、当前在用数、生产/运行对应关系、直接修改规则和图集规则。
- `resource_asset_register_bilingual_2026-08-20.csv`：当前逐文件机器可读事实表，共 `1379` 个物理资源；不包含 `.import`、`.uid`、缓存、构建产物和 Manifest 本身。
- `resource_catalog_workbook_source_2026-08-20.json`：六个工作表的结构化数据源，包含目录汇总、资源明细、运行引用、审核队列、来源映射和状态字典。
- `resource_catalog_validation_2026-08-20.json`：本次扫描的自动验收结果。
- `ui_runtime_asset_move_map_2026-08-20.csv`：`235` 个当前 UI 资源的精确旧路径、新路径、界面归属和图集策略。
- `ui_runtime_asset_reorganization_report_2026-08-20.json`：资源迁移、`.import` 配套迁移和引用更新报告。
- `runtime_unreferenced_review_queue_2026-08-20.csv`：189 个运行目录未发现引用资源的证据审核表；仅供归档或删除审批，本表不会执行资源删除。
- `active_review_visual_queue_2026-08-20.csv`：56 个在用待审核资源的视觉检查队列，包含生产证据路径、三种视口截图要求和设备审核关卡。
- `claude_resource_followup_execution_status_2026-08-20.md`：资源归整后续工作执行状态、P0 验收记录和待处理关卡。
- `resource_catalog_bilingual_2026-08-20.xlsx`：人工审核主表的目标文件名；当前环境缺少项目规定的工作簿生成运行时，尚未生成，不能用空文件或其他库代替。

当前扫描结论：

- 当前物理资源共 `1379` 个：`assets/runtime` 463、`art/production` 625、`art/ai_generated` 161、`art/ui_slices` 51、`art_source` 73、`shaders` 6。
- 当前主流程可达资源为 `280` 个：`assets/runtime` 内 276 个，加上 4 个可达 Shader。
- `ACTIVE_RUNTIME` 224 个，`ACTIVE_REVIEW_PENDING` 56 个，`RUNTIME_UNREFERENCED` 189 个。
- 来源映射另记录 `379` 条 `HISTORICAL_MISSING` 历史缺失路径；这些记录不会混入当前物理资源数量，也不会触发文件恢复。
- “正在使用”依据 `scenes/main.tscn` 当前可达调用图、有效动态路径和 TRES 图集依赖判定；旧函数中仅保留的路径不算当前运行引用。

旧 `asset_inventory.csv`、`asset_move_map.csv`、`art_source_map.csv` 和 `atlas_groups.csv` 全部保留为历史迁移快照，用于追溯来源，不再代表当前资源数量或运行状态。旧隔离目录与原始来源的工作区删除状态保持原样，本次没有恢复或删除资源文件。

## 2026-08-20 当前 UI 运行资源归整

- `235` 个真实活动 UI 已从旧的 `battle/cards/common/screens/secondary_*` 及中文 `资源` 目录，迁入 `assets/runtime/ui/interfaces`、`components`、`shared`。
- 迁移包含 `163` 张 PNG、对应 `163` 个 `.import` 侧车、`72` 个 AtlasTexture TRES，以及代码、场景、项目配置和当前生产 Manifest 引用。
- 原 `assets/runtime/资源` 中的 12 个活动资源已迁移并改为明确英文名；该空目录已移除。
- 新目录只接收当前活动资源。旧目录中的未引用版本和历史 Manifest 保持原位，未随本次任务删除。
- 4 套现有 UI 图集已整体迁移；根据现有图集和 TRES 区域无损补建的 72 张可维护源切图位于 `art/production/ui/runtime_atlas_sources/2026-08-20/`。
- 当前图集计划以 `ui_runtime_asset_move_map_2026-08-20.csv` 的 `atlas_group` 与 `packing_policy` 为准；旧 `atlas_groups.csv` 只保留为历史快照。

## 2026-08-11 未引用资源隔离

- 对 `assets/runtime/` 与旧 `assets/UI/` 执行引用审计，只移动、不删除。
- `98` 个未引用运行时资源和 `145` 个旧 UI 源文件已进入 `asset_review_delete/2026-08-11/unreferenced/`。
- 共同步隔离 `241` 个 `.import` 侧车；当前 `assets/runtime/` 保留 `322` 个有效运行时文件。
- 本批次逐文件清单见 `../../asset_review_delete/2026-08-11/manifest.csv`。

> 本节及下方 2026-07-21 数据均为历史快照，不代表 2026-08-20 当前数量；其中引用的隔离目录与 Manifest 当前可能已不存在。

本目录记录 2026-07-21 资源整理的迁移、审计和图集分组结果。整理只做移动、改名和隔离，没有物理删除美术资源。

## 当前分区

- `assets/runtime/`：Godot 运行时资源，共 200 个有效文件。文件和目录统一使用小写英文 `snake_case`。
- `art_source/`：效果图、检查图、视频、GIF、源序列和未接入的新素材，共 161 个有效文件。根目录含 `.gdignore`，不会被 Godot 导入或打包。
- `asset_review_delete/2026-07-21/`：已替换资源、旧 Cocos 遗留和 Git 基线中已删除的旧资源，共 301 个有效文件。根目录含 `.gdignore`，用户审核前不得删除。

“有效文件”不包含 `.import`、清单、说明文件和 `.gdignore`。完整审计表共 662 条。

## 清单

- `asset_inventory.csv`：完整资源清单，包含原路径、现路径、分区、Git 状态、尺寸、SHA-256、引用位置、图集组和迁移理由。
- `asset_move_map.csv`：200 个运行时资源的旧路径到新路径映射。
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
- 冰冻受击运行时资源使用用户替换的 11 帧有效序列；毒系、暴击系和火系弹道、拖尾、粒子及受击序列使用 2026-07-22 更新资源。水晶塔使用同日新增的独立子弹、拖尾和 8 帧受击序列。被替换的旧图均保存在审核区并在审核清单中注明。
- 水晶塔 2、4、6、8 级外观已从误分类的审核区恢复；运行时现保留完整的 1–9 级连续外观。
- 新增资源、修改资源、明确运行时引用和动态加载资源均按受保护资源处理。
