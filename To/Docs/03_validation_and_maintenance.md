# 验证证据与文档维护

日期：2026-09-13，v01。本次仅检查文档和文件存在性、复制哈希、当前代码；没有重跑下列历史测试。

## 已核对存在的历史证据

|证据|记录|适用范围与限制|
|---|---|---|
|[M0批准](../Migration/APPROVAL.md)|用户2026-09-11确认|覆盖旧文档“待批准”状态|
|[M1 v02报告](../Migration/M1_V02_REPORT.md)|棋盘/旧Windows/比例测试|不代表完整Unity游戏|
|[M2 v08结果](../Migration/Reports/M2FeedbackV08/Final/editor-result.txt)|PASS 98364断言|战斗/表现历史版本|
|[章节基础](../Migration/Reports/M3M9/Foundation06/campaign-core.txt)|PASS 32波等核心|不是全流程UI验收|
|[印记与磁盘](../Migration/Reports/M3M9/ImprintUI05/editor-result.txt)|PASS 117058断言|历史会话/印记回归|
|[大厅导航](../Migration/Reports/Navigation/Hub03/editor-result.txt)|PASS 101066断言|历史大厅/暂停/任务等|
|[水晶旧结果](../Migration/Reports/Navigation/Crystal02/editor-result.txt)|PASS 106397断言|早于本次层级修复，不能证明水晶当前可见/可点击|

断言数包含大量逐帧重复检查，不等于独立用例数。报告中的 PASS 仅证明当时覆盖到的断言。水晶页面此前虽然创建成功，仍被大厅盖住，说明需要同时验证真实可见性与输入。

## 复测入口

[ValidateM2Editor.ps1](../Migration/Tools/ValidateM2Editor.ps1) 将 Assets/Packages/ProjectSettings 同步到隔离验证工程并运行 Unity Editor 验证。执行前阅读脚本，使用新的 OutputDirectory 保存证据，避免覆盖历史报告；保留用户打开的主工程及未保存场景。

水晶补充断言位于 [M2EditorTools.cs](../Assets/MergeTo10/Editor/M2EditorTools.cs)，比较水晶和大厅 Canvas.sortingOrder。仍须真人点击入口和返回，不能以直接调用 EntryRequested 代替全部交互检查。测试后登记日志、截图和具体版本；未执行写 pending。

## 维护约定

1. 每次迁移同时更新 `01_migration_status.md`、`02_remaining_migration.md` 和 `04_migration_changelog.md`。
2. 状态附带代码入口、源依据、证据路径和未验收项；当前代码变化后，旧测试标为历史证据。
3. 旧 Godot 文档保留原文；新结论写本目录，不回改原文使历史失真。
4. 后续复制新快照采用新日期/版本，并生成 SHA256 清单，不覆盖来源不明文件。
5. 原美术规范仍是视觉生产依据，但 Godot NinePatch/TextureRect/.import 等步骤需要单独映射到 Unity Sprite/Canvas/导入设置；本次文档迁移未执行任何资源替换。
6. 运行时数值维护在代码/配置，不手抄第二套数值表作为运行事实。

## 2026-09-14 更新：权益与存钱罐 v01

双倍金币/去广告共用权益页、存钱罐及购买确认现已接入；U10的正式页面与本地模拟交易已实现。Run13通过167项交互/状态/存档检查，三比例截图已生成；真机验收pending。本更新覆盖前文对应的待接入描述。水晶入口和返回层级亦通过本轮点击回归。详见[迁移交付记录](06_commerce_ui_migration.md)。

## 2026-09-14 更新：加载与本地存档 v01

加载背景/进度/清空确认、读档错误与重试、备份及 pending 恢复、保存失败提示、旧档保护、日期及前后台保存已接入。水晶候选写入存档；旧 v1 的空失败快照兼容。默认构建场景改为 NavigationIntegration。专项 Run04 PASS 60 检查，Visual01 实际场景启动及三比例截图 PASS。当前首启加载完成进入现有大厅；U04 的首次教学分流和 U11 的未迁移模块状态仍 pending，不关闭整项。Player/Android 真机验收 pending。完整文件、资源、证据与后续最终回归见 [加载与本地存档交付](07_loading_and_persistence_migration.md)。

最终代码验证更新：存档专项 Run05 PASS 64 检查；完整编辑器回归 Regression02 PASS 106634 断言（包含逐帧重复断言）。覆盖现有战斗/章节/印记/导航和本轮存档改动。未生成 Player 包，未执行 Android 真机验收。

最终截图更新：Visual02 实际场景验证 PASS，已关闭编辑器 Gizmo；三比例加载/确认及大厅截图完成目视 QA。完整路径见 Docs/07_loading_and_persistence_migration.md。

## 2026-09-15：Unity 场景与界面 Prefab 化 v01

在 `D:/UGit/T0/To` 完成 35 个 Prefab：20 个界面/弹窗、7 个核心/测试入口、2 个棋盘和 6 个战斗对象。NavigationIntegration 与原有四个棋盘/战斗/章节场景使用连接的 Prefab 实例，新增 GameCoreAuthoring 战斗布局编辑场景。运行时绑定已有 UI 层级，保留独立动画父节点、界面编辑属性和业务事件；能量特效拆成可序列化独立脚本，并补充停止 Play 时的销毁检查。使用方法与本轮证据见 [Prefab 编辑说明](08_unity_prefab_authoring.md)。未实现的新手、完整结算等迁移项继续 pending；没有新增 Player 构建或真机验收。