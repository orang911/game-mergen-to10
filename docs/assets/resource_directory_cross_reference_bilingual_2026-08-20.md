# 全项目资源目录对照 / Project Resource Directory Cross-Reference

更新日期：`2026-08-20`

这份文档解决“先找到要改的界面，再找到它的资源”问题。逐文件引用、状态、哈希和来源仍以 `resource_asset_register_bilingual_2026-08-20.csv` 为准。

## 当前 UI 目录，一眼看懂

当前真实使用的 UI 共 `235` 个逻辑资源：`163 PNG + 72 TRES`。它们已经全部进入下面三类目录；旧 UI 目录不再作为当前资源入口。

```text
assets/runtime/ui/
├─ interfaces/                         独立界面专属资源，138 个
│  ├─ battle/                          战斗主界面，24
│  ├─ battle_pause/                    战斗暂停，1
│  ├─ benefits/                        权益弹窗，8
│  ├─ chapter_node_complete/           节点完成弹窗，4
│  ├─ crystal_card_choice/             水晶卡选择，4
│  ├─ daily_program/                   任务＋签到，26
│  ├─ exit_confirm/                    退出确认，1
│  ├─ first_purchase/                  首充礼包，3
│  ├─ imprint_choice/                  印记选择，5
│  ├─ legacy_runtime_controls/         兼容预加载控件，6
│  ├─ loading/                         Loading，3
│  ├─ main_hub/                        大厅，13
│  ├─ max_level_success/               最高等级成功反馈，5
│  ├─ piggy_bank/                      存钱罐，1
│  ├─ settings/                        设置，3
│  ├─ settlement/                      结算，26
│  └─ shop/                            商城，5
├─ components/                         可跨界面复用的玩法组件，72 个
│  ├─ board_glyphs/                    棋盘数字与字母，37
│  ├─ board_tiles/                     棋盘色块，6
│  ├─ card_backs/                      卡背，1
│  ├─ card_icons/                      水晶卡与印记图标，17
│  ├─ crystal_tower/                   水晶塔 1–9 级，9
│  └─ rating_stars/                    星级状态，2
└─ shared/                             跨界面共用视觉，25 个
   ├─ app/                             应用图标，1
   ├─ backplates/                      共用基础面板，1
   ├─ buttons/                         共用按钮状态，5
   ├─ confirmation/                    共用确认框，1
   ├─ decorations/                     共用标题装饰，1
   └─ meta_icons/                      大厅及元系统图标，16
```

判断方法：只影响一个完整界面的资源放 `interfaces`；表达棋盘、卡牌、水晶塔等玩法对象的资源放 `components`；确实被两个以上界面共同使用的通用视觉放 `shared`。

## 独立界面目录对照

| 界面 / Interface | 当前运行目录 / Runtime Directory | 主要内容 | 数量 | 当前状态 |
|---|---|---|---:|---|
| Loading | `assets/runtime/ui/interfaces/loading/` | 全屏背景、进度条轨道与填充 | 3 | 正在使用 |
| 大厅 / Main Hub | `assets/runtime/ui/interfaces/main_hub/` | 大厅背景、岛屿、按钮和任务框体 | 13 | 正在使用 |
| 战斗 / Battle | `assets/runtime/ui/interfaces/battle/` | 世界背景、道路、传送门、顶部 HUD、能量栏、棋盘底板、教学与属性提示 | 24 | 正在使用 |
| 印记选择 / Imprint Choice | `assets/runtime/ui/interfaces/imprint_choice/` | 卡槽、确认/广告按钮、标题和角标 | 5 | 正在使用 |
| 节点完成 / Node Complete | `assets/runtime/ui/interfaces/chapter_node_complete/` | 面板、标题、分割线和继续按钮 | 4 | 正在使用 |
| 水晶卡选择 / Crystal Card Choice | `assets/runtime/ui/interfaces/crystal_card_choice/` | 选择卡框、确认按钮、标题和角标 | 4 | 正在使用 |
| 结算 / Settlement | `assets/runtime/ui/interfaces/settlement/` | 结算面板、统计框、奖励、页签、标题和图标 | 26 | 正在使用 |
| 暂停 / Battle Pause | `assets/runtime/ui/interfaces/battle_pause/` | 暂停弹窗框体 | 1 | 使用中待最终审核 |
| 退出确认 / Exit Confirm | `assets/runtime/ui/interfaces/exit_confirm/` | 退出确认框体 | 1 | 使用中待最终审核 |
| 设置 / Settings | `assets/runtime/ui/interfaces/settings/` | 设置框体、开关两态 | 3 | 使用中待最终审核 |
| 任务＋签到 / Daily Program | `assets/runtime/ui/interfaces/daily_program/` | 组合页底板、按钮、进度、任务和奖励图标 | 26 | 使用中待最终审核 |
| 权益 / Benefits | `assets/runtime/ui/interfaces/benefits/` | 权益框体、权益卡、购买按钮和图标 | 8 | 使用中待最终审核 |
| 首充 / First Purchase | `assets/runtime/ui/interfaces/first_purchase/` | 首充框体、奖励槽和开箱图 | 3 | 使用中待最终审核 |
| 存钱罐 / Piggy Bank | `assets/runtime/ui/interfaces/piggy_bank/` | 存钱罐框体 | 1 | 使用中待最终审核 |
| 商城 / Shop | `assets/runtime/ui/interfaces/shop/` | 商城框体、商品和货币图标 | 5 | 使用中待最终审核 |
| 最高等级成功 / Max-Level Success | `assets/runtime/ui/interfaces/max_level_success/` | 成功面板、光效、皇冠、新纪录和继续按钮 | 5 | 正在使用 |
| 兼容控件 / Legacy Runtime Controls | `assets/runtime/ui/interfaces/legacy_runtime_controls/` | 仅由兼容预加载保留的返回、关闭、刷新等旧控件 | 6 | 正在引用；建议后续单独清债 |

## 组件与共用资源对照

| 类别 | 当前目录 | 谁在使用 | 修改影响 |
|---|---|---|---|
| 棋盘色块 | `assets/runtime/ui/components/board_tiles/` | `game_config.gd`、棋盘方块 | 所有棋盘色块表现 |
| 棋盘数字/字母 | `assets/runtime/ui/components/board_glyphs/` | `game_config.gd`、棋盘文字层 | 1–10 与 A–Z 的所有显示 |
| 卡牌图标 | `assets/runtime/ui/components/card_icons/` | 卡牌目录、印记选择、商城 | 水晶卡和棋盘印记图标 |
| 卡背 | `assets/runtime/ui/components/card_backs/` | 水晶卡牌显示 | 水晶卡背面 |
| 水晶塔 | `assets/runtime/ui/components/crystal_tower/` | 战斗水晶视图 | 1–9 级水晶外观 |
| 星级 | `assets/runtime/ui/components/rating_stars/` | 水晶卡选择、结算卡组 | 星级激活/空槽状态 |
| 元系统图标 | `assets/runtime/ui/shared/meta_icons/` | 大厅及日常系统 | 大厅入口、货币、签到等图标 |
| 共用按钮 | `assets/runtime/ui/shared/buttons/` | 多个二级弹窗 | 蓝/黄按钮和禁用状态 |
| 共用确认框 | `assets/runtime/ui/shared/confirmation/` | 清空数据、购买确认 | 两个确认流程同时变化 |
| 共用面板/标题 | `assets/runtime/ui/shared/backplates/`、`decorations/` | 多个二级弹窗 | 弹窗基础皮肤与标题装饰 |
| 应用图标 | `assets/runtime/ui/shared/app/` | `project.godot` | 应用与导出图标 |

## 旧目录 → 当前目录

| 迁移前目录 | 当前入口 | 说明 |
|---|---|---|
| `assets/runtime/ui/screens/loading/` | `interfaces/loading/` | 3 个活动资源全部迁入 |
| `assets/runtime/ui/screens/main_hub_v2/` | `interfaces/main_hub/` + `shared/meta_icons/` | 大厅框体/背景与共用元图标分离 |
| `assets/runtime/ui/screens/settlement/` | `interfaces/settlement/` | 26 个活动资源全部迁入 |
| `assets/runtime/ui/battle/**` | `interfaces/battle/` + `interfaces/imprint_choice/` + `interfaces/chapter_node_complete/` + 棋盘组件 | 战斗主界面、独立弹窗和玩法组件拆开 |
| `assets/runtime/ui/cards/**` | `components/card_*` + `components/rating_stars/` + `interfaces/crystal_card_choice/` | 卡牌组件与选择界面拆开 |
| `assets/runtime/ui/secondary_centered_v04/**` | 对应的暂停、确认、设置、首充、存钱罐、商城界面及 `shared/**` | 22 个活动资源按真实界面归属拆分 |
| `assets/runtime/ui/daily_program_composition_v02/**` | `interfaces/daily_program/` | 26 个活动资源与当前运行 Manifest 全部迁入；旧目录已为空并移除 |
| `assets/runtime/ui/benefits_popup_v01/**` | `interfaces/benefits/` | 8 个活动资源全部迁入 |
| `assets/runtime/ui/common/**` | `shared/app/`、`interfaces/max_level_success/`、`interfaces/battle/`、`interfaces/legacy_runtime_controls/` | 原 common 中并非所有资源都真正共用，已按消费者拆分 |
| `assets/runtime/资源/**` | `interfaces/battle/**` | 12 个活动资源已迁入并改为明确英文名；旧中文根目录已为空并移除 |

迁移清单中的每一行都有精确旧路径和新路径：`ui_runtime_asset_move_map_2026-08-20.csv`。旧目录中仍存在的文件均是本次范围外的未引用旧版本或历史 Manifest；没有被本次归整删除或恢复。

## 图集打包对照

现有 4 套运行图集已经整体迁入新目录，同时补建了可独立修改的 72 张源切图。

| 图集 | 运行图集与 TRES | 可修改源切图 | 数量 |
|---|---|---|---:|
| 棋盘色块 | `components/board_tiles/{atlases,atlas_regions}/` | `art/production/ui/runtime_atlas_sources/2026-08-20/board_tiles/` | 5 |
| 棋盘字符 | `components/board_glyphs/{atlases,atlas_regions}/` | `art/production/ui/runtime_atlas_sources/2026-08-20/board_glyphs/` | 36 |
| 卡牌图标 | `components/card_icons/{atlases,atlas_regions}/` | `art/production/ui/runtime_atlas_sources/2026-08-20/card_icons/` | 16 |
| 元系统图标 | `shared/meta_icons/{atlases,atlas_regions}/` | `art/production/ui/runtime_atlas_sources/2026-08-20/meta_icons/` | 15 |

事实说明：旧的独立图集源切图在本次工作开始前已经不存在。本次没有恢复已删除目录；新源切图是依据现有运行图集和 TRES 区域无损裁切得到，能重建当前画面，但不等于找回更高分辨率原始母版。

迁移表中的打包策略统计：`102` 个新图集候选、`57` 个独立纹理、`72` 个现有图集区域、`4` 张现有图集原图。大背景、大面板、NinePatch 风险资源和水晶等级图默认保持独立，不因为同目录就强行打进一张图集。

## 全项目顶层目录职责

| 当前目录 | 中文职责 | English Purpose | 当前物理资源数 |
|---|---|---|---:|
| `assets/runtime/**` | Godot 正式运行资源 | Godot runtime assets | 463 |
| `shaders/**` | 战斗及 UI 着色器 | Runtime shaders | 6 |
| `art/production/**` | 母版、生产切图、可维护图集源、预览与 QA | Masters, production cutouts, atlas sources, previews and QA | 625 |
| `art/ai_generated/**` | AI 原始生成结果 | Original AI outputs | 161 |
| `art/ui_slices/**` | 历史 UI 切图 | Historical UI slices | 51 |
| `art_source/**` | 历史原件与参考 | Legacy originals and references | 73 |
| `docs/assets/**` | 总账、迁移表、目录对照和验收报告 | Catalog, move maps, directory guide and validation reports | — |

当前扫描共 `1379` 个物理资源；主流程可达 `280` 个（276 个运行资源＋4 个 Shader），其中 `ACTIVE_RUNTIME=224`、`ACTIVE_REVIEW_PENDING=56`。运行目录内另有 `189` 个未引用旧资源，它们没有进入新的 `interfaces/components/shared` 目录。

## 按需求快速查找

| 你要做什么 | 先看这里 | 再看这里 |
|---|---|---|
| 修改某个完整界面 | `assets/runtime/ui/interfaces/<界面名>/` | 对应 `art/production/**/manifest.json` |
| 修改棋盘、卡牌、水晶塔等通用玩法外观 | `assets/runtime/ui/components/<组件名>/` | 图集源切图目录或资源来源列 |
| 修改多个界面共用按钮/图标 | `assets/runtime/ui/shared/<类别>/` | 迁移表中的消费者和影响范围 |
| 修改一张已入图集的小图 | `art/production/ui/runtime_atlas_sources/2026-08-20/` | 运行 `tools/build_runtime_atlases.ps1 -Mode Build -Scope UI` |
| 判断资源是否真在用 | `resource_asset_register_bilingual_2026-08-20.csv` | 查看主状态、引用数量、主要引用位置 |
| 查旧名称和新名称 | `ui_runtime_asset_move_map_2026-08-20.csv` | `ui_runtime_asset_reorganization_report_2026-08-20.json` |
| 查需要美术审核的资源 | 工作簿源数据的 `04_审核资源 Review Queue` | 对应生产 Manifest 与 QA 图 |

## 维护规则

1. 新界面资源先进入对应 `interfaces/<interface_id>/`，不要重新建立 `screens_v2`、`complete_v03` 一类版本目录。
2. 同一共用资源只保留一个运行时物理源；某个界面需要不同效果时，创建界面专属的新文件并只切换该界面引用。
3. PNG、`.import`、图集原图、AtlasTexture TRES 和消费者引用必须作为一次原子迁移处理。
4. 生产母版和可编辑源放 `art/production/**`，运行目录只放游戏真正加载的成品。
5. 旧未引用资源不因本次目录归整自动删除；清理前必须另做审核与删除授权。
