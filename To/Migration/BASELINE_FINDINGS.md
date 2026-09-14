# M0 原版测试差异记录

首轮：38项中33项通过、5项失败。固定60fps复测时序相关3项仍失败。以下不是Unity回归，冻结Source与游戏规则未修改。

|原测试|现象|独立诊断与处理|
|---|---|---|
|chapter_imprint_resume_smoke|3.20秒时印记仍未消耗|原版仍在连锁结算。诊断等待真正结算结束，约5.63秒后pending=false并通过原有结果检查。迁移测试改用状态门和超时上限，不能把印记改成提前消耗。|
|merge_chain_batch_smoke|要求手动合成事件始终排第一|当前批次按火/闪电/暴击/冰/毒聚合排序；保留raw来源和当前顺序，不改回旧队列。|
|merge_result_feedback_smoke|攻击事件到来时要求scale精确为0.90|60fps诊断实际scale约1.060367，动画仍在播放；0.90→1.14→1的原曲线保留，迁移按相对时间采样曲线而非旧事件起点假设。|
|one_tap_merge_smoke|孤立格0.05秒采样未观察到位移|仅让fixture初始化后等待0.30秒再操作，原断言全部通过。初始化布局与采样时序敏感；仍需真人确认无效点击反馈，不能删掉抖动。|
|runtime_atlas_smoke|六张卡图标不是AtlasTexture，大厅依赖不满足旧15图集要求|当前资源直接PNG与图集混用。迁移验证资源和视觉等价，不要求继续使用Godot资源类型。|

## 打包工作副本的允许差异

- Source逐文件SHA256校验：1093项、0差异。
- WorkingGodot的存档目录单独命名，测试不访问原玩家存档。
- 安卓基准包使用com.crystalguardians.mergeto10.baseline，名称“晶核守卫Godot基准”，可与原测试版共存。
- Windows添加桌面资源打包预设与S3TC/BPTC导入，不修改玩法；原安卓预设已经排除的废弃印记界面，在Windows同样排除。
- Windows交付采用Godot运行程序＋独立PCK便携包，不是Unity版本，也不是标准Windows导出模板产物。
- 诊断、黄金数据和录像脚本只存在WorkingGodot/tests，安装包排除tests，不进入运行玩法。

## 待审核而非完成

离屏768×1024布局样本中观察到左侧灰色空带，背景没有对称铺满。源码将battle_background放在居中的game_layer原点，可能解释该现象；离屏结果不等于Android实际系统视口行为，需要真机确认。按已批准原则只登记，不擅自修正适配。

原版攻击等待使用真实时钟，动画使用帧时间。离线固定帧录像不能作为时序验收依据；已另录实时60fps上限事件，观测发射至命中约0.15～0.16秒（包含帧调度量化），详见reference_motion_realtime_trace.json。

基准包真人手感、多屏幕适配、真机30/60fps及长时间性能未验收。
Source未经用户确认仍为AWAITING_BASELINE_REVIEW，不得擅自标记APPROVED。
