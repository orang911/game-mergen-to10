# 当前技术架构 / Current Technical Architecture

更新：2026-08-06

## 边界原则

```text
棋盘：选择、合成、下落、补充
战斗：怪物、路径、攻击、水晶、波次、特效
章节：节点、奖励、过场、检查点、续战
界面：Loading、大厅、HUD、弹窗、结算
```

棋盘不直接修改怪物；它只产生 `MergeAttackEvent`。`CombatSystem` 消费该事件并负责目标、伤害和表现。

## 当前模块

| 模块 | 入口 | 责任 |
|---|---|---|
| 主流程 | `main_game.gd` | Loading/大厅/章节生命周期、棋盘合成桥接、失败、存档与结算。 |
| 章节数据 | `chapter_one_config.gd` | 第一章 12 波、Boss、脚本教学、固定奖励和续战配置。 |
| 战斗总控 | `combat_system.gd` | 协调波次、怪物、水晶、弹道、特效与合成攻击序列。 |
| 合成攻击事件 | `merge_attack_event.gd` | 合成数量、属性、主攻击次数、伤害和特殊参数的唯一计算入口。 |
| 怪物与路径 | `monster_system.gd`、`monster.gd`、`path_system.gd` | 生成、移动、最前目标、状态、死亡与到达水晶。 |
| 波次 | `wave_system.gd` | 显式出怪顺序、Boss 标记、清场和波次推进。 |
| 水晶 | `crystal_system.gd`、`crystal_view.gd` | 暗淡/苏醒、普通攻击、水晶卡与状态保存。 |
| 能量与印记 | `skill_imprint_system.gd`、`energy_hud.gd` | 能量、光点、唯一待触发槽位和满能量选择。 |
| 卡牌 | `card_catalog.gd`、选择弹窗脚本 | 12 张运行时卡牌定义、类型、图标和描述。 |
| 表现 | `projectile_system.gd`、`effect_system.gd`、各 `View` | 弹道、连锁、飘字、命中、死亡和 HUD。 |

## 数据事实来源

| 内容 | 唯一运行来源 |
|---|---|
| 通用战斗数值、怪物基础值、元素参数、能量参数 | `scripts/game_config.gd` |
| 第一章与续战波次 | `scripts/chapter_one_config.gd` |
| 当前卡池、名称、说明、图标 | `scripts/card_catalog.gd` |
| 章节状态与存档序列化 | `scripts/main_game.gd`、各系统的 `export_state/restore_state` |

Markdown 用于解释、记录与验收；不得成为运行时数值的第二份来源。

## 存档规则

章节运行状态必须保存：当前波次与节点、棋盘全部方块、存活怪物生命与路径进度、水晶耐久和强化、能量、唯一待触发印记、已获得卡牌、章节模式与检查点。

退出后重启恢复原战斗；失败重试恢复节点检查点；完成第一章后的续战从大 Boss 结束状态继续。

## 测试边界

`tests/` 已覆盖 Loading、首启分流、章节、印记、续玩、战斗序列、元素反馈、卡牌弹窗与数值模拟。修改以下内容时必须补对应 smoke：

- 攻击次数、目标选择或元素层数；
- 章节波次、Boss、奖励或检查点；
- Loading/大厅分流与清档；
- 印记选择、消耗或弹窗暂停；
- 存档字段与恢复顺序。
