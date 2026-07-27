# 技术架构与模块拆分 / Technical Architecture And Module Split

## 总体原则 / General Principles

- 保留现有棋盘、选择、合成、下落、补充流程。
- 战斗系统从一开始拆成独立脚本。
- 棋盘逻辑只负责产生合成结果，不直接操作怪物。
- 战斗系统接收合成事件，负责计算攻击目标、伤害和属性效果。
- 怪物移动、波次生成、城堡耐久、攻击表现、属性效果尽量独立管理。

核心边界：

```text
棋盘只产生合成结果。
战斗只消费合成结果。
```

## 建议模块 / Suggested Modules

| 模块 | 职责 |
| --- | --- |
| `BoardSystem` | 棋盘状态、方块生成、坐标、下落、补充。 |
| `MergeSystem` | 选中、合成、计分、合成结果事件。 |
| `SkillImprintSystem` | 技能能量、技能选择、结果块印记、印记触发与消耗。 |
| `BlockView` | 方块颜色、数字/字母显示、选中、抖动、缩放、合成移动动画。 |
| `CombatSystem` | 接收合成事件，协调攻击、水晶、怪物、弹道和特效。 |
| `CrystalSystem` | 持续攻击水晶等级、攻击节奏和基础输出。 |
| `ProjectileSystem` | 合成攻击、水晶攻击、连锁、穿透等弹道表现。 |
| `MonsterSystem` | 怪物生成、移动、血量、死亡、到终点扣耐久。 |
| `PathSystem` | 围绕棋盘的路径生成和路径进度。 |
| `WaveSystem` | 波次数量、类型、间隔和结束判断。 |
| `CastleSystem` | 城堡耐久、扣耐久、失败通知。 |
| `EffectSystem` | 合成光效、受击、死亡、属性、飘字。 |
| `AudioSystem` | 点击、合成、攻击、命中、死亡、失败、成功。 |
| `GameStateSystem` | 开始、暂停、游戏中、结算、复活、重开。 |
| `GameConfig` | 等级、颜色属性、攻击力、怪物、波次、道具数值。 |

## 合成攻击事件 / Merge Attack Event

合成完成后，棋盘或合成系统发出攻击事件。

事件应包含：

- 合成后等级。
- 颜色属性。
- 合成数量。
- 攻击起点位置。
- `merge_count`：原始合并数量。
- `attack_count`：实际主攻击发数；毒/暴击/火焰等于合并数量，冰冻等于 `N-1`，闪电为 1。
- `total_damage`：本次主攻击理论总伤害。
- `damage`：单发浮点伤害。
- `sequence_id`：用于并行执行及重置取消的序列标识。
- `target_count`：冰冻合成攻击使用 `N-1`，闪电及连续集火主攻击为 1；独立技能也可使用该字段。

建议结构：

```gdscript
var attack_event := {
	"level": clicked.level,
	"element": get_element_for_level(clicked.level),
	"merge_count": merged_count,
	"origin": board_layer.global_position + clicked.position,
}
```

当前建议使用合成后等级作为攻击等级，反馈更直接。

## 技能印记事件 / Skill Imprint Event

技能印记属于棋盘机制。`SkillImprintSystem` 负责管理能量和印记生命周期，技能效果由对应系统消费。

事件至少应包含：

- 技能标识。
- 触发方块等级。
- 触发方块位置。
- 触发顺序。
- 是否由目标块优先触发。

技能事件不能直接修改数字等级；需要改变棋盘时，通过 `BoardSystem` / `MergeSystem` 的公开接口执行。

## 目标选择 / Target Selection

- 每个怪物维护路径进度 `progress_ratio`。
- 越接近 1.0，越靠近终点。
- 每个合成序列保存自己的当前锁定目标。
- 首发从存活且未到达水晶的怪物中按 `progress_ratio` 从大到小取第一只。
- 当前目标存活时后续发数继续使用它；死亡或到达终点时才重新查询第一只。
- 飞行和间隔均由异步序列推进，`CombatSystem.reset()` 通过 generation 使旧回调失效，`ProjectileSystem.reset()` 清理视觉节点。

## 数据结构 / Data Structures

等级攻击力示例：

```gdscript
const LEVEL_ATTACK := {
	1: 2,
	2: 4,
	3: 6,
	4: 10,
	5: 14,
	6: 18,
	7: 25,
	8: 32,
	9: 40,
	10: 50,
}
```

颜色属性示例：

```gdscript
enum AttackElement {
	POISON,
	CRITICAL,
	FIRE,
}
```

## 等级与字母阶段 / Levels And Letter Stage

- 内部等级仍然使用整数，例如 `1, 2, 3 ... 10, 11, 12`。
- 显示层负责把内部等级转成文本。
- `1-10` 显示数字。
- `11` 开始显示 `A`，`12` 显示 `B`，依次类推。

建议函数：

```gdscript
func get_level_label(level: int) -> String:
	if level <= 10:
		return str(level)
	return char(64 + level - 10)
```

后续需要确认：

- 字母阶段是否只到 `Z`。
- `Z` 后是否继续 `AA, AB`。
- 字母阶段攻击力是继续阶梯增长，还是按倍率增长。
