# 当前迁移内容与进度

核对日期：2026-09-13，v01。核对方式：当前 C#、场景和既有报告静态检查；本轮未重新运行游戏测试。

状态含义：**已接入**表示代码和调用链存在；**部分接入**表示仅核心或局部流程完成；**待迁移**表示对应完整实现未发现；**待验收**表示不能认定最终等价通过。历史 PASS 不代表当前工作树全量通过。由于模块工作量不同，不编造总体完成百分比。

|模块|当前内容 / Unity 入口|进度与验证|剩余事项|
|---|---|---|---|
|M0冻结与基准|Migration/Baselines、APPROVAL.md|已批准；源1093项校验记录|保留5项原测试差异；设备手感另验|
|棋盘与合成|Core/BoardModel、BoardRefillPolicy；Runtime/M1BoardDemo、CellView|已接入；M1 v02历史回归|正式新局目前仍用固定棋盘；多指真机|
|连锁/五元素/共鸣|MergeAttack、CombatClock、M2BattleDemo、ResonanceDiagram|已接入；M2 v08历史PASS|真人节奏、字体/声画细节|
|怪物/水晶自动攻击|BattleMonster、MonsterPresentation、MonsterStatusView、CombatHitAudio|已接入出生、死亡、湮灭、命中与状态反馈|水晶附加表现逐项对齐|
|章节12波+续战20波|Core/CampaignFlow；M2BattleDemo.CampaignMode|已接入非教学章节联调；32波核心验证记录|首波教学入口被跳过；端到端分支|
|检查点/重试/复活|M2BattleDemo.CaptureCampaign、RetryChapter、ReviveChapter|已接入；ChapterRecovery历史PASS|正式失败界面及全流程接入|
|节点完成弹窗|Runtime/ChapterNodeView|已接入原资源；ChapterNodeUI02历史PASS|字体、全局层级、安全区|
|能量及水晶选卡|SkillEnergy、CrystalProgress；EnergyHudView、CrystalChoiceView|已接入；CrystalChoiceUI03等历史PASS|视觉细节与全流程奖励恢复|
|六印记|Core/ImprintRules；ImprintChoiceView及战斗执行|已接入；ImprintUI05历史PASS|六种逐一实机、尾迹/爆点视觉|
|即时道具|原版换位与水晶雨等入口|待完整迁移，既有报告明确未完成|执行、HUD次数、存档与防重|
|大厅及顶部HUD|MainHubView、NavigationIntegration、BattleHudView|已接入；Hub03历史PASS|背景安全区、完整新老用户导航|
|暂停/设置/退出|BattlePauseView、NavigationSettingsView、ExitConfirmationView|已接入并有历史导航验证|禁用/销毁生命周期错误复核|
|任务/签到|Core/MetaProgress；DailyProgressView|已接入，领取防重及钱包|日期切换与真机交互验收|
|水晶升级页|Runtime/CrystalUpgradeView|已接入；Crystal02旧PASS；本次层级修复待复测|Canvas 180→1100后真实点击、遮挡、返回验收|
|权益/去广告/存钱罐|MetaProgress具备购买相关核心|部分接入；正式二级页尚未接入|双倍金币/去广告/存钱罐页面与本地模拟交易|
|局外/运行存档|Core/ProfileStore；CampaignPersistence|读写重试、坏档提示、备份/pending恢复、重置归档已接入；既有会话/Meta持久化|教学、即时道具、正式结算等完整模块状态；真机后台强杀|
|正式教学/Loading|LoadingView / 原 first_wave_tutorial_view|Loading已接入实际导航，错误/恢复/清空可交互；教学待迁移|新用户首波、苏醒演出、引导与完成标志|
|正式结算与Z|RunSettlement仅核心；36级棋盘规则已有基础|部分接入；正式视图待迁移|胜败统计、卡组、续战、Z恭喜与返回闭环|
|审核/数值模拟工具|现有Migration差分与验证工具|部分接入|原Godot审核与模拟工具逐项对应|
|适配/构建/性能|部分离屏截图；M1旧Windows包|待整体验收|导航构建入口、Android、低端30/目标60fps、长时间|

以上 Core/Runtime 路径均相对于 `Assets/MergeTo10/`。详细证据见 [验证登记](03_validation_and_maintenance.md)，后续执行顺序见 [待办](02_remaining_migration.md)。

## 当前结论

可进入大厅和非教学章节做模块联调，但不能宣称已完成“新用户启动→教学→第一章→续战→胜败结算→大厅→重启恢复”。M0已批准；M1/M2有实现与回归证据，最终真人等价验收仍待完成；完整功能与全量适配阶段仍在进行中。

## 2026-09-14 更新：权益与存钱罐 v01

双倍金币/去广告共用权益页、存钱罐及购买确认现已接入；U10的正式页面与本地模拟交易已实现。Run13通过167项交互/状态/存档检查，三比例截图已生成；真机验收pending。本更新覆盖前文对应的待接入描述。水晶入口和返回层级亦通过本轮点击回归。详见[迁移交付记录](06_commerce_ui_migration.md)。

## 2026-09-14 更新：加载与本地存档 v01

加载背景/进度/清空确认、读档错误与重试、备份及 pending 恢复、保存失败提示、旧档保护、日期及前后台保存已接入。水晶候选写入存档；旧 v1 的空失败快照兼容。默认构建场景改为 NavigationIntegration。专项 Run04 PASS 60 检查，Visual01 实际场景启动及三比例截图 PASS。当前首启加载完成进入现有大厅；U04 的首次教学分流和 U11 的未迁移模块状态仍 pending，不关闭整项。Player/Android 真机验收 pending。完整文件、资源、证据与后续最终回归见 [加载与本地存档交付](07_loading_and_persistence_migration.md)。

最终代码验证更新：存档专项 Run05 PASS 64 检查；完整编辑器回归 Regression02 PASS 106634 断言（包含逐帧重复断言）。覆盖现有战斗/章节/印记/导航和本轮存档改动。未生成 Player 包，未执行 Android 真机验收。

## 2026-09-15：Unity 场景与界面 Prefab 化 v01

在 `D:/UGit/T0/To` 完成 35 个 Prefab：20 个界面/弹窗、7 个核心/测试入口、2 个棋盘和 6 个战斗对象。NavigationIntegration 与原有四个棋盘/战斗/章节场景使用连接的 Prefab 实例，新增 GameCoreAuthoring 战斗布局编辑场景。运行时绑定已有 UI 层级，保留独立动画父节点、界面编辑属性和业务事件；能量特效拆成可序列化独立脚本，并补充停止 Play 时的销毁检查。使用方法与本轮证据见 [Prefab 编辑说明](08_unity_prefab_authoring.md)。未实现的新手、完整结算等迁移项继续 pending；没有新增 Player 构建或真机验收。