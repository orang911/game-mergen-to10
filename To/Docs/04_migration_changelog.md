# 迁移变更记录

## 2026-09-13 / 文档迁移 v01

- 在 Unity 根目录建立 Docs，提供当前基线、模块进度、剩余清单、证据登记、原文档索引。
- 将活动 Godot 工程 docs 全目录及 AGENTS.md、MIGRATION_GODOT.md、PROJECT_DIRECTION.md 原样复制到 LegacyGodot/2026-09-13_v01；逐文件SHA256校验见清单。
- 既有 Migration 批次报告、批准记录、冻结源和测试报告保持原位置；新文档引用其证据并解决新旧状态混用。
- 核实正式新局仍用固定棋盘、章节入口跳过教学首波、默认构建仍为 SampleScene，将这些列为待迁移项。
- 本次只新增文档和原文备份，不更改游戏场景、玩法、资源、存档或构建设置；未执行运行测试。

## 2026-09-13 / 水晶界面显示修复

- 问题：大厅水晶入口创建页面，但水晶 Canvas 的180层级低于大厅1000，被大厅遮挡。
- 改动：CrystalUpgradeView.cs 将层级改为1100；M2EditorTools.cs 加入水晶层级必须高于大厅的断言。
- 验证：已核对修改写入；当前修复后的编辑器回归、真实点击、截图均为 pending。Crystal02属于旧证据，不用于关闭该问题。

## 历史批次导航

- [棋盘v02](../Migration/M1_V02_REPORT.md)
- [战斗反馈v08](../Migration/M2_FEEDBACK_V08.md)
- [章节、印记、存档连续批次](../Migration/M3_M9_BATCH.md)
- [大厅与HUD](../Migration/HUB_HUD_INTEGRATION.md)

历史报告中逐批“未完成”描述需要结合其后续章节阅读；当前统一结论在进度总表。

## 2026-09-14 更新：权益与存钱罐 v01

双倍金币/去广告共用权益页、存钱罐及购买确认现已接入；U10的正式页面与本地模拟交易已实现。Run13通过167项交互/状态/存档检查，三比例截图已生成；真机验收pending。本更新覆盖前文对应的待接入描述。水晶入口和返回层级亦通过本轮点击回归。详见[迁移交付记录](06_commerce_ui_migration.md)。

## 2026-09-14 更新：加载与本地存档 v01

加载背景/进度/清空确认、读档错误与重试、备份及 pending 恢复、保存失败提示、旧档保护、日期及前后台保存已接入。水晶候选写入存档；旧 v1 的空失败快照兼容。默认构建场景改为 NavigationIntegration。专项 Run04 PASS 60 检查，Visual01 实际场景启动及三比例截图 PASS。当前首启加载完成进入现有大厅；U04 的首次教学分流和 U11 的未迁移模块状态仍 pending，不关闭整项。Player/Android 真机验收 pending。完整文件、资源、证据与后续最终回归见 [加载与本地存档交付](07_loading_and_persistence_migration.md)。

最终代码验证更新：存档专项 Run05 PASS 64 检查；完整编辑器回归 Regression02 PASS 106634 断言（包含逐帧重复断言）。覆盖现有战斗/章节/印记/导航和本轮存档改动。未生成 Player 包，未执行 Android 真机验收。

## 2026-09-15：Unity 场景与界面 Prefab 化 v01

在 `D:/UGit/T0/To` 完成 35 个 Prefab：20 个界面/弹窗、7 个核心/测试入口、2 个棋盘和 6 个战斗对象。NavigationIntegration 与原有四个棋盘/战斗/章节场景使用连接的 Prefab 实例，新增 GameCoreAuthoring 战斗布局编辑场景。运行时绑定已有 UI 层级，保留独立动画父节点、界面编辑属性和业务事件；能量特效拆成可序列化独立脚本，并补充停止 Play 时的销毁检查。使用方法与本轮证据见 [Prefab 编辑说明](08_unity_prefab_authoring.md)。未实现的新手、完整结算等迁移项继续 pending；没有新增 Player 构建或真机验收。