# 晶核守卫 Unity 工程

本工程使用独立的 `unity` 分支和独立提交历史，与同仓库 `master` 中的
Godot 工程隔离。不要将两个分支的工程文件混合或合并无关历史。

使用 Unity Hub 打开本仓库的 **To/** 目录。Unity 版本以
[ProjectVersion.txt](To/ProjectSettings/ProjectVersion.txt) 为准，当前为 6000.3.11f1。

- 运行入口：`To/Assets/MergeTo10/Scenes/NavigationIntegration.unity`
- 战斗布局编辑：`To/Assets/MergeTo10/Scenes/GameCoreAuthoring.unity`
- Prefab：`To/Assets/MergeTo10/Resources/Prefabs/`
- [项目文档](To/Docs/README.md)
- [Prefab 与动效编辑说明](To/Docs/08_unity_prefab_authoring.md)

仓库保留 Assets 及全部资源 .meta、Packages、ProjectSettings、文档和迁移工具。
Library、Temp、构建产物、隔离验证工程、备份与历史生成报告不上传。
历史文档中指向这些本地报告或 Godot 冻结源的链接，在新克隆中可能不可用；
现有回归使用的四份 JSON 基准数据单独保留。

首次打开由 Unity 重建缓存并恢复 Packages。提交资源时必须一起提交对应的
`.meta` 文件，以保留场景、脚本、材质和 Prefab 引用。

如需重新运行历史 Python 美术转换工具，先安装其依赖：
`python -m pip install -r To/Migration/Tools/requirements.txt --target To/Migration/Tools/PythonDeps`。
这些工具与 Unity 日常打开、运行和编辑无关。
