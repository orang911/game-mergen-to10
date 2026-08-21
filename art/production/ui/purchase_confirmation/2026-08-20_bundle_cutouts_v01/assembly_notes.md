# 双权益确认购买弹窗拼装说明 v01

## 范围

- 本包只提供生产素材，不修改场景、脚本或运行时资源。
- 最新确认效果图：`source/approved_bundle_purchase_effect_v01.png`。
- 标题、商品名、权益说明、价格、按钮文字、`x2` 与 `AD` 均由程序绘制。

## 推荐层级（后 → 前）

1. 程序全屏遮罩：黑色，透明度 65%～70%。
2. `purchase_popup_shell_fixed_v01.png`。
3. 程序标题：`确认购买`。
4. `purchase_divider_horizontal_v01.png`，位于标题下方。
5. 左权益：`purchase_icon_double_coin_base_v01.png` + 程序 `x2` + 商品名与说明。
6. 右权益：`purchase_icon_no_ad_base_v01.png` + 程序 `AD` + 商品名与说明。
7. `purchase_divider_vertical_v01.png`，位于两项权益之间。
8. `purchase_status_tag_permanent_v01.png` + 程序 `永久生效`。
9. 程序价格：`¥6`。
10. `purchase_button_cancel_default_v01.png` + 程序 `取消`。
11. `purchase_button_confirm_default_v01.png` + 程序 `确认购买`。

## 比例与锚点

- 弹窗以屏幕中心为锚点，建议保持母版宽高比；需要适应多语言时可使用 NinePatch。
- 两项权益列宽相同，图标均使用 512×512 同画布，中心锚点 `(0.5, 0.5)`。
- 蓝色与金色按钮已经使用相同 608×261 画布、中心和基线，切换时不得单独裁切。
- 状态条、按钮、图标均使用中心锚点。
- `x2` 建议叠加在金币图标右下区域；`AD` 建议置于禁止符号中心，均不要烘焙进贴图。

## NinePatch 建议（母版像素）

| 资源 | left | top | right | bottom | 文本安全区 |
|---|---:|---:|---:|---:|---|
| `purchase_popup_shell_fixed_v01.png` | 88 | 88 | 88 | 88 | 四边至少 72px |
| `purchase_button_cancel_default_v01.png` | 84 | 70 | 84 | 70 | 左右 76px，上下 58px |
| `purchase_button_confirm_default_v01.png` | 84 | 70 | 84 | 70 | 左右 76px，上下 58px |
| `purchase_status_tag_permanent_v01.png` | 62 | 44 | 62 | 44 | 左右 58px，上下 34px |

分隔线只允许沿长度方向拉伸；菱形中心装饰不可拉伸。

## 程序状态

- 默认交付为可用态。按下态建议整体下移 2～4px，并降低亮度 6%～10%。
- 购买中：禁用两枚按钮，主按钮文案切换为程序状态文本。
- 成功、失败、已拥有、恢复购买等反馈不应烘焙进当前底板。
- 如果后续需要独立 pressed / disabled 美术态，应另开状态切图版本，保持同画布。

## QA

- PNG RGBA：通过。
- 白 / 浅灰 / 黑底边缘：通过。
- 按钮同画布、同中心、同基线：通过。
- 96×96 图标识别：通过。
- 游戏内拼装、真机比例与点击区：待接入后验证。

