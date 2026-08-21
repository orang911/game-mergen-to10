extends RefCounted
class_name UiTypography

const FONT_NAMES := [
	"Microsoft YaHei UI",
	"Microsoft YaHei",
	"Noto Sans CJK SC",
	"Arial",
]


static func apply(label: Control, weight: int = 800) -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(FONT_NAMES)
	font.font_weight = weight
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	label.add_theme_font_override("font", font)


static func apply_title_shadow(label: Control) -> void:
	label.add_theme_color_override("font_shadow_color", Color(0.02, 0.04, 0.10, 0.62))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 3)


static func clear_shadow(label: Control) -> void:
	label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
