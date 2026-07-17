# 架构维护与美术特效指南 / Architecture, Art, And Effects Maintenance Guide

> 这份文档是后续维护手册。目标是让你明确知道：每个场景文件负责什么、每个脚本对标哪个系统、替换美术资源应该改哪里、添加特效应该接在哪里。

## 维护信心 / Maintenance Confidence

当前项目已经开始从“所有东西塞在主脚本里”转向“场景和系统分层维护”。这是正确方向。

后续维护可以放心按下面的原则推进：  

- **玩法规则放系统脚本里**，比如棋盘、怪物、波次、城堡耐久、伤害计算。
- **视觉表现放场景和 View 脚本里**，比如怪物外观、城堡 UI、路径箭头、弹道、受击反馈。
- **资源替换优先改场景或资源路径**，不要为了换一张图去改玩法逻辑。
- **新特效优先接到 `EffectSystem` 或 `ProjectileSystem`**，不要塞回 `main_game.gd`。
- **数值优先放 `GameConfig`**，避免在流程里散落魔法数字。

只要保持这些边界，后续换美术、加动画、加特效、调怪物数值，都不会互相拖累。

## 总体架构 / Overall Architecture

当前结构可以理解成三层：

```text
MainGame
├─ Core Merge Layer
│  ├─ block.gd
│  ├─ block_view.tscn
│  └─ board_grid.tscn
├─ Combat Layer
│  ├─ CombatSystem
│  ├─ BattleLayerView
│  ├─ PathSystem
│  ├─ MonsterSystem
│  ├─ WaveSystem
│  ├─ CastleSystem
│  ├─ ProjectileSystem
│  └─ EffectSystem
└─ Config And Data
   ├─ GameConfig
   └─ MergeAttackEvent
```

核心边界：

```text
合成系统只产生合成结果。
战斗系统消费合成结果。
视觉场景只负责表现。
```

这条边界后续一定要守住。它会让项目越来越好维护。

## 场景文件对照表 / Scene File Map

| 场景 | 对标作用 | 主要维护内容 |
| --- | --- | --- |
| `scenes/main.tscn` | 主入口 | 只负责挂载主脚本，不建议堆新子节点。 |
| `scenes/blocks/block_view.tscn` | 方块预览/方块表现入口 | 方块显示、选中预览、后续可扩展数字/字母表现。 |
| `scenes/blocks/board_grid.tscn` | 棋盘预览/棋盘底板 | 棋盘背景、格子预览、编辑器查看用。 |
| `scenes/combat/battle_layer.tscn` | 战斗视觉总层 | 怪物路径、怪物层、弹道层、特效层、城堡、波次 UI、装饰图。 |
| `scenes/combat/monster_path_view.tscn` | 怪物路径显示 | 路径线、方向箭头、入口/终点的路径表现。 |
| `scenes/combat/monster_view.tscn` | 单个怪物外观 | 怪物贴图、血条、状态图标、受击锚点。 |
| `scenes/combat/castle_view.tscn` | 城堡耐久表现 | 城堡图片、耐久 UI、受击闪光。 |
| `scenes/combat/projectile_view.tscn` | 单个弹道表现 | 飞行弹、光点、线条、命中特效锚点。 |
| `scenes/combat/effect_layer.tscn` | 特效承载层 | 飘字、爆点、命中反馈、全局临时特效。 |

## 脚本职责对照表 / Script Responsibility Map

| 脚本 | 对标系统 | 什么时候改 |
| --- | --- | --- |
| `main_game.gd` | 主流程和旧棋盘流程 | 只在接入系统、开始/暂停/重开/结算时改。不要继续堆战斗细节。 |
| `block.gd` | 当前实际方块按钮逻辑 | 改点击、等级显示、选中、抖动、方块贴图时改。 |
| `block_preview.gd` | 方块预览表现 | 改 `block_view.tscn` 的编辑器预览时改。 |
| `board_grid_preview.gd` | 棋盘预览表现 | 改棋盘底板预览时改。 |
| `combat_system.gd` | 战斗总控 | 接合成攻击、协调怪物/波次/城堡/弹道/特效时改。 |
| `battle_layer_view.gd` | 战斗层布局 | 改战斗 UI 位置、路径标记、装饰、波次显示时改。 |
| `path_system.gd` | 路径数据 | 改怪物走法、路径边距、终点位置、路径长度时改。 |
| `battle_path_view.gd` | 路径视觉 | 改路径线、箭头、路径贴图时改。 |
| `monster_system.gd` | 怪物管理 | 改生成、移除、最前方目标选择、清场判断时改。 |
| `monster.gd` | 单个怪物逻辑 | 改血量、移动、受伤、死亡、到终点扣耐久时改。 |
| `monster_view.gd` | 怪物视觉 | 换怪物图片、怪物动画、血条、状态显示时改。 |
| `wave_system.gd` | 波次系统 | 改每波数量、出怪节奏、循环规则时改。 |
| `castle_system.gd` | 城堡耐久逻辑 | 改扣血、回血、失败触发时改。 |
| `castle_view.gd` | 城堡表现 | 换城堡图、耐久条、受击动画时改。 |
| `projectile_system.gd` | 弹道系统 | 加飞弹、光束、连锁、穿透、追踪时改。 |
| `projectile_view.gd` | 单个弹道视觉 | 改弹体形状、飞行视觉、命中收尾时改。 |
| `effect_system.gd` | 通用特效系统 | 加受击、爆炸、飘字、城堡受击、死亡反馈时改。 |
| `chain_bolt.gd` | 连锁电击表现 | 改雷电链路视觉时改。 |
| `game_config.gd` | 全局数值配置 | 改棋盘尺寸、攻击力、怪物数值、波次、城堡耐久时改。 |
| `merge_attack_event.gd` | 合成攻击事件数据 | 合成攻击需要新增字段时改。 |

## 资源目录对照表 / Asset Directory Map

| 资源目录 | 当前作用 | 维护建议 |
| --- | --- | --- |
| `assets/textrues/mian/` | 原主界面、按钮、方块、棋盘资源 | 保留旧资源路径，替换同名图片最稳。 |
| `assets/textrues/bg/` | 背景装饰 | 替换背景和主菜单装饰时看这里。 |
| `assets/UI/loading/` | Loading / 主菜单页面 | 背景、Logo、水晶、数字方块、怪物、PLAY 按钮及其轻量动画资源。 |
| `assets/sliced_20260703_172750/` | 新拆分战斗层素材 | 战斗 UI、怪物、城堡、路径、提示面板优先放这里。 |
| `assets/sound/` | 点击和合成音效 | 后续攻击、命中、死亡、城堡受击音效也建议放这里。 |
| `assets/effest/` | 旧 Cocos 特效资源 | 可以作为视觉参考，Godot 中建议逐步转成场景或脚本特效。 |

## 替换方块美术 / Replacing Block Art

当前方块资源主要来自：

```text
assets/textrues/mian/plate_01_down.png
assets/textrues/mian/plate_01_up.png
...
assets/textrues/mian/plate_10_down.png
assets/textrues/mian/plate_10_up.png
```

维护方式：

1. 如果只是换图，优先保持同名文件替换。
2. 保持 `down` 和 `up` 两套状态图尺寸一致。
3. 如果要增加 11/A、12/B 等字母阶段，需要扩展加载规则和 `GameConfig.get_level_label()` 的显示配套。
4. 如果方块尺寸变化，先改 `GameConfig.BLOCK_SIZE`，再检查棋盘布局和路径边距。
5. 不要在 `CombatSystem` 里处理方块贴图，方块资源只属于棋盘/方块表现层。

涉及文件：

- `scripts/main_game.gd`
- `scripts/block.gd`
- `scripts/block_preview.gd`
- `scripts/game_config.gd`

## 替换怪物美术 / Replacing Monster Art

当前怪物视觉入口：

```text
scenes/combat/monster_view.tscn
scripts/monster_view.gd
```

当前 `monster_view.gd` 会优先尝试加载：

```text
assets/sliced_20260703_172750/monster_green_walk_01.png
assets/sliced_20260703_172750/monster_green_walk_02.png
assets/sliced_20260703_172750/monster_green_walk_03.png
```

不同怪物类型的前缀：

| 怪物类型 | 图片前缀 |
| --- | --- |
| `small` | `green` |
| `medium` | `blue` |
| `large` | `red` |
| 其他 | `yellow` |

维护方式：

1. 替换同名 `monster_*_walk_*.png` 最稳。
2. 如果只有静态图，可以放 `monster_green_idle.png` 这类 idle 图。
3. 如果要新增怪物类型，需要同时改 `GameConfig.MONSTER_CONFIG`、`monster_view.gd` 的 `_prefix_for_type()`、波次配置。
4. 如果怪物体积变化，优先调 `GameConfig.MONSTER_CONFIG` 里的 `scale`。
5. 血条和状态图标属于 `monster_view.gd`，不要放进怪物逻辑脚本。

## 替换战斗层 UI / Replacing Battle UI

战斗层 UI 主要在：

```text
scenes/combat/battle_layer.tscn
scripts/battle_layer_view.gd
```

常见替换：

| 想替换 | 优先位置 |
| --- | --- |
| 波次条 | `battle_layer.tscn` 的 `WaveBanner` 资源 |
| 入口门 | `battle_layer.tscn` 的 `EntranceGate` 资源 |
| 入口文字 | `battle_layer.tscn` 的 `EntranceLabel` 资源 |
| 终点文字 | `battle_layer.tscn` 的 `EndpointLabel` 资源 |
| 提示面板 | `battle_layer.tscn` 的 `TipPanel` / `TipIcon` |
| 云、树、石头装饰 | `battle_layer.tscn` 的 `DecorLayer` 子节点 |
| 位置和布局 | `battle_layer_view.gd` |

维护建议：

- 纯换图优先改场景资源。
- `battle_layer.tscn` 是战斗层手动布局入口。`use_manual_layout=true`（默认）时，入口、出口、城堡、HUD、装饰节点的位置以场景保存值为准，运行时不会被代码覆盖。直接在 Godot 编辑器里拖拽节点即可。
- `BoardGuide` 是编辑器专用棋盘参考框（半透明蓝框），运行时自动隐藏，仅用于对齐参考。
- 以下节点仍由代码控制，不可手拖：`MonsterPathView`、`MonsterLayer`、`ProjectileLayer`、`EffectLayer`（它们需要跟随棋盘坐标或铺满全屏）。
- 改位置、大小、跟随棋盘布局时改 `battle_layer_view.gd`。
- 战斗层节点都应保持 `mouse_filter = IGNORE`，避免挡住棋盘点击。

## 替换城堡和耐久表现 / Replacing Castle And Durability UI

入口：

```text
scenes/combat/castle_view.tscn
scripts/castle_view.gd
scripts/castle_system.gd
```

分工：

- `CastleSystem` 管耐久数值、扣血、回血、归零。
- `CastleView` 管城堡图片、耐久显示、受击表现。
- `battle_layer_view.gd` 管城堡摆放位置。

维护方式：

1. 换城堡图片：优先改 `castle_view.tscn` 中的贴图资源。
2. 改耐久数字/血条样式：改 `castle_view.gd` 或场景子节点。
3. 改初始耐久：改 `GameConfig.MAX_CASTLE_DURABILITY`。
4. 改怪物扣耐久：改 `GameConfig.MONSTER_CONFIG` 的 `durability_damage`。

## 添加合成攻击弹道 / Adding Merge Attack Projectiles

入口：

```text
scripts/combat_system.gd
scripts/projectile_system.gd
scripts/projectile_view.gd
scenes/combat/projectile_view.tscn
```

推荐流程：

1. `main_game.gd` 合成完成后发出 `MergeAttackEvent`。
2. `CombatSystem.handle_merge_attack(event)` 选择目标并计算伤害。
3. `ProjectileSystem.play_merge_attack(event, targets)` 播放弹道。
4. `ProjectileView` 负责单个弹体如何飞。
5. 命中后通知怪物受伤，并交给 `EffectSystem` 播放命中特效。

维护建议：

- 直线飞弹、光球、光束都放在 `ProjectileSystem` / `ProjectileView`。
- 不要把弹道 Tween 写回 `main_game.gd`。
- 多目标攻击可以让 `ProjectileSystem` 为每个目标生成一个 `ProjectileView`。
- 雷电连锁可以复用 `chain_bolt.gd`。

## 添加受击、死亡、爆炸特效 / Adding Hit, Death, And Explosion Effects

入口：

```text
scripts/effect_system.gd
scenes/combat/effect_layer.tscn
scripts/monster_view.gd
scripts/castle_view.gd
```

分工建议：

| 特效类型 | 推荐位置 |
| --- | --- |
| 怪物受击闪白/缩放 | `monster_view.gd` 或 `EffectSystem.play_monster_hit()` |
| 怪物死亡爆炸 | `EffectSystem` |
| 飘血数字 | `EffectSystem` |
| 城堡受击闪光 | `castle_view.gd` 或 `EffectSystem.play_castle_damage()` |
| 合成成功光效 | 现有 `main_game.gd` 可保留，后续可迁到 `EffectSystem` |
| 雷电连锁线 | `chain_bolt.gd` / `ProjectileSystem` |

推荐做法：

1. 需要跟随某个对象的短反馈，可以放对象 View 脚本。
2. 一次性生成的粒子、爆炸、飘字，放 `EffectSystem`。
3. 需要从 A 点飞到 B 点的表现，放 `ProjectileSystem`。
4. 特效结束后要 `queue_free()`，避免节点堆积。

## 添加持续攻击水晶 / Adding The Continuous Attack Crystal

水晶已经落地；以下内容作为结构维护和后续扩展参考：

```text
scenes/combat/crystal_view.tscn
scripts/crystal_system.gd
scripts/crystal_view.gd
```

接入方式：

1. `BattleLayer` 增加 `CrystalAnchor` 或直接实例化 `CrystalView`。
2. `CombatSystem` 创建并持有 `CrystalSystem`。
3. 合成事件进来时，`CrystalSystem` 根据 `event.level` 更新历史最高等级。
4. `CrystalSystem` 按固定间隔请求最靠近终点的怪物。
5. 使用 `ProjectileSystem` 播放水晶弹道。
6. 使用 `EffectSystem` 播放水晶升级和命中特效。

水晶维护原则：

- 水晶是基础战力，不是主输出。
- 水晶等级跟随历史最高等级。
- 水晶伤害、频率、目标数放到 `GameConfig`。
- 水晶外观升级放到 `CrystalView`。

## 修改数值 / Editing Numbers

优先改：

```text
scripts/game_config.gd
```

当前适合放在 `GameConfig` 的内容：

- 棋盘尺寸。
- 方块尺寸。
- 城堡最大耐久。
- 等级基础攻击力。
- 等级颜色属性。
- 怪物血量、速度、尺寸、扣耐久。
- 波次数量和出怪间隔。
- 后续水晶伤害系数和攻击频率。

不要把这些数值散写在：

- `main_game.gd`
- `monster_view.gd`
- `battle_layer_view.gd`
- `projectile_view.gd`

这些文件主要负责流程或表现，不应该成为数值表。

## 常见修改任务速查 / Common Task Cheat Sheet

| 需求 | 改哪里 |
| --- | --- |
| 换 1-10 方块图 | `assets/textrues/mian/plate_*`，必要时改 `block.gd`。 |
| 改方块大小 | `GameConfig.BLOCK_SIZE`，然后检查布局和路径。 |
| 换棋盘底板 | `main_game.gd` 资源表或 `board_grid.tscn` 预览。 |
| 换怪物图 | `assets/sliced_20260703_172750/monster_*` 和 `monster_view.gd`。 |
| 新增怪物类型 | `GameConfig.MONSTER_CONFIG`、`monster_view.gd`、`WaveSystem` 配置。 |
| 改出怪节奏 | `GameConfig.WAVES`。 |
| 改怪物路线 | `path_system.gd`。 |
| 改路径视觉 | `monster_path_view.tscn` / `battle_path_view.gd`。 |
| 换城堡图 | `castle_view.tscn`。 |
| 改城堡耐久 | `GameConfig.MAX_CASTLE_DURABILITY`。 |
| 加合成弹道 | `projectile_system.gd` / `projectile_view.gd`。 |
| 加怪物受击特效 | `effect_system.gd` / `monster_view.gd`。 |
| 加死亡爆炸 | `effect_system.gd`。 |
| 加水晶 | 新增 `crystal_system.gd`、`crystal_view.gd`、`crystal_view.tscn`，由 `CombatSystem` 接入。 |
| 改战斗 UI 位置 | `battle_layer_view.gd`。 |
| 改战斗 UI 图片 | `battle_layer.tscn`。 |

## 修改前检查清单 / Pre-Change Checklist

每次维护前先问这几个问题：

1. 这是玩法规则，还是视觉表现？
2. 如果是玩法规则，是否应该放进系统脚本或 `GameConfig`？
3. 如果是视觉表现，是否应该放进对应 `View` 或场景文件？
4. 这个改动会不会挡住棋盘点击？
5. 这个特效结束后会不会自动清理节点？
6. 重开游戏时，这个系统有没有 reset？
7. 暂停、失败、弹窗时，这个系统会不会继续运行？

## 结论 / Conclusion

后续维护的方向是清楚的：

- `main_game.gd` 只做主流程和旧棋盘桥接。
- `CombatSystem` 是战斗入口。
- `GameConfig` 是数值入口。
- `BattleLayer` 是战斗视觉总入口。
- `ProjectileSystem` 管飞出去的东西。
- `EffectSystem` 管爆出来、闪出来、飘出来的东西。
- 各种 `View` 管自己长什么样。

按这个结构走，后续替换美术资源、加弹道、加怪物受击、加城堡表现、加持续攻击水晶，都是可控的。项目不会越改越乱，它会越来越像一个可以长期维护和扩展的游戏工程。
