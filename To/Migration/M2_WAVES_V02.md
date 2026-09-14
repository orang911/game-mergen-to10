# M2 波次与一级水晶 v02

## Unity 测试入口

打开 Assets/MergeTo10/Scenes/M2WaveBattle.unity 后点击 Play。
也可使用菜单 Merge To 10 → Open M2 Wave Battle。建议 Game 窗口470×836。

- 怪物按原版默认20波配置从入口分批出现，水晶自动攻击。
- 正常点击棋盘检查连锁、冻结、元素发射及结算后恢复。
- 清场后点击 Continue wave (reward UI pending)。它只是奖励流程占位，不发放卡牌。
- Reset fixture 在此场景重置整局；Start Wave 指定测试起始波，重置后生效。
- Five elements 是调试注入，不是自然连锁。
- 原 M2BattleParity 固定阵列场景保留。本轮未打Windows包。

## 本轮实现

默认20波数量、血量倍率、三种怪物速度/尺寸/漏怪损失与三阶段外观；1/2/3/4只循环批次，同批间隔0.08秒。
刷怪按帧推进，合成冻结与暂停期间不推进；清场等待手动继续，末波完成停止。

一级水晶启动冷却0.9秒，此后1.8秒间隔，蓄力0.35秒、飞行0.18秒、基础伤害1。
保持活目标锁定，失效目标取消攻击；开始合成取消蓄力或飞行，有在途攻击时冻结后的冷却为0。
水晶位置、缩放和发射点由原版水晶及审核场景参数映射。没有加入升级或额外元素能力。

新素材仅复制原版 slime_stage_02、slime_stage_03、crystal_tower_lv01、crystal projectile_core 到 Resources/M2Art，未重绘或修改原PNG。
原Godot工程和冻结Source未修改。

## 验证结果

最终证据：Migration/Reports/M2WavesV02/Final。

- editor-result.txt：PASS，99,040次检查。包含每编辑器帧重复检查，不代表99,040种规则。
- wave-core.txt：20波配置、全部出生数值、三种时间步含冻结区间的Godot逐帧刷怪记录、奖励及末波边界通过。
- core.txt：原有840事件/200批次对照检查。
- 实际Play Mode验证：五元素发射/命中、普通棋盘接战斗、重置、波次、水晶命中、蓄力中合成取消、冻结期间无刷怪或普攻命中、清场等待与继续下一波。
- 测试主动清除怪物以加速奖励边界验证，不冒充真人通关20波。
- editor-combat.png：470×836离屏截图，已检查水晶及入口怪物位置；不包含IMGUI调试工具条。
- 隔离编辑器启动仍出现UnityEditor.Search内部索引异常，日志保留；未发现本轮游戏脚本MissingReference/NullReference、C#编译或shader错误。

复现工具：Migration/Tools/CaptureWaveOracle.gd 导出Godot对照，Migration/Tools/ValidateM2Editor.ps1 在隔离Unity编辑器编译并进入Play Mode，不调用Windows打包。

## 尚未完成

本次接入的是 GameConfig.get_level_waves 默认20波，不是章节/续战节点配置。
章节、教程、奖励卡牌、水晶升级与安装元素、存档、正式HUD尚未接入。
完整共鸣环、次数文字、拖尾/电弧、命中/死亡特效、跳字及出生缩放仍待对齐。
随机队列不声称跨引擎同seed排列一致；真人手感、多比例、Android和长时间性能尚未验收。
