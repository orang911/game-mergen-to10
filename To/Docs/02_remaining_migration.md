# 待迁移内容与验收清单

日期：2026-09-13，v01。全部未勾选项均未最终完成；已存在核心的模块只补缺口，不重做玩法。P0先保证可进入/可退出，P1补完整流程，P2完成等价与设备交付。此清单为后续实施记录，不表示本次已执行。

|ID/优先级|具体工作及源入口|依赖|完成标准|状态|
|---|---|---|---|---|
|U01/P0|水晶页层级修复，CrystalUpgradeView|当前1100层级改动|通过大厅真实按钮显示在大厅上层；返回可点；重复进出无重复Canvas；新回归PASS|代码已修，验证pending|
|U02/P0|BattleHudView.OnDisable生命周期|Editor.log历史MissingReferenceException|销毁/停止Play/切场景不访问已销毁GameObject；无相关异常|待复核修复|
|U03/P0|构建入口与联调说明|NavigationIntegration场景|隔离构建确实启动所选场景；不误用SampleScene；不覆盖未保存场景|默认场景已配置，实际编辑器启动PASS；Player构建pending|
|U04/P1|启动Loading、新老用户分流；main_game.gd|导航/存档|新用户到首波教学；老用户到大厅；加载失败可见|Loading/错误重试/清空/大厅已接入；首次教学分流依赖U05|
|U05/P1|首波教学、水晶苏醒、印记阶段引导；first_wave_tutorial_view.gd|U04、章节门|按原版限制操作/顺序演出；可保存恢复；不跳过索引0|待迁移|
|U06/P1|正式新局棋盘；main_game.gd、board_refill_policy.gd|教学初盘约束|移除正式流程固定fixture；保持回归fixture可用；随机调用/质量策略对齐|待迁移|
|U07/P1|胜败结算、卡组、章节到续战；settlement_view.gd、main_game.gd|现有RunSettlement/检查点|奖励只提交一次；重试/复活/返回/续战全按钮可走通|核心有，视图与闭环待接|
|U08/P1|36级Z流程；max_level_success_view.gd|棋盘移除补块|原移除、补充、恭喜页顺序；继续后输入恢复|视图待迁移|
|U09/P1|即时道具；energy_hud.gd及main_game.gd对应逻辑|能量HUD/战斗/存档|换位、水晶雨按源执行；次数/暂停/消耗/恢复防重|待迁移|
|U10/P1|权益、去广告、存钱罐；secondary_ui_controller.gd|MetaProgress|大厅入口可点；页面/限购/本地模拟交易/钱包刷新与退出一致；无真实SDK|核心有，界面待接|
|U11/P1|全流程存档、坏档错误界面；main_game.gd及meta_progress_service.gd|U04–U10|教学/奖励/道具/失败/续战各边界往返；备份恢复与失败提示；不修改Godot旧档|坏档/备份/pending/读写重试/清空/生命周期已接入；未迁移模块闭环pending|
|U12/P2|六印记、水晶和共鸣表现对照；effect_system.gd等|相关玩法接入|六种逐一测试，尾迹/爆点/混合/字体/音频与确认基线对照|待验收补齐|
|U13/P2|全UI层级、安全区、多比例；ui_global_review.gd及capture_global_ui_audit.gd|全部正式页面|状态清单逐页截图；弹窗遮挡/穿透/返回、窄高屏/平板/安全区验收|待整体验收|
|U14/P2|数值模拟与审核工具；scripts/simulation、tools|冻结数据与Unity配置|建立逐工具映射，运行同输入对照；列出无法迁移项及替代验证|待盘点迁移|
|U15/P2|发布与完整回归|上述核心闭环|无调试入口泄露；全章节/续战/异常恢复/长时间；Android触摸与30/60fps证据|pending|

## 不作为缺失功能补做

不开放原本禁用的首充或锁定商店，不新增真实支付/广告SDK，不把静态水晶预览变成新永久升级系统，不转换玩家Godot旧存档，不修改已冻结源。后续新需求单独记录。

## 每项交付记录

`ID | 日期 | 实际改动文件 | 原版依据 | 自动验证输出 | 人工/设备验证 | 遗留项 | 状态`。
只有全部完成标准都有证据时，才改成“完成”；单纯导入图片或有脚本不能关闭对应条目。

## 2026-09-14 更新：权益与存钱罐 v01

双倍金币/去广告共用权益页、存钱罐及购买确认现已接入；U10的正式页面与本地模拟交易已实现。Run13通过167项交互/状态/存档检查，三比例截图已生成；真机验收pending。本更新覆盖前文对应的待接入描述。水晶入口和返回层级亦通过本轮点击回归。详见[迁移交付记录](06_commerce_ui_migration.md)。

## 2026-09-14 更新：加载与本地存档 v01

加载背景/进度/清空确认、读档错误与重试、备份及 pending 恢复、保存失败提示、旧档保护、日期及前后台保存已接入。水晶候选写入存档；旧 v1 的空失败快照兼容。默认构建场景改为 NavigationIntegration。专项 Run04 PASS 60 检查，Visual01 实际场景启动及三比例截图 PASS。当前首启加载完成进入现有大厅；U04 的首次教学分流和 U11 的未迁移模块状态仍 pending，不关闭整项。Player/Android 真机验收 pending。完整文件、资源、证据与后续最终回归见 [加载与本地存档交付](07_loading_and_persistence_migration.md)。

最终代码验证更新：存档专项 Run05 PASS 64 检查；完整编辑器回归 Regression02 PASS 106634 断言（包含逐帧重复断言）。覆盖现有战斗/章节/印记/导航和本轮存档改动。未生成 Player 包，未执行 Android 真机验收。

## 2026-09-15：Unity 场景与界面 Prefab 化 v01

在 `D:/UGit/T0/To` 完成 35 个 Prefab：20 个界面/弹窗、7 个核心/测试入口、2 个棋盘和 6 个战斗对象。NavigationIntegration 与原有四个棋盘/战斗/章节场景使用连接的 Prefab 实例，新增 GameCoreAuthoring 战斗布局编辑场景。运行时绑定已有 UI 层级，保留独立动画父节点、界面编辑属性和业务事件；能量特效拆成可序列化独立脚本，并补充停止 Play 时的销毁检查。使用方法与本轮证据见 [Prefab 编辑说明](08_unity_prefab_authoring.md)。未实现的新手、完整结算等迁移项继续 pending；没有新增 Player 构建或真机验收。