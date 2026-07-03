# Merge To 10 项目方向记录

> 本文档用于记录这个项目后续开发方向、功能细节、讨论结论和待确认问题。
> 日期：2026-07-02

## 文档用途

- 记录项目当前状态，避免后续讨论时丢失上下文。
- 整理未来开发方向，把想法拆成可执行功能。
- 记录玩法、界面、音效、发布等细节决策。
- 保存待讨论问题，方便之后逐项确认。

## 当前项目状态

项目已经迁移为 Godot 4.x 项目。

主要入口：

- 主场景：`res://scenes/main.tscn`
- 主逻辑：`res://scripts/main_game.gd`
- 方块逻辑：`res://scripts/block.gd`

当前已有玩法：

- 5x5 棋盘。
- 点击相邻同等级方块进行选中。
- 再次点击已选中的方块，将整组方块合并到该方块。
- 合并后目标方块等级 +1。
- 计分公式：`(合并数量 - 1) * 方块等级 * 2`。
- 合并后方块下落，并随机补充新方块。
- 当前最高等级超过 4 后，新方块随机范围提高到 1-4。
- 达到 10 级方块后弹出成功提示，并移除该方块。
- 无可合并方块时进入游戏结束。
- 继续/复活逻辑：清除当前最低等级方块。
- 支持重新开始、返回主菜单、静音、点击音效、合并音效。
- 最高分保存到 `user://merge_to_10.cfg`。

## 未来开发方向

### 0. 合成打怪核心方向

目标：在原有数字合成玩法上加入打怪系统，让棋盘合成不只是得分，而是转化为攻击、防守和生存压力。

核心设定：

- 棋盘仍然位于画面中心，玩家继续通过合成数字元素进行操作。
- 数字不再只是分数等级，而是代表不同成长阶段的攻击强度。
- 等级不止做到 10，10 之后可以用字母继续表示，例如 A、B、C、D、E。
- 等级越高，攻击力越强。
- 攻击属性不一定直接绑定数字或字母，而是可以根据颜色来区分。
- 怪物以队列形式围绕棋盘行进，形成类似环绕棋盘的路径。
- 玩家通过棋盘中的合成行为产生攻击，阻挡或消灭正在前进的怪物队列。
- 当怪物前进到终点位置时，玩家损失血量。
- 游戏目标从单纯追求高分，扩展为“持续合成、持续防守、尽量生存更久”。

### 打怪系统初步结构

#### 怪物队列

- 怪物沿着固定路径移动。
- 路径采用完整环绕棋盘的形式，怪物围着棋盘外圈走一圈，形成持续压迫感。
- 怪物从左上角进入。
- 终点设置在入口旁边，接近绕满一圈但不和入口完全重合。
- 怪物按队列依次出现。
- 怪物生成采用“波次 + 持续混合”的节奏：每波有主题，波内持续出怪。
- 第一版波次主题按数量和大小变化推进：越往后怪物越密集，同时中/大怪比例提高。
- 每波结束条件：该波怪物全部生成完，并且场上怪物清空。
- 第一版只做普通怪，先把系统跑通。
- 怪物外观方向采用抽象几何怪。
- 怪物到达终点时不会只是游戏结束，而是扣除玩家血量。
- 怪物到达终点后扣除玩家耐久并消失。
- 玩家血量归零后进入失败结算。

待讨论：

- 每波持续出怪的间隔。
- 第一版普通怪是否只用大小区分血量和扣耐久。

#### 等级与攻击阶段

- 数字和字母共同构成攻击成长等级。
- 1-10 是基础数字阶段。
- 10 之后进入字母阶段，例如 A、B、C、D、E，并可以继续向后扩展。
- 低等级攻击弱，适合清理普通怪。
- 高等级攻击强，适合对付高血量怪或关键目标。
- 合成后产生的等级越高，攻击力越强。
- 攻击属性主要根据颜色区分，而不是强制每个数字/字母绑定固定属性。
- 高阶等级越多，攻击力肯定越强，形成长期成长追求。

初步理解：

| 等级阶段 | 攻击定位 |
| --- | --- |
| 1-3 | 基础攻击阶段 |
| 4-6 | 稳定输出阶段 |
| 7-10 | 强化输出阶段 |
| A-C | 高级攻击阶段 |
| D 及以上 | 高阶爆发阶段 |

待讨论：

- 10 之后的字母阶段具体开放到哪里。
- 数字到字母的显示规则，例如 10 之后是 A，还是 11 显示为 A。
- 等级攻击力和颜色属性之间如何组合。
- 攻击目标是最近的怪物、最前方怪物、随机怪物，还是玩家可指定。

#### 颜色属性

目标：等级负责攻击力成长，颜色负责攻击属性区分。

已确定基础颜色属性：

| 颜色 | 属性 | 效果方向 |
| --- | --- | --- |
| 红色 | 火焰 | 持续伤害 |
| 蓝色 | 冰冻 | 停止怪物 |
| 黄色 | 雷电 | 连锁攻击 |
| 绿色 | 毒 | 持续伤害 |

说明：

- 红色和绿色都属于持续伤害，但表现可以不同。
- 红色火焰更偏直接灼烧，适合短时间高持续伤害。
- 绿色毒更偏慢性消耗，适合长时间叠加或削弱怪物。
- 蓝色冰冻用于控制怪物前进。
- 黄色雷电用于在怪物队列中连锁跳转。

当前 1-10 素材颜色观察：

| 等级 | 当前颜色观察 | 可对应属性倾向 |
| --- | --- | --- |
| 1 | 亮绿色 | 毒 |
| 2 | 青蓝色 | 归并到冰冻 |
| 3 | 金黄/橙黄 | 归并到雷电 |
| 4 | 橙色 | 归并到火焰 |
| 5 | 红色 | 火焰 |
| 6 | 绿色 | 毒 |
| 7 | 蓝色 | 冰冻 |
| 8 | 紫色 | 归并到毒 |
| 9 | 紫红色 | 归并到雷电 |
| 10 | 黄色 | 雷电 |

设计原则：

- 等级颜色基本按照当前素材 1-10 的顺序来，不优先重排已有颜色。
- 属性设计需要顺着现有颜色做解释，让玩家看到颜色时能自然理解攻击效果。
- 10 之后的字母阶段可以继续沿用或扩展这套颜色顺序。
- 第一版只保留四大基础属性：火焰、冰冻、雷电、毒。
- 青蓝、橙、紫、紫红等颜色暂时归并到四大基础属性，不单独设计新属性。
- 后续如果玩法需要，可以再把紫色、紫红色等扩展成独立高级属性。

待讨论：

- 字母阶段是否继续使用四大基础属性循环。

#### 攻击触发

已确定方向：

- 攻击以“合成后一次性触发”为核心。
- 每次成功合成时，立刻释放一次攻击，不让棋盘上的方块持续自动攻击。
- 这里的混合感主要来自怪物队列、数字攻击属性、道具触发和技能释放，而不是方块持续攻击。
- 以“合成产生攻击”为核心，让玩家的棋盘操作直接影响战斗。
- 高等级代表更强攻击阶段，形成从数字到字母的长期成长感。
- 一次性攻击优先攻击最靠近终点的怪物，优先处理当前最危险目标。
- 合成数量越多，攻击伤害越高。
- 合成数量越多，攻击目标数量也越多。
- 等级决定基础攻击力，颜色决定攻击属性，合成数量决定本次攻击的威力和覆盖范围。

待讨论：

- 多目标攻击时，是否从最靠近终点的怪物开始依次向后选择。
- 不同颜色属性的一次性攻击具体是单体高伤害、范围、穿透、爆炸、减速，还是其他效果。

#### 合成攻击数值

第一版使用阶梯式基础攻击力，让低等级较弱，高等级明显变强。

基础攻击力：

| 等级 | 基础攻击力 |
| --- | --- |
| 1 | 2 |
| 2 | 4 |
| 3 | 6 |
| 4 | 10 |
| 5 | 14 |
| 6 | 18 |
| 7 | 25 |
| 8 | 32 |
| 9 | 40 |
| 10 | 50 |

合成数量加成：

- 每多合成 1 个方块，伤害增加 20%。
- 计算理解：2 个方块合成是基础伤害，3 个方块为 `基础伤害 * 1.2`，4 个方块为 `基础伤害 * 1.4`。

攻击目标数量：

- `目标数 = 合成数量 - 1`。
- 2 个方块合成攻击 1 个目标。
- 4 个方块合成攻击 3 个目标。

待讨论：

- 伤害是否取整。
- 多目标攻击是每个目标都吃完整伤害，还是伤害在多个目标之间递减。
- 字母阶段 A、B、C、D、E 的基础攻击力如何继续增长。

#### 触发性道具

目标：加入以攻击增强为主的触发道具，让战斗出现短时爆发和策略选择。

候选效果：

- 攻击增强：短时间提高所有攻击伤害。
- 暴击触发：下一次合成攻击造成额外伤害。
- 范围爆炸：下一次攻击对一片怪物造成伤害。
- 穿透攻击：攻击命中多个队列中的怪物。
- 减速效果：让路径上的怪物短时间变慢。
- 冻结效果：让怪物短暂停止前进。
- 连锁攻击：击败怪物后伤害跳转到下一个怪物。
- 高等级增幅：只增强 7-10 阶段的攻击，强化后期爆发。

待讨论：

- 道具采用“小道具自动触发，大技能主动释放”的混合方式。
- 小道具的自动触发条件。
- 大技能的获得方式和释放入口。
- 道具是棋盘上随机出现，还是通过合成、击杀、关卡奖励获得。
- 道具是否占用棋盘格。
- 道具是否和数字方块合成产生特殊效果。

#### 玩家血量

- 玩家生命表现为“城堡耐久”，不优先使用普通数字血条。
- 初始城堡耐久为 20，整体偏休闲。
- 怪物到达终点时扣除城堡耐久。
- 怪物按大小扣除不同耐久，例如 1/2/3。
- 城堡耐久归零后游戏结束。

待讨论：

- 小/中/大怪分别扣 1/2/3 耐久，还是需要进一步微调。
- 是否存在回血道具。
- 游戏结束是否仍然保留原有复活机制。

#### 普通怪数值

第一版普通怪只用大小区分强度。

| 怪物大小 | 血量 | 到达终点扣除耐久 |
| --- | --- | --- |
| 小怪 | 5 | 1 |
| 中怪 | 12 | 2 |
| 大怪 | 25 | 3 |

### 1. 玩法体验优化

目标：让核心合并过程更清晰、更有反馈、更耐玩。

可讨论方向：

- 合并动画是否需要更顺滑，尤其是多个方块连续移动时。
- 选中同色组时是否需要更明显的边框、闪光或轻微放大。
- 点击单个无法合并方块时，是否只抖动，还是给出更明确提示。
- 达成 10 以后是否继续以 10 为目标，还是进入更高数字挑战。
- 复活规则是否保留为“清除最低等级”，或改成广告/道具式机制。

### 2. 关卡与难度

目标：让游戏有长期目标，而不是只有单局分数。

可讨论方向：

- 增加关卡目标，例如达到指定数字、获得指定分数、限定步数。
- 增加每日挑战或固定随机种子的挑战局。
- 根据玩家进度逐渐改变新方块生成范围。
- 增加障碍块、锁定块、特殊块等元素。
- 设置不同棋盘尺寸，例如 5x5、6x6 或挑战模式。

### 3. 道具系统

目标：增加策略选择，减少无解时的挫败感。

候选道具：

- 刷新：重新随机若干方块。
- 锤子：移除一个指定方块。
- 升级：让一个方块等级 +1。
- 降级：让一个方块等级 -1。
- 洗牌：重排当前棋盘上的方块。
- 提示：高亮当前可合并的最大组。

待确认：

- 道具是局内免费获得，还是通过奖励、金币、广告获得。
- 每局道具数量是否限制。
- 道具是否影响最终分数或排行榜。

### 4. 分数与奖励

目标：让玩家明确感受到每次合并的收益。

可讨论方向：

- 大组合并时增加额外连击奖励。
- 连续合并高等级方块时增加倍率。
- 达成新最高数字时给一次额外奖励。
- 游戏结束界面显示本局最高方块、最大连击、合并次数。
- 最高分之外增加更多统计数据。

### 5. 界面与视觉

目标：保留原项目风格，同时让 Godot 版本更清晰、更现代。

可讨论方向：

- 主菜单、加载页、棋盘界面是否继续沿用原素材。
- 游戏结束弹窗是否补齐统一的按钮图片风格。
- 分数、最高分、按钮位置是否适配更多屏幕比例。
- 成功弹窗、游戏结束弹窗是否需要更完整的动画。
- 静音按钮是否需要区分音乐和音效。

### 6. 音效与手感

目标：提升点击、合并、成功、失败等关键反馈。

可讨论方向：

- 点击音和合并音是否保留当前素材。
- 合并不同等级时是否使用不同音高或不同音效。
- 达成 10、刷新、复活、失败是否增加独立音效。
- 是否增加背景音乐。
- 静音设置是否需要保存。

### 7. 存档与数据

目标：记录玩家长期进度。

当前已有：

- 最高分保存。

未来可增加：

- 总局数。
- 总合并次数。
- 达成过的最高等级。
- 道具数量。
- 设置项保存，例如静音状态、语言、震动。
- 关卡进度。

### 8. 发布与平台

目标：明确游戏未来主要发布环境。

已确定：

- 目标平台优先为 Web。
- 需要考虑浏览器加载体验、资源分段、移动端竖屏适配、音频解锁和缓存版本。

待讨论：

- 是否需要移动端触摸适配。
- 是否需要横屏/竖屏固定。
- 是否需要广告、内购、排行榜、成就系统。
- 是否保留原 Cocos 资源目录，或逐步整理成 Godot 原生资源结构。

## 功能细节记录

### 棋盘

- 当前尺寸：5x5。
- 方块显示尺寸：`132x132`。
- 棋盘坐标使用 `Vector2i(x, y)`。
- 当前显示位置中，`y = 0` 是底部行。

### 方块选择

- 玩家点击一个方块后，会递归选择上下左右相邻的同等级方块。
- 只有同等级且相邻的方块会被选中。
- 如果只选中 1 个方块，则取消选中并播放抖动反馈。
- 10 级及以上方块当前不能继续被选中合并。

### 合并

- 玩家再次点击已选中的目标方块进行合并。
- 被合并方块向目标方块移动并消失。
- 目标方块等级 +1。
- 分数根据合并数量和旧等级计算。
- 合并完成后触发下落和补充。

### 下落与补充

- 每一列从底部向上压实。
- 空位补充随机新方块。
- 初期新方块等级范围是 1-3。
- 当前最高等级超过 4 后，新方块等级范围是 1-4。

### 失败判定

- 如果棋盘上没有任何上下左右相邻的同等级方块，则游戏结束。
- 10 级及以上方块不参与可合并判定。

### 复活

- 当前复活方式：清除棋盘上最低等级的所有方块。
- 清除后执行下落和补充。
- 如果仍然无可合并方块，会再次进入失败状态。

## 技术实现计划

本章节用于记录打怪版本的具体实现方案。原则是先保留现有合成核心，再在外层增加战斗系统，避免一次性重写全部逻辑。

### 总体架构

实现思路：

- 保留现有 `main_game.gd` 里的棋盘、选择、合成、下落、补充流程。
- 战斗系统从一开始拆成独立脚本，减少和棋盘逻辑直接混在一起。
- 合成完成后，由棋盘逻辑发出一次“合成攻击事件”，战斗系统根据事件计算伤害和目标。
- 怪物移动、波次生成、城堡耐久、攻击表现、属性效果尽量独立管理。

建议模块：

- `BoardSystem`：棋盘状态、选中、合成、下落、补充。
- `CombatSystem`：接收合成事件，计算攻击目标、伤害和属性效果。
- `MonsterPath`：记录怪物环绕路径和路径进度。
- `MonsterManager`：生成、更新、移除怪物。
- `WaveManager`：管理波次配置、出怪节奏和每波结束条件。
- `CastleSystem`：管理城堡耐久、扣耐久和失败。
- `EffectSystem`：播放攻击、受击、属性、死亡等视觉反馈。
- `ItemSystem`：后续管理自动小道具和主动大技能。

第一版允许棋盘系统暂时保留在 `main_game.gd` 中，但战斗相关逻辑需要从开始就拆出去，避免后续重构成本过高。

### 长期系统拆分目标

目标：先整理结构，不急于改变现有玩法表现。系统之间通过事件和配置连接，避免棋盘、战斗、动画、音效互相污染。

#### BoardSystem / 棋盘系统

职责：

- 管理 5x5 棋盘数据。
- 管理方块生成、坐标、下落、补充。
- 保留当前棋盘玩法规则。
- 不直接管理战斗，不直接攻击怪物。

实现思路：

- 后续从 `main_game.gd` 中抽出棋盘数据和棋盘操作。
- 对外提供棋盘查询、重置、生成、下落、补充等接口。
- 合成系统需要棋盘数据时，通过接口访问，不直接改内部数组。

#### MergeSystem / 合成系统

职责：

- 只处理选中、合成、计分和合成结果。
- 合成成功后只发出事件，例如等级、合成数量、起点位置。
- 不直接攻击怪物，不直接选择怪物。

实现思路：

- 从当前 `select_next_blocks()`、`merge_selected_blocks()`、`_refresh_score()` 等逻辑中逐步抽离。
- 合成成功后创建 `MergeAttackEvent`。
- 通过信号或主流程把事件交给 `CombatSystem`。

#### BlockView / 方块表现

职责：

- 管理方块颜色、数字/字母显示、选中状态。
- 管理抖动、缩放、合成移动动画。
- 以后升级视觉时，不污染合成规则。

实现思路：

- 当前 `block.gd` 可以逐步向 `BlockView` 职责靠拢。
- 逻辑状态和视觉状态尽量分开，例如 `level` 是数据，贴图、文字、动画是表现。
- 字母阶段显示可以调用 `GameConfig.get_level_label(level)`。

#### CombatSystem / 战斗总控

职责：

- 接收合成事件。
- 计算伤害、目标数量、属性。
- 调用怪物、弹道、特效系统。

实现思路：

- `CombatSystem` 不负责棋盘合成。
- `CombatSystem` 负责把一次 `MergeAttackEvent` 转成一组战斗行为。
- 第一版已经建立 `combat_system.gd` 作为入口。

#### ProjectileSystem / 弹道系统

职责：

- 管理攻击从棋盘飞向怪物的过程。
- 后续支持直线、弧线、连锁、穿透、爆炸、追踪。
- 必须单独拆，避免动画流程把战斗数值逻辑搅乱。

实现思路：

- 第二阶段先实现简单直线弹道或瞬时命中特效。
- 后续属性扩展时，雷电连锁、爆炸范围、追踪弹都放在这里管理表现。
- 弹道命中后可以通知 `CombatSystem` 或直接触发目标受击表现，但最终伤害结算仍由战斗逻辑控制。

#### MonsterSystem / 怪物系统

职责：

- 管理怪物生成、移动、血量、死亡、到终点扣耐久。
- 怪物路径和怪物个体最好分开。

实现思路：

- 由 `MonsterManager` 或后续 `MonsterSystem` 维护怪物列表。
- 怪物个体只管理自己的血量、状态、显示和死亡。
- 到达终点时发出事件，由城堡系统扣耐久。

#### PathSystem / 路径系统

职责：

- 管理围绕棋盘的固定回形 `Path2D`。
- 根据棋盘位置重新计算路径。
- 不管理怪物血量，也不管理波次。

实现思路：

- 第一阶段可以先由 `CombatSystem.layout_for_board()` 或 `MonsterManager` 创建路径。
- 后续独立成 `path_system.gd`。
- 对外提供路径、入口位置、终点判断和 `progress_ratio` 查询辅助。

#### WaveSystem / 波次系统

职责：

- 控制每波怪物数量、类型、间隔、结束判断。
- 后续难度成长也放这里。

实现思路：

- 第一阶段使用配置表驱动。
- 每波生成一个出怪队列。
- 出怪队列为空且场上怪物清空后进入下一波。

#### EffectSystem / 特效系统

职责：

- 管理合成光效、受击闪烁、死亡爆裂、属性特效、飘字。
- 只负责表现，不负责数值。

实现思路：

- 第一版已经建立 `effect_system.gd` 占位。
- 后续所有视觉反馈都尽量通过它统一调用。
- 受击、死亡、属性状态可以由战斗或怪物系统发事件给它播放。

#### AudioSystem / 音效系统

职责：

- 管理点击、合成、攻击、命中、死亡、失败、成功音效。
- 后续支持静音、音量、音乐/音效分离。

实现思路：

- 当前音效仍在 `main_game.gd` 中。
- 后续可以抽出 `audio_system.gd`，保留 `_play_click()`、`_play_merge()` 的兼容入口。
- 音乐和音效分开保存设置。

#### GameStateSystem / 游戏状态

职责：

- 管理开始、暂停、游戏中、结算、复活、重开。
- 重点解决以后“棋盘无可合并”和“城堡耐久归零”两个失败来源的冲突。

实现思路：

- 当前 `GameStatus` 在 `main_game.gd` 中。
- 后续独立管理状态转换。
- 棋盘失败和城堡失败都应走同一个失败入口，但失败原因可记录不同。

#### Config / 数值配置

职责：

- 管理等级攻击力、颜色属性、怪物血量、波次配置、道具效果。
- 避免把平衡数值写死在流程脚本里。

实现思路：

- 第一版已经建立 `game_config.gd`。
- 后续继续把怪物配置、波次配置、道具配置移入配置层。
- 调平衡时优先改配置，不改流程代码。

### 当前结构拆分进度

已完成方向：

- 已经按“先整理结构、不改现有玩法”的方向做了第一步。
- 当前新增的战斗相关脚本是空实现或轻接入，不应该改变原有合成、下落、成功、失败、复活表现。

当前新增文件：

| 文件 | 当前状态 |
| --- | --- |
| `res://scripts/game_config.gd` | 已新增。统一放棋盘尺寸、存档路径、等级攻击力、颜色属性、伤害计算、目标数量计算。 |
| `res://scripts/merge_attack_event.gd` | 已新增。合成后生成的攻击事件数据，包含等级、属性、合成数量、起点、伤害、目标数量。 |
| `res://scripts/combat_system.gd` | 已新增。战斗系统入口，目前接收合成事件，并调用弹道/特效占位系统。 |
| `res://scripts/projectile_system.gd` | 已新增。弹道系统占位，目前提供 `reset()` 和 `play_merge_attack()`。 |
| `res://scripts/effect_system.gd` | 已新增。特效系统占位，目前提供 `reset()` 和 `play_merge_feedback()`。 |

`main_game.gd` 当前接入点：

- 创建并持有 `CombatSystem`。
- 开局、重开、返回、失败、复活时同步调用 `CombatSystem` 的开始或停止。
- `_layout_scene()` 时把棋盘位置和尺寸传给 `combat_system.layout_for_board(board_pos, board_size)`。
- 合成完成、等级提升后创建 `MergeAttackEvent`，交给 `combat_system.handle_merge_attack(attack_event)`。
- 当前 `CombatSystem` 仍是空表现接入，所以原有玩法表现应该保持不变。

当前检查记录：

- 已做静态检查，没有发现冲突标记或明显引用问题。
- 当前环境命令行找不到 Godot，尚未完成 Godot 真实解析/启动检查。

下一步建议：

- 先打开 Godot 跑主场景，确认当前空实现接入没有报错。
- 如果无报错，继续接第一阶段怪物路径。
- BoardSystem / MergeSystem 可以后续拆，但不建议在怪物路径第一阶段前大拆，避免同时改动过多。

### 数据结构

实现思路：

- 用表驱动方式记录等级、颜色属性、攻击力、怪物数值和波次配置。
- 避免把大量数值写死在流程代码里，方便后续调整。

建议数据：

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

```gdscript
enum AttackElement {
	POISON,
	FREEZE,
	LIGHTNING,
	FIRE,
}
```

```gdscript
const LEVEL_ELEMENT := {
	1: AttackElement.POISON,
	2: AttackElement.FREEZE,
	3: AttackElement.LIGHTNING,
	4: AttackElement.FIRE,
	5: AttackElement.FIRE,
	6: AttackElement.POISON,
	7: AttackElement.FREEZE,
	8: AttackElement.POISON,
	9: AttackElement.LIGHTNING,
	10: AttackElement.LIGHTNING,
}
```

### 等级与字母阶段

实现思路：

- 内部等级仍然使用整数，例如 `1, 2, 3 ... 10, 11, 12`。
- 显示层负责把内部等级转成文本。
- `1-10` 显示数字，`11` 开始显示 `A`，`12` 显示 `B`，依次类推。
- 攻击力表先实现 `1-10`，字母阶段先保留扩展接口。

建议函数：

```gdscript
func get_level_label(level: int) -> String:
	if level <= 10:
		return str(level)
	return char(64 + level - 10)
```

待确认：

- 字母阶段是否只到 `Z`，还是 `Z` 后继续 `AA, AB`。
- 字母阶段攻击力是继续阶梯增长，还是按固定倍率增长。

### 颜色属性系统

实现思路：

- 方块的颜色属性从等级映射表读取。
- 攻击时同时传入 `level` 和 `element`。
- 第一版只实现四种属性：火焰、冰冻、雷电、毒。
- 属性效果先做轻量版本，保证可玩后再调表现和数值。

第一版属性实现建议：

- 火焰：命中后附加短时间持续伤害。
- 冰冻：命中后让怪物停止移动一小段时间。
- 雷电：命中后向后续怪物跳转连锁伤害。
- 毒：命中后附加较长时间持续伤害。

技术注意：

- 怪物需要维护状态列表，例如 `burn_time`、`poison_time`、`freeze_time`。
- 持续伤害由怪物自身在 `_process(delta)` 或统一管理器里结算。
- 冰冻只影响移动速度，不影响被攻击和死亡判定。

### 合成攻击事件

实现思路：

- 在 `merge_selected_blocks(clicked)` 完成等级提升后，生成一次攻击事件。
- 攻击事件应包含：合成后的等级、颜色属性、合成数量、目标格位置、基础伤害、目标数量。
- 战斗系统只接收攻击事件，不直接关心棋盘如何选择和合成。

建议事件数据：

```gdscript
var attack_event := {
	"level": clicked.level,
	"element": get_element_for_level(clicked.level),
	"merge_count": merged_count,
	"origin": board_layer.global_position + clicked.position,
}
```

流程：

1. 玩家合成方块。
2. 目标方块等级提升。
3. 根据新等级和合成数量创建攻击事件。
4. 战斗系统选择最靠近终点的怪物。
5. 对目标怪物造成伤害和属性效果。
6. 播放攻击飞行、命中、死亡反馈。

待确认：

- 攻击使用合成前等级还是合成后等级。当前建议使用合成后等级，反馈更爽。

### 合成攻击数值

实现思路：

- 基础攻击力来自 `LEVEL_ATTACK`。
- 合成数量伤害加成：从 2 个开始算基础伤害，每多 1 个增加 20%。
- 攻击目标数：`merge_count - 1`。

建议函数：

```gdscript
func calculate_attack_damage(level: int, merge_count: int) -> float:
	var base_damage: float = float(LEVEL_ATTACK.get(level, 50))
	var bonus: float = 1.0 + max(0, merge_count - 2) * 0.2
	return base_damage * bonus
```

```gdscript
func calculate_target_count(merge_count: int) -> int:
	return max(1, merge_count - 1)
```

待确认：

- 多目标攻击是每个目标吃完整伤害，还是后续目标递减。
- 伤害内部是否保留小数，UI 是否只显示整数。

### 攻击目标选择

实现思路：

- 每个怪物维护一个路径进度值 `path_progress`，范围可以是 `0.0-1.0`，越接近 `1.0` 越接近终点。
- 攻击时从存活怪物中筛选，按 `path_progress` 从大到小排序。
- 取前 `target_count` 个怪物作为攻击目标。

建议函数：

```gdscript
func get_front_targets(target_count: int) -> Array:
	var candidates := monsters.filter(func(monster): return monster.is_alive())
	candidates.sort_custom(func(a, b): return a.path_progress > b.path_progress)
	return candidates.slice(0, target_count)
```

技术注意：

- 如果场上怪物少于目标数，就只攻击现有怪物。
- 怪物死亡后要从怪物列表中移除，避免被后续攻击重复选中。
- 后续如果做属性克制，可以在目标选择前增加过滤规则。

### 怪物路径

实现思路：

- 怪物路径使用固定回形路径。
- 不采用自由自定义路径点作为主要方案。
- 入口在左上角。
- 终点在入口旁边，接近绕满一圈但不完全重合。
- 回形路径围绕棋盘外圈，形成明确的前进队列和防守压力。

建议路径结构理解：

```gdscript
enum PathSide {
	TOP,
	RIGHT,
	BOTTOM,
	LEFT,
}
```

技术方案：

- 第一版建议使用 Godot 的 `Path2D + PathFollow2D` 实现固定回形路径。
- 路径曲线在场景中固定配置，怪物沿 `PathFollow2D.progress` 前进。
- 如果需要更精确地排序和路径进度，可以怪物自己保存 `distance_on_path`。
- `path_progress = PathFollow2D.progress_ratio`，用于判断怪物是否接近终点。

推荐：

- 第一版使用固定 `Path2D` 回形路径。
- 怪物节点可以作为 `PathFollow2D` 的子节点，或由怪物脚本持有对应的 `PathFollow2D`。
- 攻击目标排序直接使用 `progress_ratio`，数值越大越接近终点。

### 怪物节点

实现思路：

- 抽象几何怪可以先用 `Polygon2D`、`ColorRect`、`TextureRect` 或简单 `Control` 节点实现。
- 小/中/大怪共用一个脚本，通过配置决定大小、血量、速度、扣耐久。

建议字段：

```gdscript
var max_hp: float
var hp: float
var armor_damage: int
var speed: float
var path_distance: float
var path_progress: float
var freeze_time: float
var burn_time: float
var poison_time: float
```

建议方法：

- `setup(monster_config)`
- `apply_damage(amount, element)`
- `apply_status(element)`
- `update_movement(delta)`
- `die()`
- `reach_goal()`

### 波次系统

实现思路：

- 使用波次配置数组控制每波的小/中/大怪数量、生成间隔和速度。
- 第一版波次按数量递增和大小比例变化。
- 每波开始后按间隔持续生成怪物。
- 每波结束条件：该波全部生成完，并且场上怪物清空。

建议配置：

```gdscript
const WAVES := [
	{"small": 6, "medium": 0, "large": 0, "spawn_interval": 1.0},
	{"small": 8, "medium": 2, "large": 0, "spawn_interval": 0.9},
	{"small": 10, "medium": 4, "large": 1, "spawn_interval": 0.8},
]
```

技术注意：

- 波次配置不要写死在生成流程里。
- 每波可以先生成一个待出怪队列，例如 `["small", "small", "medium"]`。
- 出怪队列为空且 `monsters.size() == 0` 时进入下一波。

### 城堡耐久

实现思路：

- 新增 `castle_durability`，初始值为 20。
- 怪物到达终点时调用 `damage_castle(amount)`。
- 扣耐久后怪物消失。
- 耐久归零时进入游戏结束。

建议字段：

```gdscript
const MAX_CASTLE_DURABILITY := 20
var castle_durability := MAX_CASTLE_DURABILITY
```

建议函数：

```gdscript
func damage_castle(amount: int) -> void:
	castle_durability = max(0, castle_durability - amount)
	_update_castle_ui()
	if castle_durability <= 0:
		end_game(false)
```

UI 表现：

- 第一版可以用城堡图标 + 耐久数字，或分段耐久条。
- 后续再替换成更像“城堡受损”的视觉表现。

### 道具和技能

实现思路：

- 第一版战斗跑通后再接道具，避免同时引入太多变量。
- 小道具自动触发，大技能主动释放。
- 道具效果应该复用攻击事件或状态系统，不另起一套伤害逻辑。

建议优先级：

1. 自动小道具：下一次合成伤害增强。
2. 自动小道具：随机冻结最前方怪物。
3. 主动大技能：对最靠近终点的一批怪造成伤害。
4. 主动大技能：全路径减速或冻结。

技术注意：

- 道具效果可以作为 `CombatModifier` 存储，例如伤害倍率、额外目标数、附加属性。
- 主动技能需要 UI 入口、冷却或能量值。

### UI 改造

实现思路：

- 棋盘保持在中间。
- 怪物路径围绕棋盘外圈。
- 城堡耐久放在顶部或终点附近，和怪物终点建立视觉联系。
- 波次信息可以显示为 `Wave 1` 或简洁图标。
- 攻击反馈需要清楚表现“从合成方块打向怪物队列”。

第一版 UI 元素：

- 城堡耐久显示。
- 当前波次显示。
- 怪物路径。
- 怪物血量或受击反馈。
- 合成攻击飞行特效。

技术注意：

- 当前界面布局大多在 `main_game.gd` 中手写，需要给棋盘外圈预留怪物路径空间。
- 移动端竖屏下，怪物路径不能遮挡棋盘点击区域。
- 攻击特效可以先用简单线条、光点或缩放动画，后续再换素材。

### Web 发布与分段加载

目标：游戏需要发布为 Web 格式，因此第一版就要考虑浏览器加载体验、资源体积、首屏速度、移动端兼容和缓存策略。

核心原则：

- Web 版本首屏要尽快进入加载页，不让玩家长时间看到空白页面。
- 游戏资源按阶段加载，不把所有未来内容一次性塞进首包。
- 加载过程要有明确进度反馈。
- 核心玩法资源优先加载，扩展内容、后续波次、额外特效和音频可以延后。
- Web 发布包要避免无用旧资源进入导出结果。

#### Web 导出目标

发布形态：

- 目标平台：Web。
- 运行环境：桌面浏览器和移动浏览器。
- 画面方向：优先竖屏适配。
- 输入方式：鼠标点击和触摸点击都要可用。

第一版要求：

- 能通过 Godot Web 导出运行主场景。
- 游戏启动后显示加载页。
- 加载完成后进入主菜单。
- 进入游戏后核心合成玩法和第一阶段怪物系统可运行。
- 浏览器刷新后不会产生异常状态。

#### 分段加载阶段

建议把加载拆成 4 个阶段。

| 阶段 | 名称 | 内容 | 目标 |
| --- | --- | --- | --- |
| 0 | 引擎与启动壳 | Godot Web 引擎、HTML 壳、最小启动脚本 | 尽快显示页面和加载界面 |
| 1 | 首屏必需资源 | 加载页、主菜单背景、Logo、开始按钮、基础音效占位 | 尽快进入主菜单 |
| 2 | 核心玩法资源 | 棋盘、1-10 方块、基础 UI、合成音效、主游戏脚本 | 保证玩家能开始一局 |
| 3 | 战斗基础资源 | 怪物基础形状、路径、城堡耐久 UI、波次配置、基础特效 | 支持第一阶段打怪闭环 |
| 4 | 延后扩展资源 | 高级特效、更多怪物外观、字母阶段素材、道具技能、大音频 | 后续按需加载 |

第一版可以先做到阶段 0-3，阶段 4 作为后续扩展预留。

#### 首屏加载机制

实现思路：

- 保留当前加载页，但加载进度不只做假的 tween，后续要接真实资源加载进度。
- Web 首屏只加载能显示加载页和主菜单的资源。
- 主菜单显示后，再准备游戏局内资源。

当前项目现状：

- 现在 `show_loading()` 通过 tween 模拟加载进度。
- 后续 Web 版本需要把模拟进度改为“真实加载 + 最小展示时间”的混合方案。

建议规则：

- 如果真实加载很快，加载页至少显示短暂时间，避免闪屏。
- 如果真实加载较慢，进度条反映真实阶段。
- 加载失败时显示重试提示，而不是卡死。

#### Godot 资源加载实现

实现思路：

- 第一版仍可使用预加载和普通 `load()`，保证稳定。
- 当资源体积变大后，改为 `ResourceLoader.load_threaded_request()` 做异步加载。
- 将资源路径按阶段整理成数组或配置表。

建议结构：

```gdscript
const LOAD_GROUPS := {
	"menu": [
		"res://assets/textrues/bg/bg_01.jpg",
		"res://assets/textrues/mian/logo.png",
		"res://assets/textrues/mian/play.png",
	],
	"game_core": [
		"res://assets/textrues/mian/plate_01_down.png",
		"res://assets/textrues/mian/plate_01_up.png",
	],
	"combat_core": [
		"res://scenes/monster.tscn",
	],
}
```

建议新增系统：

- `loading_system.gd`
- 职责：按组加载资源、记录加载进度、通知 UI 更新、处理失败和重试。

建议接口：

```gdscript
signal group_progress(group_name: String, progress: float)
signal group_loaded(group_name: String)
signal all_loaded
signal load_failed(path: String)

func load_group(group_name: String) -> void
func load_groups(group_names: Array[String]) -> void
func get_progress() -> float
func is_group_loaded(group_name: String) -> bool
```

#### 资源分包策略

第一版资源分类：

- 首包：引擎、主场景、加载页、主菜单最低资源。
- 核心包：棋盘、方块、基础按钮、必要音效。
- 战斗包：怪物、路径、城堡 UI、波次配置。
- 扩展包：高级特效、字母阶段素材、道具、更多音效和音乐。

实现要求：

- `assets/textrues/` 中没有用到的旧资源不要进入 Web 导出。
- Cocos 旧目录继续通过 `.gdignore` 或导出规则排除。
- 大图、音频、未来素材优先放入延后加载组。
- 第一阶段怪物采用抽象几何表现，可以减少首版资源体积。

#### 加载触发时机

建议流程：

```text
打开网页
  └─ 加载 Godot 引擎和主场景
      └─ 显示 Loading
          └─ 加载 menu 组
              └─ 显示 MainMenu
                  └─ 后台预加载 game_core 组
                      └─ 玩家点击 Play
                          ├─ 如果 game_core 已加载：进入游戏
                          └─ 如果未加载：显示局内加载，等待完成
                              └─ 进入游戏并加载 combat_core 组
```

第一版简化方案：

- 启动时加载 menu + game_core + combat_core。
- 仍然按阶段显示进度。
- 后续资源变大后，再改为真正按需加载。

#### Web 音频限制

实现要求：

- 浏览器通常需要用户交互后才能播放音频。
- 背景音乐和音效不要在页面加载时自动播放。
- 第一次点击开始按钮后，再解锁音频播放。
- 静音按钮要对 Web 生效。

技术方案：

- 后续抽 `AudioSystem` 时加入 `unlock_audio()`。
- `PlayButton` 第一次点击时调用音频解锁。
- 音效播放前检查 `muted` 和 `audio_unlocked`。

#### 缓存与版本

实现要求：

- Web 发布后需要考虑浏览器缓存。
- 版本更新后，玩家不应该卡在旧资源。
- 配置和存档要兼容旧版本。

建议方案：

- 每次发布记录版本号，例如 `WEB_BUILD_VERSION`。
- HTML 或导出文件使用版本参数或平台缓存策略。
- 玩家本地存档只存简单数据，如最高分、设置、进度。
- 配置变更时提供默认值，避免旧存档缺字段时报错。

#### Web 性能要求

第一版要求：

- 控制首包体积。
- 避免同时生成过多怪物和特效。
- 弹道、飘字、死亡特效要能复用节点或及时释放。
- 移动浏览器中保持棋盘点击响应。

技术注意：

- 不要在每帧大量创建临时对象。
- 怪物、弹道、飘字后续可以做对象池。
- 大量透明特效可能影响 Web 性能，第一版特效要克制。

#### Web 适配测试清单

需要测试：

- 桌面 Chrome/Edge。
- 移动端浏览器竖屏。
- 页面刷新后重新进入。
- 第一次点击后音效是否能播放。
- 静音按钮是否有效。
- 加载过程中是否有空白或卡死。
- 主菜单到游戏内是否有明显等待。
- 怪物路径是否超出屏幕。
- 棋盘点击是否被战斗层遮挡。
- 浏览器窗口尺寸变化后布局是否正确。

#### Web 发布阶段计划

第一阶段：可导出运行

- 确认 Godot Web 导出模板可用。
- 导出 Web 后能打开主场景。
- 加载页、主菜单、基础游戏流程正常。

第二阶段：加载分组

- 新增 `LoadingSystem`。
- 把菜单、核心玩法、战斗基础资源列成加载组。
- 进度条接入真实加载阶段。

第三阶段：资源瘦身

- 清理或排除无用旧资源。
- 检查导出包体积。
- 压缩大图和音频。

第四阶段：Web 体验完善

- 音频解锁。
- 缓存版本策略。
- 移动端竖屏适配。
- 加载失败重试。

第五阶段：后续内容按需加载

- 字母阶段素材延后加载。
- 高级特效延后加载。
- 道具、Boss、更多怪物外观按需加载。

### 实现阶段计划

第一阶段：战斗最小闭环

- 新增怪物路径。
- 新增小/中/大普通怪。
- 新增城堡耐久。
- 怪物沿路径移动，到终点扣耐久并消失。
- 波次持续出怪，并按清空场上怪物进入下一波。
- 本阶段暂时可以不接合成攻击，目标是先确认怪物路径、出怪节奏、扣耐久和失败流程成立。

第一阶段具体工程结构：

目标：

- 在现有主场景中加入战斗层，不改变棋盘合成主体逻辑。
- 怪物可以沿固定回形路径移动。
- 怪物到达终点后扣城堡耐久并消失。
- 波次可以持续生成怪物，并在场上清空后进入下一波。

建议新增脚本：

| 文件 | 职责 |
| --- | --- |
| `res://scripts/combat_system.gd` | 第一阶段战斗总入口，持有怪物管理、波次、城堡耐久引用。第二阶段也由它接收合成攻击事件。 |
| `res://scripts/monster.gd` | 单个怪物逻辑，包括血量、大小、速度、扣耐久、死亡状态。 |
| `res://scripts/monster_manager.gd` | 生成怪物、维护怪物列表、更新场上怪物数量、处理怪物到达终点。 |
| `res://scripts/wave_manager.gd` | 管理波次配置、出怪队列、出怪间隔、波次结束判断。 |
| `res://scripts/castle_system.gd` | 管理城堡耐久、扣耐久、耐久 UI 更新、耐久归零失败。 |

建议新增场景：

| 文件 | 职责 |
| --- | --- |
| `res://scenes/monster.tscn` | 普通怪基础场景，小/中/大通过配置改变尺寸、血量、速度和扣耐久。 |
| `res://scenes/combat_layer.tscn` | 可选。承载战斗层、怪物路径、怪物容器、城堡 UI。如果第一版先在主场景动态创建，也可以后续再拆。 |

建议主场景层级：

```text
Main
├─ Background
├─ Decor
├─ Loading
├─ MainMenu
├─ Game
│  ├─ BattleLayer
│  │  ├─ MonsterPath
│  │  │  └─ MonsterFollowContainer
│  │  ├─ MonsterVisualLayer
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

层级说明：

- `BattleLayer` 放在 `Game` 下，并且视觉上位于棋盘背景和方块之间或棋盘背景后方。
- `Board` 仍然负责方块点击，怪物路径不能挡住棋盘输入。
- `MonsterPath` 使用 `Path2D`，路径围绕棋盘外圈。
- 怪物可以作为 `PathFollow2D` 的子节点移动。
- `MonsterVisualLayer` 可选。如果怪物直接挂在 `PathFollow2D` 下显示不方便，可以用它统一管理视觉节点。
- `CastleAnchor` 放在终点附近，用于显示城堡耐久或城堡图标。
- `WaveLabel` 用于显示当前波次，第一版可以先用文字。

`Path2D` 放置位置：

- `Path2D` 放在 `Game/BattleLayer/MonsterPath`。
- `BattleLayer` 跟随 `game_layer` 布局。
- `MonsterPath` 的坐标应基于棋盘外圈计算，在 `_layout_scene()` 中随棋盘位置更新。
- 回形路径需要围绕 `BoardBackdrop` 或 `Board` 外侧一圈，给怪物留出移动宽度。
- 入口在棋盘左上角外侧。
- 终点在入口旁边，接近绕满一圈但不重合。

`Path2D` 更新方案：

- 在 `_layout_scene()` 中根据 `board_pos` 和 `board_size` 重新生成 `Curve2D`。
- 路径点按固定回形顺序创建：左上入口 -> 右上 -> 右下 -> 左下 -> 左上旁边终点。
- 由于路径是固定回形，点位只根据棋盘矩形和边距计算，不暴露为自由编辑路径。

建议伪代码：

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

第一阶段脚本关系：

```text
main_game.gd
└─ combat_system.gd
   ├─ castle_system.gd
   ├─ wave_manager.gd
   └─ monster_manager.gd
      └─ monster.gd / monster.tscn
```

调用关系：

- `main_game.gd` 创建或引用 `CombatSystem`。
- `main_game.gd` 在 `start_game()` / `replay_game()` 时调用 `combat_system.start_run()`。
- `main_game.gd` 在 `over_game()` 或游戏结束时调用 `combat_system.stop_run()`。
- `main_game.gd` 在 `_layout_scene()` 时把棋盘位置和尺寸传给 `combat_system.layout_for_board(board_pos, board_size)`。
- `CombatSystem` 初始化 `CastleSystem`、`WaveManager`、`MonsterManager`。
- `WaveManager` 根据波次配置通知 `MonsterManager` 生成怪物。
- `MonsterManager` 监听怪物到达终点事件，通知 `CastleSystem` 扣耐久。
- `CastleSystem` 耐久归零时通知 `CombatSystem`，再由 `CombatSystem` 请求主游戏进入失败。

第一阶段新增信号建议：

```gdscript
signal castle_destroyed
signal monster_reached_goal(monster, durability_damage)
signal wave_started(wave_index)
signal wave_cleared(wave_index)
```

第一阶段脚本接口设计：

#### `combat_system.gd`

职责：

- 第一阶段战斗总控。
- 创建和连接 `PathSystem`、`MonsterSystem`、`WaveSystem`、`CastleSystem`。
- 对 `main_game.gd` 暴露开始、停止、重置、布局接口。
- 城堡耐久归零后通知主游戏失败。

建议信号：

```gdscript
signal castle_destroyed
signal wave_started(wave_index: int)
signal wave_cleared(wave_index: int)
signal combat_started
signal combat_stopped
```

建议字段：

```gdscript
var running := false
var board_pos := Vector2.ZERO
var board_size := Vector2.ZERO
var path_system: PathSystem
var monster_system: MonsterSystem
var wave_system: WaveSystem
var castle_system: CastleSystem
var projectile_system: ProjectileSystem
var effect_system: EffectSystem
```

建议公开方法：

```gdscript
func start_run() -> void
func stop_run() -> void
func reset() -> void
func layout_for_board(new_board_pos: Vector2, new_board_size: Vector2) -> void
func handle_merge_attack(event: MergeAttackEvent) -> void
func get_active_monsters() -> Array
```

建议内部方法：

```gdscript
func _build_children() -> void
func _connect_signals() -> void
func _on_monster_reached_goal(monster: Node, durability_damage: int) -> void
func _on_castle_destroyed() -> void
func _on_wave_started(wave_index: int) -> void
func _on_wave_cleared(wave_index: int) -> void
```

接口要求：

- `start_run()` 重置城堡耐久、怪物、波次，然后开始第一波。
- `stop_run()` 停止出怪，清理场上怪物，停止战斗状态。
- `reset()` 必须可以被重开、返回主菜单、失败流程安全调用。
- `layout_for_board()` 只负责把棋盘位置传给路径和 UI，不开始战斗。
- 第一阶段 `handle_merge_attack()` 可以继续保持空表现或只记录事件，第二阶段再真正攻击怪物。

#### `path_system.gd`

职责：

- 管理固定回形 `Path2D`。
- 根据棋盘位置和尺寸生成路径。
- 提供路径入口、终点、进度查询所需信息。
- 不管理怪物血量，不管理波次。

建议信号：

```gdscript
signal path_rebuilt
```

建议字段：

```gdscript
var path_2d: Path2D
var curve := Curve2D.new()
var board_pos := Vector2.ZERO
var board_size := Vector2.ZERO
var margin := 42.0
var end_offset := 72.0
```

建议公开方法：

```gdscript
func setup(parent: Node) -> void
func layout_for_board(new_board_pos: Vector2, new_board_size: Vector2) -> void
func get_path() -> Path2D
func create_follower() -> PathFollow2D
func get_spawn_position() -> Vector2
func get_goal_progress_ratio() -> float
```

建议内部方法：

```gdscript
func _rebuild_curve() -> void
func _make_point_list() -> Array[Vector2]
```

接口要求：

- `Path2D` 固定放在 `Game/BattleLayer/MonsterPath`，或由 `PathSystem.setup()` 创建后挂到 `BattleLayer`。
- `layout_for_board()` 每次布局时重新计算曲线。
- `create_follower()` 返回新的 `PathFollow2D`，给怪物系统挂载怪物节点。
- 终点判断第一版可以用 `PathFollow2D.progress_ratio >= 0.995`。

#### `monster.gd`

职责：

- 单个怪物的生命、移动表现、受击、死亡、到终点状态。
- 怪物个体不决定波次，也不直接扣城堡耐久，只发出到达终点事件。

建议信号：

```gdscript
signal died(monster: Monster)
signal reached_goal(monster: Monster, durability_damage: int)
signal hp_changed(monster: Monster, hp: float, max_hp: float)
```

建议字段：

```gdscript
var monster_type := "small"
var max_hp := 5.0
var hp := 5.0
var durability_damage := 1
var speed := 80.0
var alive := true
var reached := false
var path_follow: PathFollow2D
```

建议公开方法：

```gdscript
func setup(config: Dictionary, follow: PathFollow2D) -> void
func update_movement(delta: float) -> void
func apply_damage(amount: float) -> void
func kill() -> void
func reset_status() -> void
func get_progress_ratio() -> float
func is_alive() -> bool
```

建议内部方法：

```gdscript
func _check_goal() -> void
func _play_hit_feedback() -> void
func _play_death_feedback() -> void
```

接口要求：

- `update_movement(delta)` 只在 `alive == true` 且 `reached == false` 时推进。
- 到达终点后只发一次 `reached_goal`。
- `apply_damage()` 第一阶段可以先不用，第二阶段接入攻击时启用。
- `kill()` 需要安全移除视觉节点和路径跟随节点。

#### `monster_system.gd`

职责：

- 生成怪物、维护怪物列表、更新怪物移动。
- 接收 `WaveSystem` 的生成请求。
- 监听怪物死亡和到达终点。
- 给 `CombatSystem` 提供当前活着的怪物列表。

建议信号：

```gdscript
signal monster_spawned(monster: Monster)
signal monster_died(monster: Monster)
signal monster_reached_goal(monster: Monster, durability_damage: int)
signal all_monsters_cleared
```

建议字段：

```gdscript
var monsters: Array[Monster] = []
var path_system: PathSystem
var monster_scene: PackedScene
var running := false
```

建议公开方法：

```gdscript
func setup(path: PathSystem, scene: PackedScene) -> void
func start() -> void
func stop() -> void
func reset() -> void
func spawn_monster(monster_type: String) -> Monster
func get_alive_monsters() -> Array[Monster]
func get_front_monsters(count: int) -> Array[Monster]
```

建议内部方法：

```gdscript
func _process(delta: float) -> void
func _on_monster_died(monster: Monster) -> void
func _on_monster_reached_goal(monster: Monster, durability_damage: int) -> void
func _remove_monster(monster: Monster) -> void
func _check_all_cleared() -> void
```

接口要求：

- `spawn_monster()` 通过 `PathSystem.create_follower()` 创建路径跟随节点。
- `get_front_monsters(count)` 按 `monster.get_progress_ratio()` 从大到小排序。
- 怪物死亡或到达终点后都要从 `monsters` 移除。
- 移除后如果列表为空，发出 `all_monsters_cleared`。

#### `wave_system.gd`

职责：

- 管理波次配置。
- 根据当前波次创建出怪队列。
- 按间隔请求 `MonsterSystem` 生成怪物。
- 判断一波是否结束。

建议信号：

```gdscript
signal wave_started(wave_index: int)
signal spawn_requested(monster_type: String)
signal wave_spawn_finished(wave_index: int)
signal wave_cleared(wave_index: int)
```

建议字段：

```gdscript
var waves: Array = []
var current_wave_index := -1
var spawn_queue: Array[String] = []
var spawn_interval := 1.0
var spawn_timer := 0.0
var spawning := false
var waiting_for_clear := false
var monsters_are_clear := true
```

建议公开方法：

```gdscript
func setup(wave_config: Array) -> void
func start_first_wave() -> void
func start_wave(index: int) -> void
func stop() -> void
func reset() -> void
func notify_all_monsters_cleared() -> void
func is_wave_active() -> bool
```

建议内部方法：

```gdscript
func _process(delta: float) -> void
func _build_spawn_queue(wave: Dictionary) -> Array[String]
func _request_next_spawn() -> void
func _finish_spawning() -> void
func _try_clear_wave() -> void
```

接口要求：

- 每波开始时发出 `wave_started`。
- 出怪时只发 `spawn_requested(monster_type)`，不直接实例化怪物。
- 出怪队列为空后发出 `wave_spawn_finished`，并等待场上清空。
- 收到 `notify_all_monsters_cleared()` 后，如果本波也出完，发出 `wave_cleared` 并进入下一波。
- 后续难度成长、循环波次或无限波次都放在这里扩展。

#### `castle_system.gd`

职责：

- 管理城堡耐久。
- 扣耐久、重置耐久、更新 UI。
- 耐久归零后发出失败信号。

建议信号：

```gdscript
signal durability_changed(current: int, max_value: int)
signal castle_destroyed
```

建议字段：

```gdscript
var max_durability := 20
var durability := 20
var label: Label
var icon: Control
```

建议公开方法：

```gdscript
func setup(parent: Control, max_value: int = 20) -> void
func reset() -> void
func damage(amount: int) -> void
func heal(amount: int) -> void
func layout(anchor_position: Vector2) -> void
func get_durability() -> int
```

建议内部方法：

```gdscript
func _build_ui(parent: Control) -> void
func _update_ui() -> void
func _emit_destroyed_if_needed() -> void
```

接口要求：

- `damage()` 需要 clamp 到 `0`。
- 耐久变化后必须发 `durability_changed`。
- `castle_destroyed` 只能发一次，避免重复进入失败。
- 第一版 UI 可以简单显示城堡图标和 `20/20` 文本。

#### `projectile_system.gd`

第一阶段职责：

- 保持占位。
- 不影响怪物移动闭环。

第一阶段接口：

```gdscript
func reset() -> void
func play_merge_attack(event: MergeAttackEvent, targets: Array = []) -> void
```

接口要求：

- 第一阶段可以空实现。
- 第二阶段开始负责攻击飞行表现。

#### `effect_system.gd`

第一阶段职责：

- 保持占位，或播放最轻量的怪物到达终点/扣耐久反馈。
- 不负责数值。

第一阶段接口：

```gdscript
func reset() -> void
func play_merge_feedback(event: MergeAttackEvent) -> void
func play_monster_reached_goal(monster: Monster) -> void
func play_castle_damage(amount: int) -> void
```

接口要求：

- 第一阶段可以只实现 `reset()`。
- 后续受击、死亡、属性、飘字都从这里扩展。

第一阶段信号流：

```text
WaveSystem
  └─ spawn_requested(monster_type)
      └─ MonsterSystem.spawn_monster(monster_type)

Monster
  └─ reached_goal(monster, durability_damage)
      └─ MonsterSystem.monster_reached_goal
          └─ CombatSystem._on_monster_reached_goal
              └─ CastleSystem.damage(durability_damage)

CastleSystem
  └─ castle_destroyed
      └─ CombatSystem.castle_destroyed
          └─ main_game.gd end_game(false)

MonsterSystem
  └─ all_monsters_cleared
      └─ WaveSystem.notify_all_monsters_cleared()
          └─ WaveSystem.wave_cleared(wave_index)
```

第一阶段主流程：

```text
start_game()
  └─ combat_system.start_run()
      ├─ castle_system.reset()
      ├─ monster_system.reset()
      ├─ wave_system.reset()
      └─ wave_system.start_first_wave()

_layout_scene()
  └─ combat_system.layout_for_board(board_pos, board_size)
      ├─ path_system.layout_for_board(board_pos, board_size)
      └─ castle_system.layout(goal_or_anchor_position)

replay_game() / over_game() / end_game()
  └─ combat_system.stop_run()
```

第一阶段怪物配置：

```gdscript
const MONSTER_CONFIG := {
	"small": {"hp": 5, "durability_damage": 1, "speed": 80.0, "scale": 0.75},
	"medium": {"hp": 12, "durability_damage": 2, "speed": 68.0, "scale": 1.0},
	"large": {"hp": 25, "durability_damage": 3, "speed": 55.0, "scale": 1.25},
}
```

第一阶段波次配置：

```gdscript
const WAVES := [
	{"small": 6, "medium": 0, "large": 0, "spawn_interval": 1.0},
	{"small": 8, "medium": 2, "large": 0, "spawn_interval": 0.9},
	{"small": 10, "medium": 4, "large": 1, "spawn_interval": 0.8},
]
```

第一阶段实现顺序：

1. 新建 `monster.tscn` 和 `monster.gd`，能显示一个抽象几何怪。
2. 新建 `combat_system.gd`，接入主场景并能开始/停止。
3. 在 `Game` 下创建 `BattleLayer` 和 `MonsterPath`。
4. 在 `_layout_scene()` 中生成固定回形 `Path2D`。
5. 新建 `monster_manager.gd`，能把怪物挂到 `PathFollow2D` 并沿路径移动。
6. 新建 `castle_system.gd`，显示城堡耐久 20，并支持扣耐久。
7. 新建 `wave_manager.gd`，按配置持续出怪。
8. 怪物到终点后扣耐久并消失。
9. 场上怪物清空且本波出完后进入下一波。
10. 城堡耐久归零后触发失败结算。

第一阶段验收标准：

- 进入游戏后，可以看到怪物从左上入口沿棋盘外圈回形路径移动。
- 怪物到达终点后消失，并扣除城堡耐久。
- 小/中/大怪的尺寸、速度、扣耐久不同。
- 波次会按配置持续生成怪物。
- 一波全部生成完且场上清空后，会进入下一波。
- 城堡耐久归零后游戏结束。
- 怪物路径不遮挡棋盘点击。
- 重新开始会清空旧怪物、重置波次和城堡耐久。

第二阶段：合成攻击接入

- 合成完成后生成攻击事件。
- 按路径进度选择最靠近终点的目标。
- 根据等级和合成数量计算伤害。
- 怪物受伤、死亡、移除。

第二阶段开发要求：

- 棋盘合成逻辑只负责发出攻击事件，不直接操作怪物。
- 战斗系统提供公开方法，例如 `combat_system.handle_merge_attack(attack_event)`。
- 攻击事件必须包含：合成后等级、颜色属性、合成数量、攻击起点位置。
- 攻击伤害使用当前记录的基础攻击力表和合成数量加成。
- 攻击目标数使用 `merge_count - 1`。
- 目标选择必须优先选择 `progress_ratio` 最大的怪物，也就是最靠近终点的怪。
- 多目标攻击时，从最靠近终点的怪开始向队列后方依次选择。
- 如果场上怪物数量不足，则只攻击现有怪物。
- 怪物被攻击后需要显示受击反馈，至少包括闪烁、缩放或飘血中的一种。
- 怪物血量归零时播放死亡反馈并从怪物列表移除。
- 合成攻击不能阻塞棋盘下落和补充流程太久，攻击表现应尽量异步播放。
- 如果合成时场上没有怪物，攻击事件可以被忽略，但后续可以考虑转化为能量或道具充能。
- 第二阶段先实现普通伤害，不强制加入火焰、冰冻、雷电、毒的完整属性效果；属性效果放到第三阶段。

第二阶段验收标准：

- 玩家完成一次合成后，最靠近终点的怪物会受到伤害。
- 合成数量越多，伤害更高，攻击目标更多。
- 小怪血量为 5 时，可以被中高等级攻击明显击杀。
- 怪物死亡后不会继续移动、不会到终点扣耐久、不会被重复选中。
- 没有怪物时合成不会报错。
- 波次系统仍然能正确判断场上清空并进入下一波。

第三阶段：颜色属性

- 加入火焰、冰冻、雷电、毒。
- 接入持续伤害、冻结、连锁等基础效果。
- 补充对应视觉反馈。

第四阶段：UI 和反馈

- 优化城堡耐久显示。
- 优化波次显示。
- 优化怪物受击、死亡、攻击飞行表现。
- 调整布局，确保棋盘和怪物路径不冲突。

第五阶段：道具和技能

- 加入自动小道具。
- 加入主动大技能。
- 调整道具获取、触发和 UI。

### 技术风险

- 现有 `main_game.gd` 已经承担了大量 UI 和玩法逻辑，继续堆叠会变得难维护。
- 怪物路径围绕棋盘后，竖屏空间可能紧张，需要重新审视布局。
- 合成动画、下落动画和攻击事件的时机要处理清楚，避免玩家感觉攻击延迟或错位。
- 属性状态和持续伤害会引入时间结算，需要统一处理暂停、失败、弹窗状态。
- 波次系统和无可合并失败判定可能冲突，后续需要决定“棋盘无可合并”是否仍然立刻失败，还是给玩家道具/刷新机会。

## 待讨论问题

- 多目标攻击是完整伤害还是递减伤害？
- 字母阶段 A、B、C、D、E 的基础攻击力如何继续增长？
- 每波持续出怪的间隔是多少？
- 小/中/大怪扣除 1/2/3 耐久是否需要后续微调？
- 颜色分别对应哪些攻击属性？
- 字母阶段是否继续使用四大基础属性循环？
- 10 之后的字母等级如何命名和显示？
- 自动触发的小道具和主动释放的大技能如何区分？
- 玩家血量和怪物扣血规则如何设计？
- 达到 10 后如何进入字母阶段？
- 是否要加入步数限制或关卡目标？
- 游戏主要面向移动端还是桌面端？
- 是否要加入广告复活、金币、道具购买等商业化设计？
- 是否需要多语言，还是只保留中文/英文其中一种？
- 是否需要重新设计 UI，还是尽量保持原素材风格？
- 当前 `CONTINUE` 文本按钮是否需要替换成图片按钮。

## 决策记录

| 日期 | 决策 | 说明 |
| --- | --- | --- |
| 2026-07-02 | 建立项目方向记录文档 | 用于记录未来开发方向、功能细节和讨论结论。 |
| 2026-07-02 | 新增合成打怪方向 | 数字/字母作为攻击成长阶段，棋盘合成用于阻挡环绕前进的怪物队列，怪物到达终点会扣除玩家血量。 |
| 2026-07-02 | 确定打怪玩法骨架 | 攻击以合成后一次性触发为核心；怪物完整环绕棋盘；数字升级体现为伤害和攻击属性；道具分为自动触发的小道具和主动释放的大技能。 |
| 2026-07-02 | 取消方块持续攻击方向 | 数字方块不做持续自动攻击，避免玩法变成塔防挂机输出。 |
| 2026-07-02 | 确定一次性攻击目标规则 | 合成攻击优先命中最靠近终点的怪物；合成数量同时提高伤害和攻击目标数；数字属性采用低数字简单、高数字特殊化的结构。 |
| 2026-07-02 | 扩展等级与属性设计 | 等级不止到 10，10 之后用 A、B、C、D、E 等字母继续成长；等级越高攻击力越强，攻击属性主要通过颜色区分。 |
| 2026-07-02 | 确定基础颜色属性 | 红色为火焰持续伤害，蓝色为冰冻停止怪物，黄色为雷电连锁攻击，绿色为毒持续伤害。 |
| 2026-07-02 | 确定颜色顺序原则 | 等级颜色基本按照当前 1-10 素材顺序设计，不优先重排已有颜色。 |
| 2026-07-02 | 收拢颜色属性范围 | 第一版颜色系统归并到火焰、冰冻、雷电、毒四大基础属性，其他颜色暂时不独立成新属性。 |
| 2026-07-02 | 确定 8 和 9 的属性归并 | 8 的紫色归并到毒，9 的紫红色归并到雷电。 |
| 2026-07-02 | 确定怪物路径基础规则 | 怪物从左上角进入，沿棋盘外圈接近绕满一圈，在入口旁边的终点扣除城堡耐久并消失。 |
| 2026-07-02 | 确定生命表现方向 | 玩家生命用城堡耐久表现，不优先使用普通数字血条；不同怪物可以扣除不同耐久。 |
| 2026-07-02 | 确定怪物生成与外观方向 | 怪物生成采用波次 + 持续混合；第一版只做普通怪；怪物按大小扣 1/2/3 耐久；外观采用抽象几何怪。 |
| 2026-07-02 | 确定第一版波次规则 | 波次按怪物数量递增和怪物大小变化推进；每波需要全部生成完且场上清空才结束。 |
| 2026-07-02 | 确定第一版城堡与普通怪数值 | 初始城堡耐久为 20；小/中/大普通怪血量为 5/12/25，到达终点扣耐久为 1/2/3。 |
| 2026-07-02 | 确定第一版合成攻击数值 | 基础攻击力使用阶梯增长；合成数量每多 1 个伤害 +20%；目标数 = 合成数量 - 1。 |
| 2026-07-02 | 开始技术实现方案规划 | 新增技术实现计划，按棋盘、战斗、怪物路径、波次、城堡耐久、属性、UI、道具等模块记录具体实现思路。 |
| 2026-07-02 | 确定技术实现路线 | 怪物路径使用固定回形 `Path2D` 路径，不采用自由自定义路径点；战斗系统从一开始拆成独立脚本；第一阶段先做怪物移动和城堡耐久，第二阶段接入合成攻击。 |
| 2026-07-02 | 补充第一阶段工程结构 | 规划新增 `combat_system.gd`、`monster.gd`、`monster_manager.gd`、`wave_manager.gd`、`castle_system.gd`，并确定 `Path2D` 放在 `Game/BattleLayer/MonsterPath`。 |
| 2026-07-02 | 补充长期系统拆分目标 | 增加 BoardSystem、MergeSystem、BlockView、CombatSystem、ProjectileSystem、MonsterSystem、PathSystem、WaveSystem、EffectSystem、AudioSystem、GameStateSystem、Config 的职责边界。 |
| 2026-07-02 | 记录当前结构拆分进度 | 已新增 `game_config.gd`、`merge_attack_event.gd`、`combat_system.gd`、`projectile_system.gd`、`effect_system.gd`，并在 `main_game.gd` 中完成空实现接入。 |
| 2026-07-02 | 补充第一阶段脚本接口 | 为 `combat_system.gd`、`path_system.gd`、`monster.gd`、`monster_system.gd`、`wave_system.gd`、`castle_system.gd`、`projectile_system.gd`、`effect_system.gd` 规划信号、字段、公开方法和调用流程。 |
| 2026-07-02 | 确定 Web 发布方向 | 游戏优先发布 Web 格式，需要规划分段加载、资源瘦身、音频解锁、缓存版本和移动浏览器适配。 |

## 后续记录区

后续讨论可以直接追加在这里，或整理进上面的对应章节。

### 讨论记录

- 2026-07-02：创建本文档，作为项目长期规划和功能细节记录入口。
- 2026-07-02：确定新的大方向：增加打怪系统。数字/字母元素转化为攻击成长阶段，怪物以环绕队列形式围绕棋盘前进，玩家通过中间棋盘的合成行为产生攻击并阻挡怪物。怪物到达终点时玩家损失血量。
- 2026-07-02：第一轮选择结果修正：攻击以合成后一次性触发为核心，不做方块持续攻击；怪物路径采用完整环绕棋盘；数字成长采用“伤害 + 攻击属性”；道具采用“小道具自动触发，大技能主动释放”。
- 2026-07-02：第二轮选择结果：合成攻击优先攻击最靠近终点的怪物；合成数量越多，伤害越高，同时攻击目标数量也越多；数字属性采用“低数字简单，高数字才有特殊属性”的设计。
- 2026-07-02：等级设计修正：游戏不止做到数字 10，10 之后进入 A、B、C、D、E 等字母阶段；攻击力随等级持续增强，属性主要通过颜色区分。
- 2026-07-02：颜色属性选择结果：红色对应火焰持续伤害，蓝色对应冰冻停止怪物，黄色对应雷电连锁攻击，绿色对应毒持续伤害。当前素材中 1 偏亮绿、2 偏青蓝、3 偏金黄/橙、4 偏橙、5 红、6 绿、7 蓝、8 紫、9 紫红、10 黄。
- 2026-07-02：颜色顺序补充：等级颜色基本按照当前素材顺序来设计，优先让属性解释适配已有颜色，而不是重新安排 1-10 的颜色。
- 2026-07-02：颜色属性范围补充：第一版先归并到四大基础属性，不为青蓝、橙、紫、紫红单独建立新属性；后续如果玩法需要再修改扩展。
- 2026-07-02：8 和 9 的属性归并补充：8 暂时归并到毒，9 暂时归并到雷电。
- 2026-07-02：怪物路径选择结果：怪物从左上角进入，终点在入口旁边，接近绕满一圈但不完全重合；怪物到达终点后扣除城堡耐久并消失。玩家生命表现为城堡耐久，不同怪物可扣不同耐久。
- 2026-07-02：怪物生成与类型选择结果：怪物生成采用“波次 + 持续混合”，每波有主题，波内持续出怪；第一版只做普通怪；怪物按大小扣 1/2/3 耐久；怪物外观采用抽象几何怪。
- 2026-07-02：波次规则选择结果：第一版波次主题采用数量递增和大小变化，越往后怪物越密集，中/大怪比例越高；每波结束条件为该波怪物全部生成完，并且场上怪物清空。
- 2026-07-02：数值选择结果：初始城堡耐久为 20，偏休闲；普通怪采用轻量血量，小/中/大分别为 5/12/25，到达终点分别扣 1/2/3 耐久。
- 2026-07-02：合成攻击数值选择结果：基础攻击力采用阶梯增长，1-10 分别为 2/4/6/10/14/18/25/32/40/50；合成数量每多 1 个伤害增加 20%；攻击目标数 = 合成数量 - 1。
- 2026-07-02：进入技术实现方案规划阶段。技术计划按模块拆分为总体架构、数据结构、等级与字母阶段、颜色属性、合成攻击事件、攻击目标选择、怪物路径、怪物节点、波次系统、城堡耐久、道具技能、UI 改造和实现阶段计划。
- 2026-07-02：技术路线补充：怪物路径使用固定回形 `Path2D`，不走自由自定义路径点方案；战斗系统从一开始拆成独立脚本；第一阶段可以先完成怪物移动、波次和城堡耐久闭环，第二阶段再接入合成攻击，并提前列出第二阶段开发要求和验收标准。
- 2026-07-02：第一阶段工程结构补充：新增脚本建议为 `combat_system.gd`、`monster.gd`、`monster_manager.gd`、`wave_manager.gd`、`castle_system.gd`；主场景中在 `Game` 下增加 `BattleLayer`，其下放置 `MonsterPath`、怪物显示层、城堡耐久锚点和波次显示。`Path2D` 放在 `Game/BattleLayer/MonsterPath`，在布局时按棋盘外圈生成固定回形路径。
- 2026-07-02：长期系统拆分补充：后续系统边界包括 BoardSystem、MergeSystem、BlockView、CombatSystem、ProjectileSystem、MonsterSystem、PathSystem、WaveSystem、EffectSystem、AudioSystem、GameStateSystem 和 Config。当前优先保持原玩法不变，通过事件和配置逐步拆分。
- 2026-07-02：当前结构拆分进度记录：已新增 `game_config.gd`、`merge_attack_event.gd`、`combat_system.gd`、`projectile_system.gd`、`effect_system.gd`；`main_game.gd` 已在开局、重开、返回、失败、复活和合成完成时接入 `CombatSystem`。当前战斗系统为空实现，理论上不改变原玩法。已做静态检查，未发现明显引用问题；命令行找不到 Godot，尚未跑真实启动检查。
- 2026-07-02：第一阶段脚本接口补充：为战斗总控、路径、怪物、怪物管理、波次、城堡耐久、弹道、特效分别规划信号、字段、公开方法、内部方法和信号流。第一阶段主流程为 `start_game()` 调用 `combat_system.start_run()`，布局时调用 `layout_for_board()`，怪物到终点后经由怪物系统通知城堡扣耐久，耐久归零后由战斗总控通知主游戏失败。
- 2026-07-02：Web 发布方案补充：目标平台优先为 Web。技术计划新增 Web 发布与分段加载章节，包含 0-4 阶段加载、首屏加载机制、Godot 异步资源加载、资源分包、加载触发时机、浏览器音频解锁、缓存版本、Web 性能要求和测试清单。
