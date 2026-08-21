# 当前 UI 图集可维护源切图

更新日期：`2026-08-20`

本目录保存当前 4 套运行时 UI 图集对应的 72 张独立源切图，供局部修改、审核和重新打包使用。Godot 运行时不直接引用这里的文件；`.gdignore` 用于阻止这些生产源被项目重复导入。

## 来源事实

- 原有独立源切图及其旧审核归档在当前工作区已经不存在，未被本次归整恢复。
- 本目录文件由现有可运行图集和 72 个 `AtlasTexture` 区域定义进行无损区域裁切得到。
- 因此，这些文件能够逐像素重建“当前运行效果”，但不能还原图集生成前可能存在的更高分辨率母版。
- 卡牌图标等资源如果在旧打包流程中发生过缩放，这里的切图已经包含该缩放结果。

## 目录

```text
2026-08-20/
├─ board_tiles/      棋盘色块，5 张
├─ board_glyphs/     数字与字母，36 张
├─ card_icons/       水晶卡与棋盘印记图标，16 张
├─ meta_icons/       大厅及元系统图标，15 张
└─ manifest.csv      图集、区域、尺寸和 SHA-256 来源记录
```

修改单张源切图后，运行：

```powershell
powershell -ExecutionPolicy Bypass -File tools/build_runtime_atlases.ps1 -Mode Build -Scope UI
powershell -ExecutionPolicy Bypass -File tools/build_runtime_atlases.ps1 -Mode Verify -Scope UI
```

打包脚本会把图集和 `AtlasTexture` 写回新的 `assets/runtime/ui/components/**` 或 `assets/runtime/ui/shared/**` 目录。不要在界面目录复制第二份图标；界面应继续引用唯一的组件或共用图集区域。
