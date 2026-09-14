# 晶核守卫 Unity 工程文档入口

更新：2026-09-13，v01。工程：`D:/UGit/T0/To`，Unity `6000.3.11f1`。

当前为迁移联调工程，棋盘、战斗、章节核心、部分正式 UI 和存档已接入；完整新手到结算闭环尚未完成。文件迁入、代码实现、测试通过、真人验收是四个不同状态。

## 阅读顺序

1. [当前工程基线与运行入口](00_unity_project_baseline.md)
2. [迁移内容与进度总表](01_migration_status.md)
3. [待迁移与验收清单](02_remaining_migration.md)
4. [验证证据与更新规则](03_validation_and_maintenance.md)
5. [迁移变更记录](04_migration_changelog.md)

## 原文档与历史证据

- [Godot 文档迁移说明与索引](05_legacy_document_map.md)：原文原样复制，含策划、数值、美术、资源清单及历史方案。
- [Godot 原文档目录](LegacyGodot/2026-09-13_v01/docs/README.md)：其中“当前状态”指原 Godot 工程，不代表 Unity 已实现。
- [已有 Unity 批次报告入口](../Migration/README.md)：保留历史记录；当前状态以本目录汇总为入口，旧报告中已被后续批次覆盖的“待迁移”不直接沿用。
- [批准记录](../Migration/APPROVAL.md)、[行为契约](../Migration/BEHAVIOR_CONTRACT.md)、[原版已知差异](../Migration/BASELINE_FINDINGS.md)。M0 已批准；旧报告中待批准文字是历史状态。

## 事实优先级

用户最新明确要求 → 已批准 Godot 冻结源码及确认效果 → 当前 Unity 代码与实际验证结果 → 本目录进度表 → 历史迁移报告 → 原项目概述和历史提案。
目标行为与 Unity 实现不一致时登记差异，不把当前实现自动视为正确目标。旧的两次点击合成等描述不能覆盖已冻结的单击和连锁规则。

本目录只管理文档；不将 Godot 的 `res://`、`.tscn`、`assets/runtime` 或 F 盘旧路径当作 Unity 可直接使用的工程路径。

## 2026-09-14 更新：权益与存钱罐 v01

双倍金币/去广告共用权益页、存钱罐及购买确认现已接入；U10的正式页面与本地模拟交易已实现。Run13通过167项交互/状态/存档检查，三比例截图已生成；真机验收pending。本更新覆盖前文对应的待接入描述。水晶入口和返回层级亦通过本轮点击回归。详见[迁移交付记录](06_commerce_ui_migration.md)。

## 2026-09-14 更新：加载与本地存档 v01

加载背景/进度/清空确认、读档错误与重试、备份及 pending 恢复、保存失败提示、旧档保护、日期及前后台保存已接入。水晶候选写入存档；旧 v1 的空失败快照兼容。默认构建场景改为 NavigationIntegration。专项 Run04 PASS 60 检查，Visual01 实际场景启动及三比例截图 PASS。当前首启加载完成进入现有大厅；U04 的首次教学分流和 U11 的未迁移模块状态仍 pending，不关闭整项。Player/Android 真机验收 pending。完整文件、资源、证据与后续最终回归见 [加载与本地存档交付](07_loading_and_persistence_migration.md)。

## 2026-09-15：Unity 场景与界面 Prefab 化 v01

在 `D:/UGit/T0/To` 完成 35 个 Prefab：20 个界面/弹窗、7 个核心/测试入口、2 个棋盘和 6 个战斗对象。NavigationIntegration 与原有四个棋盘/战斗/章节场景使用连接的 Prefab 实例，新增 GameCoreAuthoring 战斗布局编辑场景。运行时绑定已有 UI 层级，保留独立动画父节点、界面编辑属性和业务事件；能量特效拆成可序列化独立脚本，并补充停止 Play 时的销毁检查。使用方法与本轮证据见 [Prefab 编辑说明](08_unity_prefab_authoring.md)。未实现的新手、完整结算等迁移项继续 pending；没有新增 Player 构建或真机验收。