# 当前维护与美术特效入口 / Maintenance, Art And Effects

更新：2026-08-06
适用基线：`00_current_product_baseline.md`

## 修改归属

| 需求 | 首选入口 |
|---|---|
| 章节节点、Boss、教学、固定奖励 | `chapter_one_config.gd` |
| 通用数值、元素、怪物基础值、续战公式 | `game_config.gd` 与 `26_combat_balance_master.md` |
| 当前 12 张卡牌的名称、图标和文案 | `card_catalog.gd` |
| 能量、选择和下一次合成印记 | `skill_imprint_system.gd`、`energy_hud.gd`、`imprint_choice_modal_v2.gd` |
| 合成攻击次数、目标和伤害 | `merge_attack_event.gd`、`combat_system.gd` |
| 水晶苏醒、普攻和强化 | `crystal_system.gd`、`crystal_view.gd` |
| 怪物逻辑与状态 | `monster.gd`、`monster_system.gd`、`monster_view.gd` |
| 弹道、链路、飘字与命中特效 | `projectile_system.gd`、`effect_system.gd`、`chain_bolt.gd` |
| Loading、大厅、章节转场与结算 | `loading_view.gd`、`main_hub_view.gd`、`main_game.gd` |
| 战斗 HUD、路径、水晶城堡位置 | `battle_layer.tscn`、`battle_layer_view.gd` |

## 当前场景职责

- `scenes/main.tscn`：主流程挂载。
- `scenes/ui/loading_view.tscn`：自动 Loading、百分比、清档确认。
- `scenes/ui/main_hub.tscn`：老用户大厅与章节/续战入口。
- `scenes/combat/battle_layer.tscn`：水晶城堡、路径、怪物、HUD、弹道和特效承载层。
- `scenes/combat/monster_view.tscn`：怪物外观、血条、状态与受击锚点。
- `scenes/ui/imprint_choice_modal_v2.tscn`：印记三选一；显示“下一次有效合成”。
- `scenes/ui/crystal_card_choice_modal_v2.tscn`：水晶强化选择/展示。

## 美术替换约束

- 换图优先改场景引用或 `CardCatalog` 图标路径，不能把资源路径散写到战斗逻辑。
- 怪物美术替换后必须保留血条、状态层数、Boss 徽记与受击锚点的可读性。
- 水晶是守护目标和攻击源；不得再次拆分独立城堡/独立水晶两个主体。
- 所有战斗表现层必须 `mouse_filter = IGNORE`，不能阻挡棋盘点击。
- Loading 不得恢复“开始游戏”按钮；新用户/老用户分流由主流程决定。

## 特效接入约束

- 弹道：`ProjectileSystem`；一次性爆点、飘字、闪光：`EffectSystem`；怪物持续状态：`MonsterView`。
- 毒、火层数最多 4；毒每秒只显示一次合计红色飘字。
- 冰冻必须能看出蓝色化与 40% 移速；闪电链路按顺序硬直；Boss 必须有可辨识血条和徽记。
- 新增或替换特效后，重开、失败、结算、退出与恢复路径都必须清理临时节点和 Tween。

## 修改后的最低验证

- 战斗规则：`merge_combo_attack_smoke.gd`、`element_feedback_smoke.gd`。
- 章节或续玩：`chapter_one_config_smoke.gd`、`campaign_resume_flow_smoke.gd`。
- 印记：`skill_imprint_flow_smoke.gd`、`chapter_energy_imprint_smoke.gd`。
- 启动/大厅：`loading_view_smoke.gd`、`first_time_startup_flow_smoke.gd`、`main_hub_flow_smoke.gd`。
