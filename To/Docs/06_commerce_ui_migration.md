# 权益与存钱罐 UI 迁移 v01

更新：2026-09-14。分类：精确迁移。布局与内容参考为已批准 Godot 冻结源码 secondary_ui_controller.gd；原截图作为 LAYOUT_REFERENCE / CONTENT_REFERENCE。

## 已接入

大厅 DoubleCoinButton、RemoveAdsButton 共用 ¥6 权益包；PiggyButton 打开存钱罐。包含原面板、标题、图标、文案、确认/取消、按下反馈、遮罩外点击关闭、权益已拥有禁用、存钱罐四阶段、动态进度、空罐提示、满额及部分领取、失败重试、重复提交防护与稳定存档。保持后台战斗暂停。交易沿用本地模拟，无真实支付或广告 SDK。

运行入口：Merge To 10/Open Navigation Integration，重新进入 Play 后点击大厅三个入口。旧场景由 NavigationIntegration.Start 自动补齐 CommerceView。

## 文件与资源

主实现：Assets/MergeTo10/Runtime/CommerceView.cs。辅助：CommerceButtonFeedback、CommerceTextOutline、CommerceOwnedSprite。入口接线：NavigationIntegration.cs。BattleHudView 增加已销毁对象检查。

25 张原始 PNG 原样复制到 Assets/MergeTo10/Resources/Campaign，来源、尺寸、像素格式、SHA256见 Migration/Reports/Commerce/2026-09-14_v01/assets_manifest.json。无重新生成的美术效果图；文字由程序绘制，原图阴影/光效保留。新增机械栅格素材：commerce_shade_v01.png（4×4，RGBA，半透明，无字）；commerce_piggy_selection_v01.png（131×159，RGBA，圆角黄色选中底框，无字）。未使用AI生图，提示词不适用。

面板700×714，中心定位；权益下移22设计像素。存钱罐内容539×583，购买确认518×552等比缩放居中。面板九宫格四边28；进度填充左/右18、上/下14，最小宽36。图像Sprite中心锚点，UI内容左上坐标；各文字安全矩形见CommerceView中的Copy/BenefitCopy参数。

原素材白/灰/黑预览：Migration/Reports/Commerce/2026-09-14_v01/assets_white_gray_black.png。目视未发现新增杂边或背景残留；原猪图柔边保留。未对每张原图开展像素级重抠图验收。

## 验证

最终有效结果：Migration/Reports/Commerce/2026-09-14_v01/Run13/commerce-result.txt，PASS 167项。覆盖实际UI射线点击、两个权益入口、确认/取消、模拟失败重试、已拥有、四阶段、满额/部分领取、防重复、磁盘往返、后台暂停及水晶返回层级。不是167个人工用例。

截图目录：Migration/Reports/Commerce/2026-09-14_v01/Run13/。含941×1672、720×1600、768×1024；06_piggy_progress.png已确认选中框、进度及遮罩显示。旧Run01–Run12为诊断/中间结果，部分截图失真或验证失败，不作为最终完成依据。

验证代码：Assets/MergeTo10/Editor/CommerceUiVerifier.cs；截图协程只由验证入口临时挂载。通过隔离工程执行，没有生成Windows或Android包。本轮没有重新运行完整战斗长时回归。

## 遗留验收

Android真实触摸、安全区、性能、长时间运行为pending。Noto与Godot原系统字体存在字形差异，未宣称逐像素一致。大厅原有厚描边及平板留边属于既有全局UI问题，此次未重做。编辑器SearchDatabase启动索引异常仍存在，未归为游戏功能通过。所有截图仅供编辑器视觉核对，不是设备性能证据。