# Godot → Unity 6 等价迁移

目标工程：D:/UGit/T0/To。源工程：D:/UGit/UGit/TO10。

## 已确认约束

- Unity 6000.3.11f1、URP 17.3.0；Universal Renderer＋正交相机。
- 棋盘与战场使用场景精灵，普通界面使用 Canvas；不引入新3D美术或玩法。
- 941×1672设计坐标，整体等比缩放居中，背景独立铺满；逐页复现原有布局。
- 完整迁移当前运行功能，Unity 使用新存档；不转换玩家 Godot 旧档。
- Android＋Windows；60帧目标、低端30帧验证。
- 原版缺陷单独登记，未经审核不修正玩法、适配或手感。

## 里程碑与审核门

M0：冻结含未提交改动的运行源码、配置、资源与测试，建立校验清单、基准包和行为参数表。用户确认基准包后才将其标记为 APPROVED。

M1：精灵棋盘、输入、布局、下落补块、连锁及高亮；以M0行为为准。

M2：五元素、共鸣、怪物/水晶、暂停、弹道命中及完整战斗小样；同机对照手感。

M3：教学、章节、续战、卡牌、UI、局外及存档；迁移现有审核和数值模拟工具。

M4：全量差分测试、多比例、真机性能、异常恢复、长时间运行及用户验收。

## 当前状态

最新补齐 v08：真实湮灭分支已显示中文提示和0.16秒局部闪光；电击位移/角度按原版帧时间平滑回正，死亡立即归零。最终隔离编辑器回归与湮灭截图检查通过，无Windows包。中文采用可分发Noto子集，设备间字形与真人手感仍待对照。见 [M2_FEEDBACK_V08.md](M2_FEEDBACK_V08.md)。

最新战斗反馈 v07：实际伤害跳字、火焰汇总反馈、三类状态叠层标记、冰冻染色、电击黑白闪烁与抖动、火/暴击后仰、原版四声部命中音效已接入。最终编辑器回归通过，无Windows包；湮灭表现、旋转恢复和真人声画手感等仍待本轮收尾，不标为第2轮完全验收。详见 [M2_FEEDBACK_V07.md](M2_FEEDBACK_V07.md)。

最新表现 v06：合鸣底盘、原版字体与描边、错峰渐入/脉冲/淡出、四元素拖尾与散落粒子、闪电序列及怪物间连线已接入。最终隔离Unity编辑器回归通过，新增暂停/重置清理检查通过；字体栅格化、并行动画与真人声画手感仍待对照。入口不变，不打Windows包。详见 [M2_RESONANCE_V06.md](M2_RESONANCE_V06.md)。

最新表现 v05：三种及以上元素显示原版圆环/固定五角连线，同元素用单图标＋×N显示贡献次数。已完成实际截图检查及隔离编辑器回归，不打Windows包。字体描边、图标底盘和渐入脉冲尚未完成。详情见 [M2_RESONANCE_V05.md](M2_RESONANCE_V05.md)。

最新表现 v04：六类原版命中序列帧已接实际伤害落点，播放清理及重置取消检查通过。继续使用 M2WaveBattle.unity，仅Unity编辑器验证，不打Windows包。详见 [M2_IMPACTS_V04.md](M2_IMPACTS_V04.md)。

最新表现阶段 v03：原版出生缩放、19帧死亡和2.5倍速湮灭死亡已接入；尸体不参与存活/选敌，合成冻结不阻塞死亡演出，重置清理通过。仍使用 M2WaveBattle.unity 在Unity内测试，无Windows包。见 [M2_PRESENTATION_V03.md](M2_PRESENTATION_V03.md)。

最新阶段：M2WaveBattle.unity 已接默认20波分批刷怪与一级水晶自动攻击，保留清场继续入口和合成冻结/取消。菜单 Merge To 10 → Open M2 Wave Battle。仅编辑器测试，不打Windows包；章节、奖励升级与完整特效尚未完成。详情见 [M2_WAVES_V02.md](M2_WAVES_V02.md)。

最新编辑器入口：Assets/MergeTo10/Scenes/M2BattleParity.unity，或菜单 Merge To 10 → Open M2 Combat Test。本轮按用户要求不再生成Windows测试包，改为Unity Play Mode验证。已加入怪物测试阵列、真实合成冻结、固定槽发射、元素命中和基础状态；正式波次、水晶自动攻击和完整特效未完成。操作与边界见 [M2_EDITOR_V01.md](M2_EDITOR_V01.md)。下方为之前里程碑记录。

M2 已开始：本轮迁移五元素合成快照、同类聚合、倍率、双时钟基础和棋盘异步结算接口；23,085项战斗基础检查及34项接口运行检查通过，旧棋盘14,079项回归和470×836实际运行通过。详情见 [M2_FOUNDATION_REPORT.md](M2_FOUNDATION_REPORT.md)。怪物、弹道、状态效果和完整战斗运行器尚未接入，不能将此称为M2可玩战斗包。

M0 已获用户确认（见 APPROVAL.md），M1 最新为 v02：补齐统一阴影、残影和入场错峰时序，Windows 构建、14,079 项断言、三种比例与默认图形后端实际运行通过。最新程序位于 Builds/M1V02，详情见 [M1_V02_REPORT.md](M1_V02_REPORT.md)。完整等价验收尚未完成。原 SampleScene 保留；进入 Assets/MergeTo10/Scenes/M1BoardParity.unity 后按 Play。完整 Unity 游戏尚未迁移完成，战斗及完整 UI 未接入。
Baselines/godot_2026-09-11_v01/Source 是逐文件校验的源快照，禁止直接编辑；WorkingGodot 仅用于隔离存档的基准测试与打包。
禁止把已生成Godot基准包描述成Unity包；测试通过不代表真人手感验收通过。

## 本轮结果入口

- [Godot安卓基准包](Baselines/godot_2026-09-11_v01/Builds/MergeTo10_GodotBaseline_20260911.apk)：独立包名，可与原测试版共存，使用新测试存档。
- [Godot Windows便携对照包](Baselines/godot_2026-09-11_v01/Builds/MergeTo10_GodotBaseline_Windows.zip)：解压后运行MergeTo10Baseline.exe，不能只拷贝exe漏掉PCK。
- [冻结副本重新生成的35状态图册](Baselines/godot_2026-09-11_v01/WorkingGodot/builds/ui_audit/2026-09-11_v02_runtime_baseline/README.md)。图册日期文字沿用原工具；本轮生成依据是当前冻结代码和capture日志。
- [原版测试结果](Baselines/godot_2026-09-11_v01/Reports/tests.md)：33/38通过；5项失败及诊断见[差异记录](BASELINE_FINDINGS.md)。
- [手感与规则契约](BEHAVIOR_CONTRACT.md)。
- [合成/五元素视觉参考录像](Baselines/godot_2026-09-11_v01/Reports/reference_motion.avi)：脚本fixture，五元素批次显式注入，不冒充真人自然游玩。原版攻击用真实时钟，离线固定60帧录制会改变相对时序，因此**不得用于手感时序或性能验收**；音频未单独验收。旧离线trace保留作诊断。
- [实时60fps上限事件时间线](Baselines/godot_2026-09-11_v01/Reports/reference_motion_realtime_trace.json)：不启用离线录制，记录帧时间和wall_time；以真实时钟对照发射、命中和批次结束。真人声画手感仍须实际运行基准包确认。
- 默认桌面首启截图位于Reports，实际渲染597×1061。精确941×1672、720×1600、768×1024离屏布局截图位于Reports/Layouts：通过SubViewport验证原布局代码，不代表原包在相同比例设备上的系统拉伸/留黑边行为。安卓真机与安全区仍待验收。
- 288组原版补块数据、2592次采样、25格坐标、36级字形/属性映射见Reports/board_oracle.json。

## 审核要求

请先用独立基准APK确认：单击合成、高亮、最多五次连锁、怪物冻结/恢复、元素发射与命中、新手和v02弹窗是否就是后续Unity要还原的版本。
确认后将M0标为APPROVED，开始M1精灵棋盘与适配；未确认前不把本轮数据当成已批准的最终手感标准。

## 复现

运行 Migration/Tools/FreezeBaseline.ps1 生成新的、不可覆盖的基线目录。
冻结时排除缓存、玩家存档、旧安装包与未引用旧项目目录；保留当前运行资源及Godot导入配置。
Source仍可从原素材重建导入缓存。详细文件、SHA256和源Git状态见对应manifest.json。
