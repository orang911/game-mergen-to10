# M2 怪物出生与死亡表现 v03

继续使用 Assets/MergeTo10/Scenes/M2WaveBattle.unity，在Unity点Play；未打Windows测试包。
原固定阵列场景 M2BattleParity 同样获得死亡动画。

## 本轮迁移

- 波次怪物从0.12缩放入场，0.22秒Back Out到1，保持原版身体底部中心轴。
- 复用原版monster_death_sheet：19帧、24fps，5列，320×320帧、4px边距、328px步长。
- 普通死亡播放约0.792秒；湮灭死亡2.5倍速、约0.317秒。
- 死亡立即从存活数量、选敌和清场判定排除；可见尸体单独保留到演出完成。
- 合成冻结不暂停死亡演出；游戏暂停仍暂停帧时间。
- 到终点的怪物保留0.22秒显示再移除，不错误播放死亡序列。
- 重置立即隐藏旧显示对象，再销毁，避免上一批死亡画面残留。
- 湮灭改用独立死亡标记，不再伪装成一次普通伤害以选择动画速度。

## 原版来源

Source/scripts/monster_system.gd：SPAWN_INTRO_START_SCALE、SPAWN_INTRO_DURATION、_remove_monster。
Source/scripts/monster_view.gd：DEATH_FRAME_COUNT、DEATH_FRAME_DURATION、play_death_animation、_load_death_frames。
只复制原版死亡图集到Resources/M2Art，没有生图、裁改PNG或修改Godot原工程/冻结源码。

## 编辑器验证

工具：Migration/Tools/ValidateM2Editor.ps1。
报告：Migration/Reports/M2PresentationV03/Run01。
editor-result.txt记录最终运行结果；core.txt、wave-core.txt为先前元素和波次数值回归。

本轮实际结果PASS；100,668次检查包含按编辑器帧重复的冻结检查，不等于独立规则数量。死亡截图已检查；4个C#文件及死亡图集与隔离验证工程SHA256一致。未发现游戏脚本空引用、失效引用、C#或shader错误；仍记录了隔离编辑器已知的SearchDatabase启动索引异常，不宣称整份编辑器日志无异常。

新增检查：
出生起止缩放、普通死亡时长、湮灭帧速；
同时普通死亡和湮灭时立即减少存活数；
冻结期间两种死亡动画仍显示；
湮灭先结束、普通死亡随后结束；
死亡中重置不残留显示对象。
测试人为注入死亡和湮灭，不能代替真人自然触发或全帧视觉等价验收。

## 仍待迁移

完整共鸣环和次数、元素拖尾/电弧、命中特效、跳字、状态视觉、死亡声效；
水晶升级、奖励、章节、教程、正式UI与存档。
当前仍是战斗联调，不是完整迁移完成。Android、多比例、性能与真人手感仍待验收。
