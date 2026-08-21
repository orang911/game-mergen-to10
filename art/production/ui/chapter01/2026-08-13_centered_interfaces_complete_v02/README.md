# 第一章居中界面完整资源包 v02

本包修复上一版“只有整页母版、缺少图素与框体”的问题。

## 交付内容

- `cutouts/frames/`：10 张无字透明界面框体，可作为页面组装底图。
- `cutouts/elements/`：94 张透明 UI 图素，包含通用框体源、按钮状态、Tab、开关、进度条、设置图标、任务/签到组件、商业化组件和商城组件。
- `previews/implementation_previews/`：10 张 941×1672 居中实现效果图；背景只用于位置与比例检查。
- `qa/frames_white_bg.png`、`frames_gray_bg.png`、`frames_black_bg.png`：透明边缘 QA。
- `qa/implementation_preview_contact_sheet.png`：10 个界面的实现效果总览。
- `manifest.json`：逐文件尺寸、Alpha、锚点和 QA 状态。

## 居中规则

- 页面轴心：`(0.5, 0.5)`。
- 打开锚点：屏幕中心。
- 只允许等比缩放，禁止横向或纵向单独拉伸。
- 941×1672 设计预览中的放置公式：`x=(941-page_width)/2`，`y=(1672-page_height)/2`。

## 正式资源规则

- 10 张框体不包含文字、价格、数量和动态奖励内容。
- 程序文案、价格、进度数值、红点数量和商品状态由 Godot 绘制。
- NinePatch 边距沿用 `assets/runtime/ui/secondary_v2/manifest_batch1.json` 与 `manifest_batch2.json`。
- 本次只补生产资源与实现预览，未覆盖运行目录，未修改场景引用。

## 界面框体尺寸

| 界面 | 尺寸 |
|---|---:|
| 战斗暂停 | 660×485 |
| 退出确认 | 660×388 |
| 设置 | 650×910 |
| 清档确认 | 660×383 |
| 日常任务 | 880×1141 |
| 七日签到 | 880×436 |
| 权益 | 760×775 |
| 首充礼包 | 760×748 |
| 存钱罐 | 760×842 |
| 商城 | 850×901 |

