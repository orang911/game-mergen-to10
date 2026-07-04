# Merge To 10 项目方向入口 / Project Direction Index

> 本文件现在只作为项目方向导航。详细设计、技术方案和讨论记录已经拆分到 `docs/`。
> 更新时间：2026-07-04

## 快速定位 / Quick Links

| 主题 | 文档 |
| --- | --- |
| 文档总目录 / Docs Index | `docs/README.md` |
| 当前项目状态 / Current State | `docs/01_current_state.md` |
| 核心合成规则 / Core Merge Rules | `docs/02_core_merge_rules.md` |
| 战斗系统设计 / Combat Design | `docs/03_combat_design.md` |
| 攻击与持续水晶 / Attack And Crystal | `docs/04_attack_crystal_design.md` |
| 技术架构与模块拆分 / Technical Architecture | `docs/05_technical_architecture.md` |
| 视觉、场景与 UI / Visual Scene Plan | `docs/06_visual_scene_plan.md` |
| 实现路线图 / Roadmap | `docs/07_roadmap.md` |
| 待讨论问题 / Open Questions | `docs/08_open_questions.md` |
| 决策记录 / Decision Log | `docs/09_decision_log.md` |
| 架构维护与美术特效 / Architecture, Art, Effects | `docs/10_architecture_maintenance_art_effects.md` |
| 完整旧版备份 / Full Archive | `docs/archive/PROJECT_DIRECTION_FULL_2026-07-04.md` |

## 当前核心方向 / Current Core Direction

- 保留原有 5x5 数字合成玩法和操作手感。
- 在外层加入围绕棋盘移动的怪物队列。
- 合成后触发一次主动攻击，优先攻击最靠近终点的怪物。
- 新增持续攻击水晶，承载本局成长后的基础战力，解决后期低级合成攻击断档。
- 怪物到达终点后扣除城堡耐久。
- 战斗、怪物、路径、弹道、特效、水晶、波次、城堡耐久都从棋盘逻辑中拆出。

## 最近新增讨论 / Recent Additions

### 持续攻击水晶 / Continuous Attack Crystal

问题：

- 玩家为了合成高等级，后期仍然需要大量合成低级数字。
- 如果攻击只看当前合成等级，后期低级合成会出现明显输出断档。

方向：

- 合成攻击仍然是主动爆发。
- 水晶作为本局成长后的基础战力。
- 水晶等级跟随本局历史最高等级。
- 水晶低频攻击最靠近终点的怪物。
- 水晶输出不能取代合成攻击，只负责保底和成长表现。

详见：`docs/04_attack_crystal_design.md`

## 当前建议执行顺序 / Recommended Order

1. 保持现有合成核心稳定。
2. 完成结构拆分和事件边界。
3. 完成怪物路径、波次、城堡耐久最小闭环。
4. 接入合成攻击。
5. 加入持续攻击水晶。
6. 再做颜色属性、弹道、特效、道具和技能。

## 维护规则 / Maintenance Rules

- 根文档只放导航和最新摘要。
- 具体设计写进 `docs/` 对应主题文档。
- 新问题先补到 `docs/08_open_questions.md`。
- 已确认结论补到 `docs/09_decision_log.md`。
