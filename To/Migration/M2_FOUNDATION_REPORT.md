# M2 战斗基础层进度（2026-09-11）

状态：M2 进行中，当前不是完整可玩战斗小样。目标工程 D:/UGit/T0/To。

## 本轮实现

- MergeAttack：独立于可变棋盘格的只读合成快照；源等级决定元素和阶级，结果等级决定基础攻击。
- MergeAttackBatch：固定火→闪电→暴击→冰→毒排序，同元素单槽展示，保留每次原始贡献；3/4/5元素增益1.15/1.30/1.50。
- 保留原版聚合细节，包括冰的不同目标覆盖、闪电额外合成增益、最高数值效果参数、暴击每次原始攻击独立随机取值。此处只迁移数据和伤害计算辅助，尚未执行完整命中、状态和湮灭。
- CombatClock：真实单调攻击时间与帧驱动模拟时间分开；全局暂停不计攻击时间，结算冻结只停模拟时间。尚待战斗运行器接入。
- IBoardCombatSink：棋盘有效操作同步通知开始；每次结果产生时记录快照；等待整个批次完成才执行结束阶段并解锁。重置和销毁取消旧批次。
- M1BoardParity 没有默认接入模拟战斗；不改旧棋盘场景视觉。接口由测试替身验证，不能据此宣称怪物已经冻结。
- 快照 OriginX/Y 统一存设计坐标，未来世界精灵表现层换算；固定元素槽弹道起点尚未接入。

## 验证证据

1. CaptureM2CombatOracle.gd 在隔离 WorkingGodot 上调用冻结原版 MergeAttackEvent、MergeChainBatch：
   - 源等级1–35，合成数量2–25，共840组合成事件；
   - 200组1–5次合成批次，覆盖重复元素及五元素；
   - 输出 Migration/Reports/M2Foundation/combat_oracle.json；Godot退出0，无脚本错误。
2. Unity对照数据及定向检查：23,085项通过。
   - 等级、元素、阶级、次数、伤害、数值效果参数、聚合顺序、倍率、保留贡献；
   - 冰目标分配、暴击固定随机输入调用次数、双时钟暂停/冻结/恢复。
   - 不含完整怪物伤害解析、DOT、湮灭、波次或弹道视觉等价认证。
3. 旧棋盘核心和Windows构建回归：14,079项通过。
4. Windows/D3D11、470×836运行：
   - Settlement/m2-settlement-result.txt：34项通过；开始3次、正常结束1次、取消2次。
   - BoardRegression/runtime-result.txt：启动、自动连锁、高亮、落定25格、重置、满盘合成、残影清理、孤立格/Z拒绝及抖动复位通过。
   - 高亮差异3578像素，阴影6418像素（25个块），残影48像素；仅验证可见性，不表示像素完全等价。
5. 7个变更/新增C#文件与隔离验证副本SHA256一致。原Godot工程和冻结Source未修改。
6. 本轮没有重新认证三个比例、Android真机、60fps稳定性或真人手感。

结果文件在 Builds/M2Foundation 下。Windows/MergeTo10M1.exe 仍是带新增接口的棋盘测试程序，不是M2可玩战斗包；因此没有把它替换为对外“完整战斗包”。

## 复现

先用Godot运行 Migration/Tools/CaptureM2CombatOracle.gd，项目指定冻结目录下的WorkingGodot，
参数 --output=<绝对路径>/Migration/Reports/M2Foundation/combat_oracle.json，APPDATA指向独立测试目录。

然后：

```powershell
& .\Migration\Tools\BuildM1.ps1 -OutputDirectory 'D:\UGit\T0\To\Builds\M2Foundation' -CombatOracle 'D:\UGit\T0\To\Migration\Reports\M2Foundation\combat_oracle.json'
```

运行生成的Windows程序，分别传 --m2-settlement-smoke 或 --m1-smoke，
均需 --capture-dir=<独立绝对输出目录>，本轮窗口470×836、D3D11。
不要同时传两种测试参数。

## 下一实施段（未完成）

1. 原版路径、怪物、波次、水晶自动攻击及所有冻结状态实际接入。
2. 共鸣固定位置及原资源、0.15秒发射间隔、0.14秒飞行、死亡换目标、清场停止与延后下一波。
3. 逐元素真实命中、毒/火/冰状态、暴击/湮灭/免疫、火溅射、闪电跳跃。
4. 印记时序、暂停/退出生命周期、完整战斗小样与多比例运行对照。
5. 全套UI、教学、局外及存档仍属于后续M3。

