extends Control
class_name ChapterNodeCompleteModal

const UiTypographyScript := preload("res://scripts/ui_typography.gd")

signal continue_pressed
signal secondary_pressed

const DESIGN_SIZE := Vector2(941.0, 1672.0)
const CONTENT_RECT := Rect2(115.5, 480.0, 710.0, 610.0)
const PANEL_RECT := Rect2(0.0, 70.0, 710.0, 514.0)
const TITLE_RECT := Rect2(8.0, 0.0, 694.0, 180.0)
const DIVIDER_RECT := Rect2(13.5, 170.0, 683.0, 137.0)
const DESCRIPTION_RECT := Rect2(50.0, 315.0, 610.0, 82.0)
const NORMAL_BUTTON_RECT := Rect2(100.0, 410.0, 510.0, 140.0)
const CHAPTER_BUTTON_RECT := Rect2(130.0, 400.0, 450.0, 110.0)
const SECONDARY_BUTTON_RECT := Rect2(175.0, 515.0, 360.0, 68.0)
const PANEL_TEXTURE := preload("res://assets/runtime/ui/interfaces/chapter_node_complete/backplates/popup_panel.png")
const TITLE_TEXTURE := preload("res://assets/runtime/ui/interfaces/chapter_node_complete/decorations/title_plaque.png")
const DIVIDER_TEXTURE := preload("res://assets/runtime/ui/interfaces/chapter_node_complete/decorations/crystal_divider.png")
const BUTTON_TEXTURE := preload("res://assets/runtime/ui/interfaces/chapter_node_complete/buttons/primary_button.png")

var _submitted := false
var _design_root: Control
var _content: Control
var _title_label: Label
var _description_label: Label
var _continue_button: TextureButton
var _continue_label: Label
var _secondary_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_interface()
	resized.connect(_layout_for_viewport)
	_layout_for_viewport()
	_play_intro()


func setup(node_id: String) -> void:
	if _title_label:
		_title_label.text = "%s 完成" % node_id
		_description_label.text = "水晶、棋盘与能量状态将带入下一关。"
		_continue_label.text = "继续前进"
		_continue_button.position = NORMAL_BUTTON_RECT.position
		_continue_button.size = NORMAL_BUTTON_RECT.size
		_continue_button.pivot_offset = _continue_button.size * 0.5
		_secondary_button.visible = false


func setup_chapter_completion() -> void:
	if _title_label == null:
		return
	_title_label.text = "第一章完成"
	_description_label.text = "挑战仍将继续。下一站：续战 01/20。"
	_continue_label.text = "继续挑战"
	_continue_button.position = CHAPTER_BUTTON_RECT.position
	_continue_button.size = CHAPTER_BUTTON_RECT.size
	_continue_button.pivot_offset = _continue_button.size * 0.5
	_secondary_button.visible = true


func _build_interface() -> void:
	var shade := ColorRect.new()
	shade.name = "FullScreenShade"
	shade.color = Color(0.01, 0.035, 0.025, 0.70)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	_design_root = Control.new()
	_design_root.name = "DesignRoot"
	_design_root.size = DESIGN_SIZE
	_design_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_design_root)

	_content = Control.new()
	_content.name = "Content"
	_content.position = CONTENT_RECT.position
	_content.size = CONTENT_RECT.size
	_content.pivot_offset = CONTENT_RECT.size * 0.5
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_design_root.add_child(_content)

	var panel := NinePatchRect.new()
	panel.name = "Panel"
	panel.texture = PANEL_TEXTURE
	panel.patch_margin_left = 64
	panel.patch_margin_top = 60
	panel.patch_margin_right = 64
	panel.patch_margin_bottom = 60
	panel.position = PANEL_RECT.position
	panel.size = PANEL_RECT.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(panel)

	var title_bar := TextureRect.new()
	title_bar.name = "TitleBar"
	title_bar.texture = TITLE_TEXTURE
	title_bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_bar.stretch_mode = TextureRect.STRETCH_SCALE
	title_bar.position = TITLE_RECT.position
	title_bar.size = TITLE_RECT.size
	title_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(title_bar)

	_title_label = _make_label("1-1 完成", 57, Color.WHITE, Color(0.04, 0.10, 0.24, 1.0), 6, 900, true)
	_title_label.name = "TitleLabel"
	_title_label.position = Vector2(70.0, 25.0)
	_title_label.size = Vector2(554.0, 112.0)
	title_bar.add_child(_title_label)

	var divider := TextureRect.new()
	divider.name = "CrystalDivider"
	divider.texture = DIVIDER_TEXTURE
	divider.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	divider.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	divider.position = DIVIDER_RECT.position
	divider.size = DIVIDER_RECT.size
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(divider)

	_description_label = _make_label("水晶、棋盘与能量状态将带入下一关。", 30, Color(0.035, 0.14, 0.34, 1.0), Color.TRANSPARENT, 0, 700, false)
	_description_label.name = "DescriptionLabel"
	_description_label.position = DESCRIPTION_RECT.position
	_description_label.size = DESCRIPTION_RECT.size
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(_description_label)

	_continue_button = TextureButton.new()
	_continue_button.name = "ContinueButton"
	_continue_button.texture_normal = BUTTON_TEXTURE
	_continue_button.texture_hover = BUTTON_TEXTURE
	_continue_button.texture_pressed = BUTTON_TEXTURE
	_continue_button.ignore_texture_size = true
	_continue_button.stretch_mode = TextureButton.STRETCH_SCALE
	_continue_button.focus_mode = Control.FOCUS_NONE
	_continue_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_continue_button.position = NORMAL_BUTTON_RECT.position
	_continue_button.size = NORMAL_BUTTON_RECT.size
	_continue_button.pivot_offset = _continue_button.size * 0.5
	_continue_button.button_down.connect(_on_button_down)
	_continue_button.button_up.connect(_on_button_up)
	_continue_button.pressed.connect(_on_continue_pressed)
	_content.add_child(_continue_button)

	_continue_label = _make_label("继续前进", 48, Color(1.0, 0.97, 0.86, 1.0), Color(0.24, 0.10, 0.025, 1.0), 7, 900, true)
	_continue_label.name = "Label"
	_continue_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_continue_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_continue_button.add_child(_continue_label)

	_secondary_button = Button.new()
	_secondary_button.name = "SecondaryButton"
	_secondary_button.text = "返回大厅"
	_secondary_button.visible = false
	_secondary_button.focus_mode = Control.FOCUS_NONE
	_secondary_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_secondary_button.add_theme_font_size_override("font_size", 31)
	_secondary_button.add_theme_color_override("font_color", Color.WHITE)
	_secondary_button.add_theme_color_override("font_outline_color", Color(0.025, 0.08, 0.20, 1.0))
	_secondary_button.add_theme_constant_override("outline_size", 5)
	UiTypographyScript.apply(_secondary_button, 800)
	_secondary_button.add_theme_stylebox_override("normal", _make_secondary_style(Color(0.10, 0.31, 0.61, 1.0), Color(0.45, 0.78, 1.0, 1.0)))
	_secondary_button.add_theme_stylebox_override("hover", _make_secondary_style(Color(0.13, 0.39, 0.72, 1.0), Color(0.64, 0.88, 1.0, 1.0)))
	_secondary_button.add_theme_stylebox_override("pressed", _make_secondary_style(Color(0.07, 0.23, 0.48, 1.0), Color(0.37, 0.67, 0.94, 1.0)))
	_secondary_button.position = SECONDARY_BUTTON_RECT.position
	_secondary_button.size = SECONDARY_BUTTON_RECT.size
	_secondary_button.pressed.connect(_on_secondary_pressed)
	_content.add_child(_secondary_button)


func _layout_for_viewport() -> void:
	if _design_root == null:
		return
	var viewport_size := size if size.x > 0.0 and size.y > 0.0 else DESIGN_SIZE
	var scale_factor := minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	_design_root.position = (viewport_size - DESIGN_SIZE * scale_factor) * 0.5
	_design_root.scale = Vector2.ONE * scale_factor


func _play_intro() -> void:
	_content.scale = Vector2(0.90, 0.90)
	_content.modulate.a = 0.0
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.parallel().tween_property(_content, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_content, "modulate:a", 1.0, 0.16)


func _on_button_down() -> void:
	if _submitted:
		return
	_continue_button.modulate = Color(0.92, 0.82, 0.66, 1.0)
	_continue_button.scale = Vector2(0.96, 0.96)


func _on_button_up() -> void:
	if _submitted:
		return
	_continue_button.modulate = Color.WHITE
	_continue_button.scale = Vector2.ONE


func _on_continue_pressed() -> void:
	if _submitted:
		return
	_submitted = true
	_continue_button.disabled = true
	_secondary_button.disabled = true
	_continue_button.modulate = Color.WHITE
	_continue_button.scale = Vector2.ONE
	continue_pressed.emit()


func _on_secondary_pressed() -> void:
	if _submitted:
		return
	_submitted = true
	_continue_button.disabled = true
	_secondary_button.disabled = true
	secondary_pressed.emit()


func _make_secondary_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(4)
	style.set_corner_radius_all(22)
	style.shadow_color = Color(0.02, 0.05, 0.13, 0.55)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0.0, 5.0)
	return style


func _make_label(text: String, font_size: int, color: Color, outline_color: Color, outline_size: int, font_weight: int = 800, use_shadow: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if outline_size > 0:
		label.add_theme_color_override("font_outline_color", outline_color)
		label.add_theme_constant_override("outline_size", outline_size)
	UiTypographyScript.apply(label, font_weight)
	if use_shadow:
		UiTypographyScript.apply_title_shadow(label)
	else:
		UiTypographyScript.clear_shadow(label)
	return label
