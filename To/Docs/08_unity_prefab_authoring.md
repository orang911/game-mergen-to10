# Unity 界面与核心场景 Prefab 编辑说明

2026-09-15，v01。共 35 个 Prefab、6 个场景文件。开发工程：`D:/UGit/T0/To`。

## 从哪里开始

- 主入口：`Assets/MergeTo10/Scenes/NavigationIntegration.unity`，包含连接到资源的 `GameCore` Prefab 实例。
- 战斗布局编辑入口：`Assets/MergeTo10/Scenes/GameCoreAuthoring.unity`，关闭大厅预览，直接展示棋盘、路径、魔法门和水晶。播放仍使用现有游戏导航流程。
- 资源根目录：`Assets/MergeTo10/Resources/Prefabs/`。
- Unity 菜单：`Merge To 10/Prefabs/Open Editable Game Scene`。

主场景展开 `GameCore/InterfacePrefabs` 可以找到各个界面的预制体实例。编辑模式下可启用要预览的界面，暂时关闭其他界面，避免高层 Canvas 遮挡。运行时 `PrefabSceneLibrary` 会隐藏这些编辑模板，再根据实际界面状态实例化；场景中的模板 Override 同样参与运行。

## 资源清单

|目录|Prefab|用途|
|---|---|---|
|Core|GameCore|完整游戏控制器、嵌套战斗层、相机和界面模板引用|
|Core|GameLayer、BoardCamera|游戏视觉层和正交相机|
|Core|M1BoardParity、M2BattleParity、M2WaveBattle、ChapterIntegration|原有四个测试/联调场景入口，保留原控制器设置|
|Board|BoardLayout、Cell|5×5 棋盘布局和运行时方块|
|Combat|BattleWorld、Road、Gate、Crystal|战斗区域、路径、魔法门、水晶|
|Combat|Monster、Projectile|运行时怪物、飞行物的实例模板|
|UI|LoadingCanvas、MainHubCanvas|加载、大厅|
|UI|BattleHudCanvas、EnergyHudCanvas、BattlePauseCanvas|战斗 HUD、能量区、暂停|
|UI|NavigationSettingsCanvas、DailyProgressCanvas、CrystalUpgradeCanvas|设置、任务签到、水晶升级预览|
|UI|ExitConfirmationCanvas、ChapterNodeCanvas|退出确认、关卡完成|
|UI|CrystalChoiceCanvas、ImprintChoiceCanvas|水晶卡牌与印记选择|
|UI|Commerce_benefits、Commerce_piggy|权益和存钱罐|
|UI|Commerce_purchase_confirm_benefits_bundle、Commerce_purchase_confirm_piggy_bank|两种购买确认|
|UI|LoadingClearDialog、LoadingErrorDialog、LoadingRecoveryDialog、SaveErrorCanvas|清空确认、加载错误、备份恢复、保存失败|
|Shared|sprite_*.asset、material_*.mat|从现有纹理建立的持久 Sprite、材质引用，确保退出 Play 后 Prefab 不丢图|

`BoardLayout/EditorPreview` 和 `BattleWorld/EditorPreview` 仅用于编辑预览。运行时移除预览，再通过 Cell、Crystal 等 Prefab 创建真实对象，避免重复棋盘或水晶；预览也标记为 `EditorOnly`。

## 添加和修改动效

1. 双击对应 `.prefab`，进入 Prefab Mode，编辑子节点；或者在场景实例上修改后按需要 Apply。
2. 完整 Canvas 界面的整体动效优先放到 `AnimationRoot` 上，添加 Animator、Animation 或 Timeline。暂停弹窗需要把 Animator 的 Update Mode 设置为 **Unscaled Time**。
加载小弹窗可在 Panel 上或新增的动画子节点上制作动画。
3. 方块的额外装饰、旋转、缩放可放在 `Cell/AnimationRoot`。代码仍负责方块根节点的落下、合成移动及排序。
4. 局部按钮、卡牌可以增加自己的动画父节点。`PrefabUiNode` 使用独立的绑定标识，因此改显示名称或插入不带该组件的动画父节点，不会因路径改变而失去事件绑定。
5. 保留生成节点上的 `PrefabUiNode`。绑定标识由迁移工具生成，不要复制已有标识到新增节点；新增装饰普通节点无需该组件。

代码继续更新文案数值、随机卡牌图标、按钮可用状态、进度宽度、棋盘数字、怪物位置和原有交互动效。不要让新动画与这些逻辑同时写同一个属性；为新增动效增加独立父节点即可。界面 Prefab 中的位置、字体/字号、颜色或替换贴图的编辑会在初始数据绑定时保留；动态业务属性仍随游戏状态刷新。

## 实现与维护

- `GameUiSurface` 读取场景模板或 Resources Prefab，绑定已有节点和组件。
- `PrefabUiNode` 保存稳定绑定标识及原始样式基线，区分美术编辑和动态业务状态。
- `UiPrefabInstance` 在构建结束后恢复编辑属性，并隐藏当前数据状态不需要的可选节点。
- `WorldPrefabFactory` 为方块、怪物、水晶、飞行物创建实例；主场景中已有的世界层级直接复用。
- `EnergyMoteGraphic` 已拆成同名独立脚本，保证 Unity 可以序列化组件引用。
- `PrefabAuthoringTools` 是初始迁移工具；不要对已进行美术编辑的 Prefab 重跑初始生成。
- 现有贴图没有重绘或替换，没有修改 Godot 工程。

本次覆盖 Unity 中已经实现的界面。首波教学、完整胜败结算、最高级成功页等在迁移清单中仍未实现的内容，没有凭空补成可交互界面，继续以 `02_remaining_migration.md` 为准。

## 验证

- `Migration/Reports/PrefabAuthoringV01/FinalRuntime05/prefab-runtime-result.txt`：PASS 3281 检查，覆盖全部 35 个 Prefab 的序列化/脚本引用、主场景启动、界面复用、位置/字号/新增子节点保留、25 个真实方块、预览清理、加载三个子弹窗和停止 Play 生命周期。检查数量包含逐节点检查，不等于独立用例数。
- `Migration/Reports/PrefabAuthoringV01/Regression01/editor-result.txt`：PASS 103497 断言，覆盖原有战斗、波次、水晶、合成、印记、章节、导航、存档与界面回归。含逐帧重复断言。该回归后仅补充 EnergyHudView 销毁对象检查，并在最终运行检查验证停止 Play。
- `Migration/Reports/PrefabAuthoringV01/Commerce01/commerce-result.txt`：PASS 167 检查，覆盖真实 UI 射线命中、确认/取消/失败重试、权益归属、四档存钱罐、重复领取防护和三种比例截图。该轮退出时发现的 EnergyHudView 引用异常已修复，FinalRuntime05 验证停止 Play 通过。
- 最终截图在 `Migration/Reports/PrefabAuthoringV01/FinalRuntime05/`；已目视检查大厅、任务签到、战斗、两类选卡的完整构图，没有重复棋盘或界面整体错位。
- 原有四场景的 Prefab 接入证据：`Migration/Reports/PrefabAuthoringV01/Fixtures01/fixture-prefabs-result.txt`。
- 没有新建 Windows/Android Player 包；真机、触摸输入、性能及完整未迁移流程仍为 pending。

验证在隔离工程 `Migration/Validation/M1Project` 执行。Runtime03 暴露了 Prefab 实例进入 Play 时未记录测试 PathOverride 的问题，一次音效关闭测试写入默认存档；已比较默认存档与备份，确认唯一变化是 Sound=true→false，然后恢复测试前原文件并核对 SHA256 一致。测试触及版本与恢复依据保留在该轮报告目录。验证器现通过 SerializedObject 和 PrefabUtility 记录路径 Override，并断言 Play 后路径正确；最终验证使用报告目录独立存档，结束后默认玩家存档再次核对未变。LoadingVisualVerifier 同步补充了 Prefab Override 记录。

隔离编辑器启动日志中另有 UnityEditor.Search.SearchDatabase 索引初始化异常；保留原始日志，仅将这一已识别的编辑器索引堆栈排除出游戏脚本错误判断，游戏运行与停止 Play 异常仍作为失败处理。

初始修改前的脚本和场景备份：`Migration/Backups/prefab_refactor_v01/`。
