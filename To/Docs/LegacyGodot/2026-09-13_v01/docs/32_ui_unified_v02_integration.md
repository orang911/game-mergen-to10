# UI 统一风格 v02：切图与实装

日期：2026-09-10。工程：D:/UGit/UGit/TO10。

已替换正式教学提示、节点/章节完成、胜负结算和 Z 恭喜界面。使用已确认的 v02 细边框蓝白风格。旧资源与审核稿保留；未修改战斗数值、路径、棋盘布局或顶部/底部 HUD。

## 结果入口

- [实装后的 35 张截图与图册](../builds/ui_audit/2026-09-10_v02_runtime/README.md)
- [教学提示](../builds/ui_audit/2026-09-10_v02_runtime/screenshots/05_tutorial_merge.png)
- [阶段完成](../builds/ui_audit/2026-09-10_v02_runtime/screenshots/25_node_complete.png)
- [Z 恭喜页](../builds/ui_audit/2026-09-10_v02_runtime/screenshots/27_max_level_success.png)
- [胜利](../builds/ui_audit/2026-09-10_v02_runtime/screenshots/28_settlement_win.png) / [失败](../builds/ui_audit/2026-09-10_v02_runtime/screenshots/29_settlement_lose.png)
- [新增切图与 QA 包](../art/production/ui_unified_style/ui_unified_v02_cutouts.zip)

## 素材清单与约定

共 14 个 PNG RGBA。源图为 art/production/ui_unified_style/2026-09-10_v02 中的确认稿。本轮使用本地机械裁切和无字边缘采样，没有重新生图。文字、数值、动态内容仍由程序绘制。

|素材|像素尺寸|存放模块|
|---|---|---|
|panel/header/primary/secondary/tab_active/tab_inactive/stat/reward，共8张|各64×128|shared/backplates/unified_v02|
|节点完成底板、标题、按钮|128×128、694×130、510×140|interfaces/chapter_node_complete，使用_v02后缀|
|Z面板、按钮、皇冠|740×820、460×105、155×125|interfaces/max_level_success，使用_v02后缀|

所有路径均位于 assets/runtime/ui。共享九宫格左/上/右/下边距为12px，内容安全边距至少16px；边框不随面板尺寸整体放大。面板按左上角定位，标题和按钮按当前布局居中。普通节点继续按钮510×140，Z按钮460×105。

新增底板/按钮均不含文字和动态图标，保留浅渐变与细边，不含大范围外发光。皇冠含原有金色高光、青蓝点缀和透明轮廓，无文字。遮挡区域不硬裁入库，采用干净边缘与内侧空白列构成九宫格；其他独立图标复用原资源。

详细来源、裁切区域、尺寸记录在 art/production/ui_unified_style/2026-09-10_v02/cutout_qa/slice_manifest.json。复现脚本：tools/cut_unified_ui_v02.ps1。

## 功能与验证

保留整屏唤醒、跳过教学、教学进度、阶段继续/返回、结算卡组切换和复活/重开/主页回调。结算保留全部原数据字段，包括效果图未完整展示的波次、时长、分数及伤害百分比；不新增奖励。

白/浅灰/黑底透明边缘图已生成并目视核对，见 cutout_qa/nine_patch_edges.png 和 crown_edges.png。Godot导入、解析和35张941×1672正式场景截图通过。

通过测试：ui_unified_v02_smoke、max_level_success_smoke、chapter_node_complete_smoke、first_wave_tutorial_smoke、ui_global_review_smoke、resonance_v05_smoke。覆盖切图透明角、固定九宫格边距、页签选中、按钮信号、教学避让和连锁战斗。

教学测试改为等待真实合成完成，将首击已杀怪计入四只教学怪总数；全局审核加载等待上限45秒，功能断言保留。审核场景教学位置改为读取实际棋盘/水晶坐标，不改游戏规则。

Android真机、多比例视觉和触控体验仍待验收。本轮未重新打APK，之前的v05包不包含这些新UI。
