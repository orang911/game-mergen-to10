# 加载页与本地存档迁移 v01

日期：2026-09-14。任务分类：精确编辑/迁移。冻结版 `scripts/loading_view.gd`、`scenes/ui/loading_view.tscn`、`scripts/main_game.gd` 为 LAYOUT_REFERENCE / CONTENT_REFERENCE。复用原资源，没有重新设计、切图或 AI 生图。

## 运行入口与完成内容

Unity 工程 `D:/UGit/T0/To`，菜单 `Merge To 10/Open Navigation Integration`，进入 Play。旧导航场景运行时自动补齐 LoadingView。默认 EditorBuildSettings 已从 SampleScene 改为 NavigationIntegration；配置和实际场景启动已验证，尚未生成本轮 Player 包。

- 原背景 cover 铺满；941×1672 控件等比居中。原进度轨道与填充独立，按原 2.5 秒三阶段曲线及 0.18 秒淡出显示；存档未就绪时不提前进入。加载与确认期间战斗不推进，输入被遮挡。
- 清空本地数据入口、二次确认、取消继续、确认后重新加载。清空仅作用于当前 Unity 存档及其 backup/pending；旧文件先保存在同目录 `.reset_<id>` 归档。测试只使用报告目录内的测试档，未清空用户实际存档。
- 缺失档建立新档；新导航用户钱包沿用 Godot 的 1804 金币、120 水晶；已有 Unity 用户余额保持原档。纯战斗联调场景动态添加存档组件时保留其现有状态。
- 主档 SHA256 与版本校验，再验证 Meta、当前章节、检查点、失败快照。有效备份/完整 pending 可恢复，恢复显示提示；全部无效时停留在加载错误页，可重试或再次确认清空，不静默创建新局。
- 恢复后修复主档前保留损坏原件；语义损坏主档不会覆盖有效备份。兼容 JsonUtility 将可选 null 快照写成空对象的旧 v1 文件。
- 保存采用 pending 写入与 flush，再原子替换，保留上一有效备份。状态变更请求保存，稳定状态下每 2 秒检查；失焦、切后台、退出时尝试保存。合成/冻结/复活期间延后到稳定点，不能保证强杀时保存尚未结束的演出。
- 保存失败显示常驻提示和重试按钮，保留内存状态及旧档；日期在启动、回到前台及运行检查时同步。任务、签到、钱包、权益、存钱罐、设置、卡片及章节数据沿用现有模型持久化。
- 水晶奖励三个候选加入同一存档，恢复保留候选顺序，避免重启重新抽选。

存档路径：`Application.persistentDataPath/unity_campaign_v1.json`，备份为 `.backup`，待提交文件为 `.pending`。不读取、转换或写入 Godot 玩家存档；没有真实支付或广告 SDK。

## 实际修改

- `Assets/MergeTo10/Runtime/LoadingView.cs`：加载、确认、恢复/错误反馈。
- `Assets/MergeTo10/Runtime/NavigationIntegration.cs`：等待加载与存档后进入现有大厅。
- `Assets/MergeTo10/Runtime/CampaignPersistence.cs`：读写、重试、重置、日期、前后台保存。
- `Assets/MergeTo10/Core/ProfileStore.cs`：校验、备用记录恢复、原件归档及清空事务。
- `Assets/MergeTo10/Runtime/M2BattleDemo.cs`：递归快照验证、空对象兼容、水晶候选保存。
- `ProjectSettings/EditorBuildSettings.asset`：导航场景入口。
- `Assets/MergeTo10/Editor/LoadingPersistenceVerifier.cs`、`LoadingVisualVerifier.cs`，`Migration/Tools/ValidateLoadingPersistence.ps1`：隔离验证与截图工具。

## 资源与 QA

本轮经用户明确同意，截图/QA 保存到 `D:/UGit/T0/To/Migration/Reports/LoadingPersistence/2026-09-14_v01/`（当前机器无 F:）。未移动历史产物。

|原样迁入资源（完整路径）|像素与 Alpha|文字/光影|九宫格与锚点|
|---|---|---|---|
|D:/UGit/T0/To/Assets/MergeTo10/Resources/Campaign/loading_background_clean_hd_941x1672_v01.png|941×1672，RGB，无 Alpha|含原画 Core Warden Logo；不含进度文字；含原画光影|无九宫格；中心 cover|
|D:/UGit/T0/To/Assets/MergeTo10/Resources/Campaign/ui_loading_track_empty_576x48_1x_v01.png|576×48，RGBA|无字；保留原描边、高光|无九宫格，固定576×48，Sprite中心|
|D:/UGit/T0/To/Assets/MergeTo10/Resources/Campaign/ui_loading_fill_green_full_576x48_1x_v01.png|576×48，RGBA|无字；保留原渐变、高光|无九宫格，原尺寸裁切显示，Sprite中心|

原资源 SHA256 与尺寸：`Migration/Reports/LoadingPersistence/2026-09-14_v01/assets_manifest.json`。无新效果图、无新无字生产图、无新透明切图；上表是复用运行资源。

进度区左上 `(182.5,1420)`，576×48；百分比同矩形；加载文案 `(182.5,1485,576,48)`；清空入口 `(24,1594,166,48)`。文字均程序绘制，弹窗标题和正文分别位于局部 `(20,16,580,50)`、`(32,78,556,144)`，按钮位于下方独立区域。确认框 620×320、居中。弹窗使用程序矩形，无九宫格图片。

白/灰/黑边缘 QA：`D:/UGit/T0/To/Migration/Reports/LoadingPersistence/2026-09-14_v01/loading_edges_white_gray_black.png`。目视保留完整边缘，无新增杂边/白毛边/背景残留。原图深色细轮廓和柔边保留，未重新抠图。

最终三比例实际 Unity 场景截图位于 `D:/UGit/T0/To/Migration/Reports/LoadingPersistence/2026-09-14_v01/Visual02/`：`06_loading.png`（941×1672）、`05_loading_tall.png`（720×1600）、`04_loading_tablet.png`（768×1024）；确认框为 `01_clear_confirmation.png`、`02_clear_confirmation_tall.png`、`03_clear_confirmation_tablet.png`；加载后大厅为 `07_hub_after_loading.png`。Visual02 已关闭编辑器 Gizmo，目视核对布局、文字及遮罩；截图透明通道非交付素材用途。窄高/平板按源 cover 裁切背景，控件保持完整。字体使用已有 Noto 700，与 Godot 系统字体存在字形差异，不宣称逐像素一致。

## 验证与剩余边界

- 专项最终 `Run05/loading-persistence-result.txt`：PASS 64 检查。含真实 UI raycast 的确认/取消/重试、重复启动、主档/备份/pending、坏档不覆盖、保存失败重试、清空归档和恢复导航；补充验证水晶候选与顺序、冻结延后保存及切后台保存。
- 实际 NavigationIntegration 场景最终 `Visual02/loading-visual-result.txt`：PASS，生成 941×1672、720×1600、768×1024 截图。
- 现有完整编辑器战斗/导航回归 `Regression02/editor-result.txt`：PASS 106634 断言，包含大量逐帧检查，不代表独立用例数量。Run01–Run03、Regression01 是诊断或失败记录，不用作最终通过依据。
- 本轮接通加载到现有大厅；首波教学/水晶苏醒尚未迁移，首次用户自动进入教学的分流仍 pending（U05）。没有将“进入大厅”宣称为已完成新手闭环。
- U11 仍有依赖：未迁移教学、即时道具、正式结算等模块的完整状态边界继续待办。现有模型以外的新手记录没有凭空新增完成标志。
- Android 真实触摸、安全区、后台进程终止、性能、长时间运行、Player 构建为 pending。

工具：本地 C#/PowerShell、Unity 6000.3.11f1；无 AI 生成工具，提示词不适用。

已知环境问题：Unity Editor SearchDatabase 启动索引异常仍出现在部分验证日志，属于已有编辑器问题；本轮未修复该编辑器设施。测试没有将它计为游戏功能通过。运行时受测流程未出现 MergeTo10 异常。
