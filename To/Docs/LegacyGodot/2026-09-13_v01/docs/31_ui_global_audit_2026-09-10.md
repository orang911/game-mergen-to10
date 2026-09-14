# 全局 UI 截图审核基线 · 2026-09-10

当前项目：`D:/UGit/UGit/TO10`。本轮只导出截图和整理审核议题，没有替换美术或修改正式 UI。

- [完整图册与 35 张单页索引](../builds/ui_audit/2026-09-10_v01/README.md)
- [第一轮审核议题](../builds/ui_audit/2026-09-10_v01/REVIEW_NOTES.md)
- [全局总览 PNG](../builds/ui_audit/2026-09-10_v01/contact_sheets/00_all.png)
- [完整打包文件](../builds/ui_audit/ui_audit_2026-09-10_v01.zip)

来源为 `scenes/ui/ui_global_review.tscn` 的 29 个登记状态，另补 6 个状态：结算卡组页，以及单元素/两元素叠加/三四五元素合鸣。所有原图为 941×1672。截图采用正式组件和审核预设数据，不是安卓实机截图。

需要特别标注：任务与签到是合并页面的两个入口；首充入口已被正式代码停用，第 15 张只显示大厅，不是正常弹窗。静态截图不能代替动效、触控和多比例适配验收。

## 复现

在项目目录使用带图形渲染的 Godot 执行 `--script res://tests/capture_global_ui_audit.gd --rendering-method gl_compatibility --audio-driver Dummy`；不要使用 `--headless`。输出到 `builds/ui_audit/2026-09-10_v01/`。

随后执行 `tools/build_ui_audit_contact_sheets.ps1`，从原图生成带中文编号的最终图册。脚本支持 `-AuditDir` 指定已导出的图册目录。原图不被缩放覆盖。

今后更新美术应使用新版本输出目录保存对比基线，不覆盖本轮已交付的截图包。
