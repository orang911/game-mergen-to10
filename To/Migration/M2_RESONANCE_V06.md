# M2 合鸣与弹道表现 v06

本轮对应剩余计划第1轮。测试入口保持 Assets/MergeTo10/Scenes/M2WaveBattle.unity，
或菜单 Merge To 10 → Open M2 Wave Battle。仅Unity编辑器验证，没有生成Windows包。

## 实际迁移

- 元素底盘：半径633×0.072，底色为元素色darkened(0.45)，外环lightened(0.4)、宽3设计像素。
- 同元素保持一个槽位，×N仍表示原始合成贡献次数。标签使用从Godot内置字体导出的Open Sans SemiBold，
  由WOFF2解压成TTF，保留字形及嵌入的版权/授权信息；没有换成系统字体或烘焙次数图片。
- 图标与文字按新增槽位次序延迟0.08秒、线性渐入0.14秒；
  重复贡献及发射时缩放1→1.18（0.06秒）→1（0.10秒）。
- 开始批量发射前接入1→1.13的群组burst，结束后0.16秒淡出。淡出独立于下一批逻辑；
  重置仍立即取消旧表现。
- 毒/冰/暴击/火：原版核心尺寸74/70/78/78，原始拖尾贴图与加色渐变shader，
  0.10秒距离历史、命中后0.05秒收束；旋转偏移按原版。演出使用帧时间，
  未改动伤害的0.14秒真实时间等待或0.15秒组间隔。
- 原始四类散落粒子：距离发射、稀疏段/偶发双粒子、交替侧向扩散、缩小与淡出；
  火系缩放/间距/寿命修正保留。随机实例不保证跨引擎逐粒子相同。
- 闪电：原版258×516、4px间隔边距的三帧图集，0/1/2/0/1/2共0.4秒，
  宽120、端点补偿32；连锁怪物之间也播放连线，端点随目标移动。
- 无目标时非闪电视觉淡出；重置清理核心、拖尾、粒子及退出中的阵图。

## 验证与证据

执行 Migration/Tools/ValidateM2Editor.ps1，
最终证据目录 Migration/Reports/M2ResonanceV06/Final。
最终运行通过，累计97,490次编辑器断言（含逐帧重复检查，不等于独立用例数量）；
战斗核心23,085项断言及默认20波回归通过。暂停与重置新增检查通过。
未检出C#编译错误、Shader错误、游戏NullReference/MissingReference或字体格式警告。
仍有已知UnityEditor.Search.SearchDatabase越界日志，不将整个Editor日志描述为零错误。
包含合鸣截图resonance.png、五元素测试弹道flight-review.png、编辑器日志和回归结果。
五元素弹道截图为显式注入的水平排列测试，不冒充正常游戏中的发射布局。

新增检查：渐入初始alpha/延迟/结束值，脉冲峰值与回落，闪电帧序，
拖尾历史长度，残留特效最终消失，暂停保持特效时钟，重置清理。
继续运行战斗核心、默认20波、冻结、结算、目标死亡、出生死亡演出等既有回归。

## 实施边界与后续审核

字体描边当前用16个偏移文字层模拟5px轮廓，尚不能声称与Godot字体栅格化逐像素一致；
同时存在burst与单元素pulse时Unity采用后触发的pulse优先，原版并行Tween的同帧竞争还需真人对照。
URP加色混合、抗锯齿、字体尺寸与不同屏幕上的可读性仍需原版实机对照；
本文不把“有画面/逻辑回归通过”写成全部手感等价已验收。
原PNG不重绘，不改变棋盘、路径、槽位或玩法数值。
下一轮仍是伤害跳字、状态反馈、音效与战斗节奏审核；水晶专用光束完整表现仍需补齐。
章节/奖励/完整UI/存档、Android性能与真人验收未在本轮完成。

## 字体与资源复现

Migration/Tools/ExportResonanceFont.gd导出内置WOFF2；
ConvertResonanceFont.py使用工程隔离的fonttools 4.65.0、brotli 1.2.0转换成TTF。
PythonDeps仅为迁移工具依赖，不位于Assets，不进入游戏运行时。
字体嵌入授权信息在Assets/MergeTo10/Resources/M2Art/resonance_default_license.txt。
四类trail_*.png、particle_*.png及lightning_beam.png均从冻结Source原样复制。
