# 合成特效 Particle1 接入 v01

任务类型：精确编辑（运行时特效替换）。用户指定的 Particle1 为内容依据，不涉及重新设计或切图。

## 接入

- 原始预制体：`D:\UGit\T0\To\Assets\EffectsPrefabs\Particle1.prefab`。
- 运行时引用：`D:\UGit\T0\To\Assets\MergeTo10\Resources\merge_effect.asset`，直接引用原始预制体，构建时包含依赖。
- 入口：`Assets/MergeTo10/Runtime/M1MergeFeedback.cs`。在原有合成目标中心实例化，保持预制体旋转和缩放；两层粒子均关闭循环，渲染排序增加 100，结束后销毁；重置棋盘或禁用反馈组件时清理。
- 合成规则、触发时机及震屏逻辑保持原样。原始预制体及其材质、贴图未修改。

## 素材规格

| 原有贴图完整路径 | 尺寸 | 源图 Alpha |
|---|---|---|
| `D:\UGit\T0\To\Assets\EffectsTex\DefaultParticleReplacement.jpg` | 128×128 | 无，RGB；显示由原材质控制 |
| `D:\UGit\T0\To\Assets\MergeTo10\Resources\M1Art\merge_sheet.png` | 832×832 | 有，ARGB |

锚点：原有合成目标格中心。NinePatch / 文本安全区：不适用。
光效：沿用原有粒子材质；无新增文字、阴影或绘图。原贴图含字及视觉边缘检查：pending。
新效果图、无字生产图、透明切图：未生成，不适用。生成工具及提示词：不适用，直接使用用户资源。

## 验证

- Unity 脚本编译通过。
- Unity 内自动验证通过：Resources 指向指定预制体、包含两层粒子、材质和 Shader 存在且受支持、两层均可发射、模拟结束后粒子数归零。
- 可复验菜单：`MergeTo10 > Verify Merge Effect`；结果：`D:\UGit\T0\To\Temp\merge_effect_verify.result`。
- 已完成运行时引用替换；完整合成操作、重置清理的实机验收及白/灰/黑背景视觉 QA：pending。桌面控制工具连接不可用，未作视觉通过声明。
- Player / WebGL 构建冒烟：pending。本次目标是 Unity 项目，Godot 导入和 Headless 不适用。
