# Unity 当前工程基线

日期：2026-09-13，v01。

## 工程及来源

- Unity 工程：`D:/UGit/T0/To`；原活动工程：`D:/UGit/UGit/TO10`。
- 已批准迁移基线：`Migration/Baselines/godot_2026-09-11_v01/Source`。批准事实见 [APPROVAL](../Migration/APPROVAL.md)，冻结源只读。
- 本次复制的原项目文档是 2026-09-13 活动目录快照，不自动替换 2026-09-11 已批准运行基线。
- 引擎版本以 [ProjectVersion.txt](../ProjectSettings/ProjectVersion.txt) 为准：6000.3.11f1。现有迁移约定为 URP、正交相机、场景精灵棋盘及 Canvas UI。

## 当前运行入口

|用途|场景|说明|
|---|---|---|
|大厅和战斗导航联调|[NavigationIntegration](../Assets/MergeTo10/Scenes/NavigationIntegration.unity)|Unity 菜单 `Merge To 10/Open Navigation Integration`；大厅、水晶、任务签到、暂停等；不是全流程完成版|
|章节联调|[ChapterIntegration](../Assets/MergeTo10/Scenes/ChapterIntegration.unity)|`Merge To 10/Open Chapter Integration`；包含章节/卡牌/存档组件|
|旧20波测试|[M2WaveBattle](../Assets/MergeTo10/Scenes/M2WaveBattle.unity)|`Merge To 10/Open M2 Wave Battle`；不能替代正式第一章|
|战斗差分测试|[M2BattleParity](../Assets/MergeTo10/Scenes/M2BattleParity.unity)|五元素等测试入口|
|棋盘差分测试|[M1BoardParity](../Assets/MergeTo10/Scenes/M1BoardParity.unity)|M1 棋盘回归入口|

2026-09-14：`ProjectSettings/EditorBuildSettings.asset` 首场景已改为 NavigationIntegration，启动先经过加载及存档处理。实际场景在编辑器验证通过，Player 构建与真机仍 pending；首波教学尚未接入，加载后进入现有大厅。详见 [加载与本地存档交付](07_loading_and_persistence_migration.md)。

## 运行模块

- `Assets/MergeTo10/Core/`：棋盘、补块、攻击、时钟、怪物、章节、能量、印记、水晶、Meta、存档及结算规则。
- `Assets/MergeTo10/Runtime/`：视图、真实战斗执行、导航、章节门、存档接入。
- `Assets/MergeTo10/Resources/`：当前已迁入资源与导出的运行配置。
- `Assets/MergeTo10/Editor/M2EditorTools.cs`：创建/打开测试场景及隔离编辑器验证。
- `Migration/Tools/`、`Migration/Reports/`：迁移工具和历史证据。

## 产品约束

保留 5×5、单击合成、最多五次连锁、冻结战斗、原五元素发射顺序与共鸣规则。941×1672设计坐标，路径、棋盘、HUD及色彩身份按确认基线复现。当前基础比例缩放不等于安全区和真机已验收。

Unity 使用 `Application.persistentDataPath/unity_campaign_v1.json`，不转换或覆盖 Godot 玩家存档。保留异常原文件及备份，不能把恢复失败静默处理为新局。

水晶升级页按源行为保持静态等级/材料预览与禁用升级按钮，顶部钱包动态绑定；不因“迁移完整”新增永久升级或扣费。首充禁用、商店未解锁保持原边界；真实支付/广告 SDK 不属于现有迁移内容。
## 2026-09-15：Unity 场景与界面 Prefab 化 v01

在 `D:/UGit/T0/To` 完成 35 个 Prefab：20 个界面/弹窗、7 个核心/测试入口、2 个棋盘和 6 个战斗对象。NavigationIntegration 与原有四个棋盘/战斗/章节场景使用连接的 Prefab 实例，新增 GameCoreAuthoring 战斗布局编辑场景。运行时绑定已有 UI 层级，保留独立动画父节点、界面编辑属性和业务事件；能量特效拆成可序列化独立脚本，并补充停止 Play 时的销毁检查。使用方法与本轮证据见 [Prefab 编辑说明](08_unity_prefab_authoring.md)。未实现的新手、完整结算等迁移项继续 pending；没有新增 Player 构建或真机验收。