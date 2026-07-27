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
| `17_target_card_catalog_2026-07-17.md` | 下一轮待实现的 8 张棋盘道具卡、8 张水晶装备卡及旧卡迁移表。 |
| `18_balance_simulation_report_2026-07-22.md` | 游戏内数值模拟器口径、6000 局首轮结果与下一轮调参建议。 |
| `19_refresh_probability_experiment_2026-07-22.md` | 当前/V1/V2/V2动态四规则的1200局刷新概率实验与死盘诊断。 |
| `20_state_scored_refresh_experiment_2026-07-22.md` | 基于虚拟落子和整盘评分的动态概率算法、1200局结果及概率上限诊断。 |
| `21_sliding_window_board_progression_2026-07-22.md` | 五级滑窗纯棋盘推进实验、字母阶段到达率与正式掉落策略。 |
| `22_crystal_tower_long_term_progression_2026-07-23.md` | 水晶塔攻击基线、暂停前期升级及后续长线成长接口。 |
| `23_combo_focus_simulation_2026-07-23.md` | 合成连续集火规则、快速配对结果与正式模拟口径。 |

## 当前核心方向 / Current Core Direction

- 保留原有 5x5 数字合成操作。
- 合并 N 个方块后触发 N 发连续攻击，持续集火最靠近终点的怪物。
- 新增持续攻击水晶，用于承载玩家本局成长后的基础战力，解决后期低级合成攻击断档。
- 怪物沿棋盘外圈回形路径移动，到达终点扣除城堡耐久。
- 战斗、弹道、特效、怪物、波次、城堡耐久都应从主棋盘逻辑中拆出。

## 当前工作基线 / Current Work Baseline

- 核心战斗、能量技能印记和波次水晶强化闭环已经落地；当前重点转为移动端实机冒烟、视觉细调和数值打磨。
- `main_game.gd` 仍然是较大的集中式流程脚本；棋盘/合成系统的进一步拆分属于中期重构，不应阻塞当前版本收口。
- 技能印记与九张卡牌的当前运行规则见 `13_skill_imprint_mechanism.md` 和 `14_initial_card_catalog.md`。
- 已确认但尚待代码替换的 16 张目标卡池见 `17_target_card_catalog_2026-07-17.md`。

## 维护规则 / Maintenance Rules

- `PROJECT_DIRECTION.md` 只保留导航和最近变更摘要。
- 新讨论先进入对应主题文档；跨主题内容可以在 `08_open_questions.md` 留索引。
- 已确认的结论同步补到 `09_decision_log.md`。
- 大段历史原文不再塞回根文档，必要时查 archive。
