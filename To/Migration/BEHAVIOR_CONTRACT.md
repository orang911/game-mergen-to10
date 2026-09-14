# 冻结版本行为契约（M0，待基准包审核）

基线：godot_2026-09-11_v01。数值源为Source中的实际代码；本表不作为第二份运行配置。

|系统|必须复现|基线来源|
|---|---|---|
|输入|有效单击提交一次合成，结果位于被点格；无效单格抖动；教学限制优先；锁定时不接受合成|main_game.gd / one_tap_merge_smoke|
|手动组|深度优先递归，邻居上、下、左、右；保留遍历顺序，影响吸附路径|main_game.gd::_flood_select|
|自动组|仅落定候选，按y*5+x排序；组内广度优先，上、下、左、右；组含根结果时沿用根结果锚点|_find_auto_merge_group / _collect_merge_group|
|连锁|最多5次含首次；教学期间禁用；达到上限停止本批而非全盘无限消除|CHAIN_MERGE_LIMIT / merge_selected_blocks|
|合成时间|action=max(0.045,0.36/组大小)，自动步骤乘0.85^已有事件数；总时长=(maxSteps+1)*action+0.08|_resolve_merge_step|
|背板高亮|自动步骤开始即高亮目标背板，持续到合成结束；不是只闪数字|block.gd / chain_merge_highlight_smoke|
|下落|每列x递增、y递增，幸存块压到write_y=0起；逻辑y=0是视觉底部，显示公式使用4-y；有位移才等settle，再按y/x顺序补格|_fall_and_fill / get_block_position_for_site|
|下落时间|连锁settle 0.20/refill 0.24/drop 0.20秒；非连锁0.14/0.32/0.28|_fall_and_fill|
|补块|调用动态棋盘质量策略；历史最高<5用0.33/0.34/0.33；之后5级滑窗、最高级上限0.05、活跃下限0.03/上限0.55|board_refill_policy.gd|
|冻结|有效合成冻结移动、状态计时、刷怪、水晶自动攻击与战斗计时；演出不冻结；无效操作不冻结|combat_system.gd / resonance_v05_smoke|
|时钟|攻击发射/飞行等待使用Time.get_ticks_usec真实时间，树暂停时不扣时；动画/SceneTreeTimer按帧时间。Unity时钟必须分别映射，不擅自统一成一个delta|combat_system.gd::_wait_merge_launch_delay|
|属性聚合|保留raw贡献，不把最高等级一次攻击当成全部贡献；相同元素只显示一个聚合槽|merge_chain_batch.gd|
|发射|火/闪电/暴击/冰/毒；缺项跳过；0.15秒组间隔；原版合成弹道0.14秒；从固定元素槽实时位置出发|combat_system.gd / projectile_system.gd|
|增益|不同元素3/4/5种对应1.15/1.30/1.50|game_config.gd|
|命中|飞行结束结算；目标死亡转向活怪；清场停止无意义攻击；不提前刷下一波|resonance_v05_smoke|
|印记|按原版合成批、印记动画、实际生效、消耗的顺序执行；不是文档概述的任意立即执行|merge_selected_blocks / merge_imprint_sequence_smoke|
|Z|36级，对应Z；沿用移除、补充及弹窗顺序|max_level_success_smoke|
|适配|941x1672；min(w/941,h/1672)等比居中；背景铺满；棋盘内容0.95底部中心缩放；坐标反转只发生在显示适配层|main_game.gd::_layout_scene / game_config.gd|
|数字|当前block.gd使用独立字形TextureRect，不是普通文本字体；Unity必须保留原字形资源，不默认换成TMP字体|block.gd::_refresh|
|UI|v02细边框已实装；首充入口已禁用，审核清单存在不表示可用功能|capture_global_ui_audit.gd / secondary_ui_controller.gd|
|局外|自然日任务、签到、碎片、权益等以实际实现为准；本地交易模拟，不接新SDK|meta_progress_service.gd|

## 比较方法

固定初始棋盘、怪物状态、时间步和带调用标签的玩法随机输入；比较状态与事件序列。不假定相同seed跨引擎等价。
整数、离散状态和事件顺序完全一致；浮点容差1e-5*max(1,abs(reference))不能放宽到改变分支。
60fps下关键时间点误差<=1帧，整段连锁不得累计漂移；关键布局锚点<=2设计像素。
原版混用真实时钟与帧时间，离线固定帧录像会扭曲攻击与动画相对时间：AVI仅供视觉参考，时序用实时60fps运行产生的wall_time事件日志。原版渲染卡顿与时钟交互列为待真人审核项，不擅自修正。
测试源文件只读；失效断言分类记录，不通过修改原版把失败变成通过。

## 待真人验收

基准APK包含最新UI，但尚需用户确认其手感。设备名单、30/60fps、不同屏幕比例、声画同步及长时间性能均未验收。
