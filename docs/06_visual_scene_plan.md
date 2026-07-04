# 视觉、场景与 UI 拆分方案 / Visual, Scene, And UI Split Plan

## 主场景层级建议 / Suggested Main Scene Hierarchy

```text
Main
├─ Background
├─ Decor
├─ Loading
├─ MainMenu
├─ Game
│  ├─ BattleLayer
│  │  ├─ MonsterPath
│  │  ├─ MonsterVisualLayer
│  │  ├─ CrystalAnchor
│  │  ├─ CastleAnchor
│  │  └─ WaveLabel
│  ├─ BoardBackdrop
│  ├─ Board
│  ├─ Score
│  ├─ Best
│  ├─ RestartButton
│  ├─ BackButton
│  └─ MergeEffect
└─ Popups
```

## BattleLayer / 战斗层

- 放在 `Game` 下。
- 视觉上位于棋盘背景和方块之间，或棋盘背景后方。
- 不应遮挡棋盘输入。
- 承载怪物路径、怪物显示、城堡耐久、波次提示、水晶锚点。

## MonsterPath / 怪物路径

- 使用 `Path2D`。
- 路径围绕棋盘外圈。
- 在布局时根据棋盘位置和尺寸重新生成。
- 入口在棋盘左上角外侧。
- 终点在入口旁边，接近绕满一圈但不重合。

路径伪代码：

```gdscript
func build_monster_path(board_pos: Vector2, board_size: Vector2) -> void:
	var margin := 42.0
	var left := board_pos.x - margin
	var top := board_pos.y - margin
	var right := board_pos.x + board_size.x + margin
	var bottom := board_pos.y + board_size.y + margin
	var end_offset := 72.0

	var curve := Curve2D.new()
	curve.add_point(Vector2(left, top))
	curve.add_point(Vector2(right, top))
	curve.add_point(Vector2(right, bottom))
	curve.add_point(Vector2(left, bottom))
	curve.add_point(Vector2(left, top + end_offset))
	monster_path.curve = curve
```

## 水晶表现 / Crystal Presentation

- `CrystalAnchor` 可放在棋盘上方、终点附近或棋盘中轴视觉焦点。
- 水晶等级提升时播放升级脉冲。
- 水晶持续攻击时发射低噪声光束或能量弹。
- 水晶颜色可跟随当前最高等级属性，也可以先固定为中性色。

## UI 第一版元素 / First UI Pass

- 城堡耐久显示。
- 当前波次显示。
- 怪物路径。
- 怪物血量或受击反馈。
- 合成攻击飞行特效。
- 水晶等级或水晶升级反馈。

## Web 发布与分段加载 / Web Release And Staged Loading

后续 Web 版本需要避免首屏加载过慢：

- 启动必需资源优先加载。
- 战斗、怪物、弹道、特效资源可延后加载。
- 大图和音频尽量按场景或阶段拆分。
- Loading 层需要能显示真实加载进度或阶段提示。

## 视觉拆分原则 / Visual Split Principles

- 玩法逻辑不直接写视觉动画细节。
- 方块表现放进 `BlockView`。
- 怪物表现放进 `MonsterView`。
- 水晶表现放进 `CrystalView`。
- 弹道表现放进 `ProjectileSystem` / `ProjectileView`。
- 通用反馈放进 `EffectSystem`。
