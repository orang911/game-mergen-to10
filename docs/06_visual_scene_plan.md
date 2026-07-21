# 视觉、场景与 UI 拆分方案 / Visual, Scene, And UI Split Plan

## 主场景层级建议 / Suggested Main Scene Hierarchy

```text
Main
├─ Background
├─ Decor
├─ MainMenu
│  └─ LoadingView
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
- `LoadingView` 负责启动阶段淡入和主菜单展示；真实资源进度接入前，使用约 1.2 秒的阶段动画。

## LoadingView / 启动主菜单

- 场景：`scenes/ui/loading_view.tscn`；脚本：`scripts/loading_view.gd`。
- 资源统一放在 `assets/UI/登录页/`，当前使用完整登录页效果图作为整屏主视觉。
- 设计坐标以效果图原始 `967×1626` 为基准，按视口等比覆盖并居中裁切。
- “开始游戏”是当前唯一可交互元素；账号与设置图标暂时仅作为效果图视觉。
- Logo、水晶、方块、怪物和 PLAY 使用低幅度、不同周期的浮动/呼吸动画；进入游戏或离开菜单时统一清理 Tween。

## 视觉拆分原则 / Visual Split Principles

- 玩法逻辑不直接写视觉动画细节。
- 方块表现放进 `BlockView`。
- 怪物表现放进 `MonsterView`。
- 水晶表现放进 `CrystalView`。
- 弹道表现放进 `ProjectileSystem` / `ProjectileView`。
- 通用反馈放进 `EffectSystem`。

## 合成攻击行提示 / Merge Attack Row Prompt

- `MergeAttackPromptView` 实例化在 `EffectLayer/FloatingText` 下，位于棋盘/弹道之上、HUD 之下，忽略鼠标。
- 横幅尺寸 640×64，在可视棋盘区域水平居中；数字区域为 (435, 3, 160, 58)。
- 逻辑行 y=4..0 分别映射到 941×1672 设计坐标系中的顶部目标值 642, 750, 858, 966, 1074。
- 动画：向上平移 24 px；0.18s 淡入/入场，0.30s 停留，0.27s 淡出。
- 临时节点名称以 `Effect_` 开头，确保 reset/restart 时一次性清理所有实例。
