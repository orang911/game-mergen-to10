# Android ARM64 测试包说明

## 定位

该预设只用于本地功能测试，不接广告、支付、统计、账号、渠道 SDK，也不用于商店发布。

## 资源策略

- `assets/runtime/` 只保留当前运行资源；历史未引用资源进入 `asset_review_delete/`。
- Android 导出排除 `art/`、审核区、测试、文档、工具、本地依赖和构建产物目录。
- 棋盘块、棋盘字符、卡牌图标、大厅图标和动画帧按同屏/同材质/同生命周期合批。
- 大背景、NinePatch、大型结算面板和单例水晶图不合批，避免透明浪费和无效常驻显存。

## 图集目录

- `assets/runtime/characters/monsters/atlases/`
- `assets/runtime/fx/**/atlases/`
- `assets/runtime/ui/**/atlases/`
- 静态子图资源位于相邻的 `atlas_regions/`。

图集可用以下命令重建和校验：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\build_runtime_atlases.ps1 -Mode Build
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\build_runtime_atlases.ps1 -Mode Verify
```

## 测试包导出

预设：`Android ARM64 Test`

```powershell
C:\Users\PC\AppData\Local\Programs\Godot\4.7\Godot_v4.7-stable_win64_console.exe `
  --headless --path . --export-debug "Android ARM64 Test"
```

本机使用项目 `local/jdk17/` 中的便携 Temurin JDK 17；该目录受 `.gdignore` 保护，不进入版本库或 APK。

输出：`builds/android/merge_to_10_arm64_test_v03.apk`

当前测试版本：`versionCode=3`，`0.1.2-test`。

移动端图集约束：所有图集宽高不得超过 `2048`；怪物动画使用 `320×320` 内区、方块使用 `304×304` 内区，每个区域四周保留 `4px` 透明隔离边距。生成器会验证每个区域存在非透明像素，空白帧或超限图集会直接构建失败。

## 0.1.2-test 验证记录

- APK 大小：`52,100,712` bytes
- SHA-256：`fe7f6467303ae2272dc1515a49965b824e2916efb4891067a39099fb3d77aaec`
- ABI：仅 `arm64-v8a`
- 权限：未声明自定义或运行权限
- 签名：Godot Debug，APK Signature Scheme v2/v3 验证通过
- 包内资源：新版方块、普通怪行走/受击/死亡、铁甲教学 Boss 行走/受击和移动端传送门图集均存在；对应旧散帧及 2560px 传送门源图未进入包
- 真机：当前未检测到连接设备，安装与屏幕截图验收仍为 `pending`
