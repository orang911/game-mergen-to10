# Web 冒烟测试流程记录 / Web Smoke Test Record

日期：2026-07-08

项目：`game_mergenTo10_published`

归档目的：记录本次 Godot Web 打包、本地冒烟测试、已遇到的问题、处理原则和后续线上测试清单。

## 1. 本次目标

本次 Web 包属于冒烟测试包，不是正式发布包。

主要验证目标：

- Web 导出包可以正常启动。
- 游戏资源可以正常加载。
- 可以进入主菜单和游戏局内。
- 棋盘、路径、怪物、水晶、HUD 层级正常。
- 合成方块正常。
- 合成后可以触发攻击弹道。
- 数字颜色属性弹道和命中特效可以显示。
- 合成攻击行提示横幅正常（五种元素横幅映射正确、基础 ATK 数值对齐、五行位置对齐、上浮淡出动画正常、无目标时仍然显示、restart 后无残留）。
- 本地 HTTP 环境下运行正常。

## 2. 打包输出目录

Web 冒烟包输出目录：

```text
F:\卖肉\godotT10\game_mergenTo10_published\builds\web_smoke\
```

导出入口文件：

```text
builds/web_smoke/index.html
```

Web 包核心文件应包含：

```text
index.html
index.js
index.wasm
index.pck
```

如果 Godot 同时生成以下文件，也需要一起部署：

```text
index.audio.worklet.js
index.worker.js
```

## 3. 本地 Godot CLI 已验证可用

Godot 可执行文件已验证存在：

```text
C:\Users\PC\AppData\Local\Programs\Godot\4.7\godot4_console.exe
```

版本：

```text
4.7.stable.official.5b4e0cb0f
```

导出模板位置：

```text
C:\Users\PC\AppData\Roaming\Godot\export_templates\4.7.stable
```

本地可以执行 parse、主场景运行和临时 Web 导出。仓库构建输出（`builds/`）不纳入验证范围，临时 Web 导出使用系统临时目录。本次状态：

```text
本地 Web 打包测试已成功。
```

## 4. Godot Web 导出要求

项目入口：

```text
F:\卖肉\godotT10\game_mergenTo10_published\project.godot
```

导出路径：

```text
F:\卖肉\godotT10\game_mergenTo10_published\builds\web_smoke\index.html
```

第一轮冒烟推荐配置：

```text
Platform: Web
Runnable: On
Export With Debug: On
Threads: Off
Canvas Resize Policy: Adaptive
```

第一轮建议关闭 Threads，避免线上服务器额外要求：

```text
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

冒烟通过后，再考虑 Debug 关闭、资源压缩、线程开启和缓存策略。

## 5. 本地测试方式

Web 包不能直接双击 `index.html` 作为最终验证方式，需要通过 HTTP 服务访问。

本地测试目录：

```text
F:\卖肉\godotT10\game_mergenTo10_published\builds\web_smoke\
```

本地访问地址示例：

```text
http://localhost:8080
```

本次结果：

```text
本地 Web 测试已成功。
```

## 6. 当前核心玩法验证规则

合成攻击规则已明确为：

```text
source_level = 合成前等级
result_level = 合成后等级
```

本次攻击使用：

```text
攻击属性 = source_level
弹道颜色 = source_level
命中特效 = source_level
属性阶数 = source_level
攻击力 = result_level
生成方块 = result_level
```

示例：

```text
1 + 1 -> 2
本次攻击：Lv1 绿色 poison
生成方块：Lv2 蓝色 2
```

```text
2 + 2 -> 3
本次攻击：Lv2 蓝色 ice
生成方块：Lv3 黄色 3
```

验收重点：

- 不能使用合成后的 `result_level` 决定本次攻击属性。
- 弹道、拖尾、命中特效都必须跟随 `source_level`。
- 新生成方块、水晶最高等级和攻击力成长可以跟随 `result_level`。

## 7. 特效资源接入记录

资源规划目录：

```text
assets/fx/elements/
```

共享拖尾：

```text
assets/fx/elements/shared/trail_soft_white.png
```

命中特效序列帧：

```text
assets/fx/elements/poison/hit_spritesheet.png
assets/fx/elements/ice/hit_spritesheet.png
assets/fx/elements/lightning/hit_spritesheet.png
assets/fx/elements/arcane/hit_spritesheet.png  (used by critical/purple element)
assets/fx/elements/fire/hit_spritesheet.png
```

子弹图片：

```text
assets/fx/elements/poison/projectile_core.png
assets/fx/elements/ice/projectile_core.png
assets/fx/elements/lightning/projectile_core.png
assets/fx/elements/arcane/projectile_core.png  (used by critical/purple element)
assets/fx/elements/fire/projectile_core.png
```

表现分工：

- `projectile_view`：负责子弹本体、拖尾、移动、旋转和到达回调。
- `projectile_system`：负责创建弹道、传入表现参数和命中回调。
- `effect_system`：负责命中特效、状态特效、范围表现和跳字等反馈。
- 伤害、减速、毒伤、弹射等逻辑不放在表现层。

## 8. 当前表现问题记录

已观察到：

- 发射出去的弹体点偏小。
- 飞行拖尾不够明显。

优先调整方向：

```text
core_scale = 1.3
trail_size = 165 x 42
trail_alpha = 0.82
launch_flash = 90 x 90 / 0.12s
min_travel_time = 0.24s
```

处理原则：

- 不优先修改美术源图。
- 先通过 Godot 表现参数调整弹体尺寸、拖尾尺寸、透明度、发射闪光和最短飞行时间。
- 如果表现仍然弱，再考虑补充 `launch_flash` 或更亮的共享拖尾素材。

## 9. 层级问题记录

之前遇到过：

```text
底图放入 BattleLayer 后，合成棋盘被盖住。
```

原因：

```text
BattleLayer 位于 Board 上方，整屏背景图跟随 BattleLayer 一起覆盖了棋盘。
```

修正原则：

```text
BattleBackground 放在 Game 层底部。
BoardBackdrop / Board 放在其上方。
BattleLayer 只负责怪物、水晶、弹道、命中特效、HUD。
```

推荐层级：

```text
BattleBackground
BoardBackdrop
Board
BattleLayer
PopupLayer
```

后续任何整屏底图、路径底图、静态环境图，都不应再放入覆盖棋盘的动态战斗层中。

## 10. 棋盘背板与布局注意事项

棋盘逻辑区域和背板视觉区域应拆开配置。

逻辑棋盘：

```text
5 x 5
单格 118 px
棋盘内容区 590 x 590
```

背板是视觉框，不参与点击和合成逻辑。

当前布局原则：

- 方块尺寸不因背板变化而缩放。
- 背板只调位置和尺寸。
- 背板必须在数字方块下方。
- 背板四周应保留约 30-40 px 视觉留白。
- 水晶底部盾牌不能压住棋盘上边框。

## 11. 线上部署注意事项

服务器 MIME 需要正确：

```text
.wasm -> application/wasm
.pck  -> application/octet-stream
.js   -> application/javascript
.html -> text/html
.png  -> image/png
.jpg  -> image/jpeg
```

线上上传时，必须上传整个 Web 输出目录内容，不能只上传 `index.html`。

如果开启 Web Threads，需要额外配置响应头：

```text
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

第一轮线上冒烟建议继续保持 Threads 关闭。

## 12. 线上冒烟检查清单

- 页面能打开。
- Console 没有 wasm / pck 加载错误。
- 新 LoadingView 背景、Logo、装饰元素和 PLAY 正常显示；淡入与错落浮动完成后可点击 PLAY 进入游戏。
- 返回菜单后 LoadingView 不残留旧进度条、旧 Logo 或重复 Tween。
- 可以开始游戏。
- 棋盘显示正常。
- 路径和怪物显示正常。
- 水晶显示正常。
- 合成方块正常。
- `1 + 1 -> 2` 发绿色 poison 弹道。
- `2 + 2 -> 3` 发蓝色 ice 弹道。
- 紫色弹道（暴击/ critical）命中时有概率触发"暴击!"浮字 + 强化闪光。
- 暴击为即时效果，无持续状态（不同于毒/冰/火）。
- 命中特效透明背景正常，无黑底白底。
- 拖尾显示清楚。
- 合成攻击行提示横幅：五种元素横幅正确显示、基础 ATK 数字对齐、五行位置对齐、上浮淡出动画正常、无目标时仍然显示、restart 后无残留提示。
- 移动端竖屏比例正常。
- 没有关键 UI 被裁切。
- Console 无关键运行错误。

建议记录格式：

```text
URL:
设备:
浏览器:
是否进入游戏:
是否可合成:
弹道颜色是否正确:
命中特效是否正确:
层级是否正确:
Console 报错:
截图:
```

## 13. 下一步计划

下一步进入线上冒烟测试：

```text
1. 上传 builds/web_smoke 全部文件。
2. 检查服务器 MIME。
3. 桌面 Chrome 测试。
4. 手机竖屏测试。
5. 记录 Console 报错和截图。
6. 根据测试结果调整弹道大小、拖尾强度、层级和资源加载问题。
```

后续正式发布前，再补充：

- Debug 关闭后的导出验证。
- 包体大小记录。
- 加载耗时记录。
- 移动端性能记录。
- 缓存刷新策略。
- 资源瘦身清单。
