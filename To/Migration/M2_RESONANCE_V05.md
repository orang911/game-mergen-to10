# M2 合鸣阵图 v05
测试入口不变：Assets/MergeTo10/Scenes/M2WaveBattle.unity，Unity Play Mode；未打Windows包。

本轮：
- 按冻结原版element_resonance_view绘制三种及以上不同元素的圆环和固定五角连线。
- 中心(0.5,0.24)×633，半径0.285×633，环宽3、连线宽2设计像素，再随棋盘0.95缩放。
- 同元素仍只显示一个图标；×N表示本批该元素的原始合成贡献次数，不是方块数或攻击次数。
- 标签跟随原图标局部位置(45,62)，清场/重置随槽位一起清理。
- 没有修改伤害、发射顺序、共鸣倍率或固定弹道起点。

验证入口：Migration/Tools/ValidateM2Editor.ps1。
最终证据：Migration/Reports/M2ResonanceV05/Final，包括resonance.png、editor-result.txt、core.txt、wave-core.txt和editor.log。
新增同元素重复计数、两种元素不显示环、三种显示环、重置清理检查；继续运行旧战斗回归。

最终隔离Unity Play Mode验证通过；战斗核心23,085项断言，波次配置及三组冻结帧轨迹通过。编辑器累计93,123次断言包含逐帧重复检查，不代表同等数量的独立用例。
人工检查最终截图，确认圆环、五角连线和缩小后的×N文字确实渲染。首轮截图发现的MeshRenderer误用精灵材质导致线条不可见已改用独立URP顶点色材质；没有修改棋盘精灵材质或工程色彩空间。
未发现C#编译、Shader、游戏MissingReference/NullReference错误；日志仍有已知UnityEditor.Search.SearchDatabase内部越界异常，不将其描述为完全无错误日志。

边界：当前次数使用世界空间TextMesh，尚未迁移原版字体和5px描边；图标底部圆盘/圆弧、渐入和脉冲也尚未完成。本轮不是全部合鸣视觉等价完成。
章节、奖励、升级、完整UI与存档仍待迁移。
