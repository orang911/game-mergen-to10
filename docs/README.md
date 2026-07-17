# Merge To 10 文档目录 / Documentation Index

> 本目录用于拆分原 `PROJECT_DIRECTION.md` 中的长期规划、玩法设计、技术方案和讨论记录。
> 完整旧版原文已备份到 `docs/archive/PROJECT_DIRECTION_FULL_2026-07-04.md`。

## 文档索引 / Document Index

| 文档 | 用途 |
| --- | --- |
| `01_current_state.md` | 当前项目状态 / Current state、已有功能、主要入口。 |
| `02_core_merge_rules.md` | 核心合成规则 / Core merge rules。 |
| `03_combat_design.md` | 战斗系统设计 / Combat design。 |
| `04_attack_crystal_design.md` | 攻击与持续水晶 / Attack and continuous crystal。 |
| `05_technical_architecture.md` | 技术架构与模块拆分 / Technical architecture。 |
| `06_visual_scene_plan.md` | 视觉、场景与 UI / Visual scene and UI plan。 |
| `07_roadmap.md` | 实现路线图 / Roadmap。 |
| `08_open_questions.md` | 待讨论问题 / Open questions。 |
| `09_decision_log.md` | 决策记录 / Decision log。 |
| `10_architecture_maintenance_art_effects.md` | 架构维护、美术替换与特效添加指南 / Architecture, art, and effects maintenance guide。 |
| `12_execution_plan_2026-07-15.md` | 当前执行计划、优先级与验收清单 / Current execution plan and acceptance checklist。 |
| `13_skill_imprint_mechanism.md` | 技能印记机制 / Skill imprint mechanism。 |
| `14_initial_card_catalog.md` | 首批 9 张卡牌名称与效果 / Initial nine-card catalog。 |
| `15_unified_card_wave_rules_2026-07-16.md` | 统一卡池、中心能量选择、五波节点奖励与 20 波关卡规则。 |
| `16_crystal_tower_card_design_2026-07-17.md` | 水晶塔辅助攻击定位、8 张物品化水晶卡与魔法蒸汽城堡美术规则。 |

## 当前核心方向 / Current Core Direction

- 保留原有 5x5 数字合成操作。
- 合成后触发一次主动攻击，攻击最靠近终点的怪物。
- 新增持续攻击水晶，用于承载玩家本局成长后的基础战力，解决后期低级合成攻击断档。
- 怪物沿棋盘外圈回形路径移动，到达终点扣除城堡耐久。
- 战斗、弹道、特效、怪物、波次、城堡耐久都应从主棋盘逻辑中拆出。

## 当前工作基线 / Current Work Baseline

- 核心战斗、能量技能印记和波次水晶强化闭环已经落地；当前重点转为移动端实机冒烟、视觉细调和数值打磨。
- `main_game.gd` 仍然是较大的集中式流程脚本；棋盘/合成系统的进一步拆分属于中期重构，不应阻塞当前版本收口。
- 技能印记与九张卡牌的当前运行规则见 `13_skill_imprint_mechanism.md` 和 `14_initial_card_catalog.md`。
- 已确认但尚待代码替换的 8 张水晶塔物品卡与 13 张目标总卡池见 `16_crystal_tower_card_design_2026-07-17.md`。

## 维护规则 / Maintenance Rules

- `PROJECT_DIRECTION.md` 只保留导航和最近变更摘要。
- 新讨论先进入对应主题文档；跨主题内容可以在 `08_open_questions.md` 留索引。
- 已确认的结论同步补到 `09_decision_log.md`。
- 大段历史原文不再塞回根文档，必要时查 archive。
