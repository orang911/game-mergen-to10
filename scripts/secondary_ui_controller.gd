extends Control
class_name SecondaryUiController

signal closed(page_id: String, source: String)
signal setting_changed(setting_id: String, enabled: bool)
signal exit_confirmed
signal clear_data_confirmed
signal wallet_changed
signal first_purchase_completed

const UiTypographyScript := preload("res://scripts/ui_typography.gd")
const ROOT := "res://assets/runtime/ui/secondary_centered_v04/"
const APPROVED_EFFECT_SHELLS := false
const FRAMES := ROOT + "frames/"
const ELEMENTS := ROOT + "elements/"
const COMMON := ELEMENTS + "common/"
const ICONS := ELEMENTS + "icons/"
const SETTINGS_ICONS := ICONS + "settings/"
const SHARED_BUTTONS := "res://assets/runtime/ui/shared/buttons/states/"
const SHARED_PANEL := "res://assets/runtime/ui/shared/backplates/panels/panel_light.png"
const SHARED_TITLE := "res://assets/runtime/ui/shared/decorations/titles/title_ribbon_blue.png"
const CONFIRMATION_BACKPLATES := "res://assets/runtime/ui/shared/confirmation/backplates/"
const PAUSE_BACKPLATES := "res://assets/runtime/ui/interfaces/battle_pause/backplates/"
const EXIT_CONFIRM_BACKPLATES := "res://assets/runtime/ui/interfaces/exit_confirm/backplates/"
const SETTINGS_BACKPLATES := "res://assets/runtime/ui/interfaces/settings/backplates/"
const SETTINGS_CONTROLS := "res://assets/runtime/ui/interfaces/settings/controls/"
const FIRST_PURCHASE_ROOT := "res://assets/runtime/ui/interfaces/first_purchase/"
const PIGGY_BANK_BACKPLATES := "res://assets/runtime/ui/interfaces/piggy_bank/backplates/"
const SHOP_ROOT := "res://assets/runtime/ui/interfaces/shop/"
const DAILY_PROGRAM := "res://assets/runtime/ui/interfaces/daily_program/"
const DAILY_PROGRAM_BACKPLATES := DAILY_PROGRAM + "backplates/"
const DAILY_PROGRAM_ICONS := DAILY_PROGRAM + "icons/"
const BENEFITS_PROGRAM := "res://assets/runtime/ui/interfaces/benefits/"
const BENEFITS_PROGRAM_BACKPLATES := BENEFITS_PROGRAM + "backplates/"
const BENEFITS_PROGRAM_ICONS := BENEFITS_PROGRAM + "icons/"
const PURCHASE_CONFIRM_ROOT := "res://assets/runtime/ui/interfaces/purchase_confirmation/"
const PURCHASE_CONFIRM_BACKPLATES := PURCHASE_CONFIRM_ROOT + "backplates/"
const PURCHASE_CONFIRM_ICONS := PURCHASE_CONFIRM_ROOT + "icons/"
# Exact visible bounds measured from the approved 941 x 1672 effect sheets.
# Each page keeps this proportion when opened independently at screen center.
const PAGE_SIZES := {
	"pause": Vector2(384, 282), "exit_confirm": Vector2(299, 176),
	"settings": Vector2(512, 717), "clear_confirm": Vector2(326, 189),
	"daily": Vector2(915, 1513), "benefits": Vector2(700, 714),
	"first_purchase": Vector2(461, 454), "piggy": Vector2(445, 493), "shop": Vector2(465, 493),
	"purchase_confirm": Vector2(518, 552),
}

# V03 shells and their programmatic overlays were authored in these logical
# coordinate spaces. The whole overlay canvas is scaled into PAGE_SIZES so
# frame art, labels, controls and hit targets cannot drift independently.
const AUTHORING_SIZES := {
	"pause": Vector2(660, 485), "exit_confirm": Vector2(660, 388),
	"settings": Vector2(650, 910), "clear_confirm": Vector2(660, 383),
	"daily_combined": Vector2(915, 1513),
	"benefits": Vector2(760, 775), "first_purchase": Vector2(760, 748),
	"piggy": Vector2(760, 842), "shop": Vector2(850, 901),
	"purchase_confirm": Vector2(518, 552),
}

# Coordinates measured on the three approved 941 x 1672 effect sheets. Content
# is authored in this space, then uniformly mapped into the full-size frame.
const EFFECT_COORD_SIZES := {
	"pause": Vector2(384, 282), "exit_confirm": Vector2(299, 176),
	"settings": Vector2(512, 717), "clear_confirm": Vector2(326, 189),
	"daily_combined": Vector2(915, 1513),
	"benefits": Vector2(445, 454), "first_purchase": Vector2(461, 454),
	"piggy": Vector2(445, 493), "shop": Vector2(465, 493),
	"purchase_confirm": Vector2(518, 552),
}

# Benefits was originally laid out in a compact 445 × 454 review canvas and
# then scaled into its 700 × 714 runtime shell.  That is acceptable for art,
# but it rasterizes labels at a small size and enlarges them afterwards.  Keep
# the approved review coordinates as the source of truth, while drawing their
# result directly in the final shell coordinate space.
const BENEFITS_LAYOUT_SCALE := 714.0 / 454.0
const BENEFITS_LAYOUT_REVISION := 5

var service: MetaProgressService
var page_id := ""
var source := "hub"
var _shade: ColorRect
var _panel: NinePatchRect
var _content: Control
var _title: Label
var _title_bar: NinePatchRect
var _daily_tab := "tasks"
var _shop_category := "recommended"
var _shop_page := 0
var _benefits_purchase_button: TextureButton
var _locked := false
var _pending_product_id := ""
var _purchase_return_page := "shop"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_shade = ColorRect.new()
	_shade.name = "Shade"
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.color = Color(0.015, 0.04, 0.10, 0.68)
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_shade.gui_input.connect(_on_shade_input)
	add_child(_shade)
	_panel = NinePatchRect.new()
	_panel.name = "Panel"
	_panel.texture = load(SHARED_PANEL)
	_panel.patch_margin_left = 28
	_panel.patch_margin_top = 28
	_panel.patch_margin_right = 28
	_panel.patch_margin_bottom = 28
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)
	_content = Control.new()
	_content.name = "Content"
	_content.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_content)
	_panel.resized.connect(_layout_v03_shell)
	_title_bar = NinePatchRect.new()
	_title_bar.name = "TitleBar"
	_title_bar.texture = load(SHARED_TITLE)
	_title_bar.patch_margin_left = 30
	_title_bar.patch_margin_right = 30
	_title_bar.position = Vector2(60, 18)
	_title_bar.size = Vector2(540, 82)
	_title_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_title_bar)
	_title = _label("", 42, Color("17345d"))
	_title.name = "Title"
	_title.position = Vector2(55, 25)
	_title.size = Vector2(540, 70)
	UiTypographyScript.apply_title_shadow(_title)
	_content.add_child(_title)
	resized.connect(_layout)


func _process(_delta: float) -> void:
	# Controls created before a Godot script hot-reload retain their old rects.
	# Rebuild an already-open benefits popup exactly once when its composition
	# revision changes, so editor preview and normal gameplay cannot keep showing
	# a stale visual layout after an approved alignment update.
	if not visible or page_id != "benefits" or _content == null:
		return
	if int(_content.get_meta("benefits_layout_revision", -1)) == BENEFITS_LAYOUT_REVISION:
		return
	_content.set_meta("benefits_layout_revision", BENEFITS_LAYOUT_REVISION)
	call_deferred("_refresh")
	call_deferred("_layout")


func setup(progress_service: MetaProgressService) -> void:
	service = progress_service
	if not service.changed.is_connected(_refresh):
		service.changed.connect(_refresh)


func open(requested_page: String, requested_source: String = "hub") -> void:
	if service == null or not PAGE_SIZES.has(requested_page):
		return
	page_id = requested_page
	source = requested_source
	_locked = false
	visible = true
	_refresh()
	_layout()
	_panel.modulate.a = 0.0
	var target_scale := _panel.scale
	_panel.scale = target_scale * 0.92
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.parallel().tween_property(_panel, "modulate:a", 1.0, 0.14)
	tween.parallel().tween_property(_panel, "scale", target_scale, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func open_benefits(_entry_id: String, requested_source: String = "hub") -> void:
	# Both lobby entries display the same ¥6 bundle.  The cards describe package
	# contents and are intentionally not separate selectable products.
	open("benefits", requested_source)


func close() -> void:
	if not visible or _locked:
		return
	var old_page := page_id
	var old_source := source
	visible = false
	page_id = ""
	closed.emit(old_page, old_source)


func _layout() -> void:
	if _panel == null or page_id.is_empty():
		return
	var desired := _current_page_size()
	var available := size - Vector2(40, 100)
	if page_id == "daily":
		available = size - Vector2(16, 80)
	var scale_factor := minf(1.0, minf(available.x / desired.x, available.y / desired.y))
	_panel.size = desired
	_panel.pivot_offset = desired * 0.5
	_panel.scale = Vector2.ONE * scale_factor
	# Pixel-snap the mathematical center. Several approved shells have even widths
	# on the 941 px viewport; leaving them at x.5 softens the one-pixel outline.
	var centered := (size - desired) * 0.5
	if page_id == "daily":
		# Match the supplied reference: the combined sheet starts below the
		# resource bar and leaves the bottom navigation visible. Because the panel
		# scales around its center, compensate the pivot displacement on narrow
		# viewports; otherwise the visible top is pushed hundreds of pixels down.
		var visible_top := 78.0 * scale_factor
		centered.y = visible_top - desired.y * 0.5 * (1.0 - scale_factor)
	elif page_id == "benefits" and is_equal_approx(scale_factor, 1.0):
		# The approved lobby composition sits just below the chapter title rather
		# than touching it at the mathematical center.
		centered.y += 22.0
	_panel.position = Vector2(roundf(centered.x), roundf(centered.y))
	_layout_v03_shell()


func _current_page_size() -> Vector2:
	return PAGE_SIZES[page_id] as Vector2


func _current_authoring_size() -> Vector2:
	if page_id == "daily":
		return AUTHORING_SIZES["daily_combined"] as Vector2
	return AUTHORING_SIZES.get(page_id, _current_page_size()) as Vector2


func _shell_path() -> String:
	match page_id:
		"pause": return PAUSE_BACKPLATES + "ui_battle_pause_shell_v03.png"
		"exit_confirm": return EXIT_CONFIRM_BACKPLATES + "ui_exit_confirm_shell_v03.png"
		"settings": return SETTINGS_BACKPLATES + "ui_settings_shell_v03.png"
		"clear_confirm": return CONFIRMATION_BACKPLATES + "ui_clear_data_confirm_shell_v03.png"
		"daily": return ""
		# The benefits view is assembled from the dedicated v01 cutouts.  Do not
		# fall back to the old, baked v03 sheet: it contains its own obsolete
		# ribbon, cards and icons and would show through the new live layers.
		"benefits": return BENEFITS_PROGRAM_BACKPLATES + "benefits_popup_shell_fixed_v01.png"
		"first_purchase": return FIRST_PURCHASE_ROOT + "backplates/ui_first_purchase_gift_shell_v03.png"
		"piggy": return PIGGY_BANK_BACKPLATES + "ui_piggy_bank_shell_v03.png"
		"shop": return SHOP_ROOT + "backplates/ui_shop_shell_v03.png"
		"purchase_confirm": return PURCHASE_CONFIRM_BACKPLATES + "purchase_popup_shell_fixed_v01.png"
		_: return CONFIRMATION_BACKPLATES + "ui_clear_data_confirm_shell_v03.png"


func _layout_v03_shell() -> void:
	if _content == null or _panel == null:
		return
	if page_id == "benefits":
		_content.size = _panel.size
		_content.scale = Vector2.ONE
		_content.position = Vector2.ZERO
		return
	var key := page_id
	if page_id == "daily":
		key = "daily_combined"
	var design_size := EFFECT_COORD_SIZES.get(key, _panel.size) as Vector2
	var factor := minf(_panel.size.x / design_size.x, _panel.size.y / design_size.y)
	_content.size = design_size
	_content.scale = Vector2.ONE * factor
	_content.position = (_panel.size - design_size * factor) * 0.5


func _add_daily_task_shell() -> void:
	pass


func _refresh() -> void:
	if not visible:
		return
	# Only battle pause uses the specified 65–70% blackout. Hub popups retain
	# the lobby context from the approved effect images with a light veil.
	_shade.color = Color(0.015, 0.04, 0.10, 0.68 if source == "battle" or source == "pause" else 0.45)
	var shell_path := _shell_path()
	_panel.texture = load(shell_path) if not shell_path.is_empty() else null
	_panel.patch_margin_left = 0
	_panel.patch_margin_top = 0
	_panel.patch_margin_right = 0
	_panel.patch_margin_bottom = 0
	_title.add_theme_color_override("font_color", Color("17345d"))
	_title.add_theme_color_override("font_outline_color", Color(0.04, 0.10, 0.24, 0.88))
	_title.add_theme_constant_override("outline_size", 3)
	_title_bar.visible = false
	var authoring := _current_authoring_size()
	_title_bar.size.x = authoring.x - 120.0
	_title.size.x = authoring.x - 110.0
	_clear_dynamic_content()
	match page_id:
		"pause": _build_pause()
		"exit_confirm": _build_confirm("退出后将结束本次挑战", "继续挑战", "确认退出", _cancel_exit, _confirm_exit)
		"settings": _build_settings()
		"clear_confirm": _build_confirm("将删除章节、新手及局内进度", "取消", "确认清空", _cancel_clear, _confirm_clear)
		"daily": _build_daily()
		"benefits": _build_benefits()
		"first_purchase": _build_first_purchase()
		"piggy": _build_piggy()
		"shop": _build_shop()
		"purchase_confirm": _build_purchase_confirm()


func _build_pause() -> void:
	_title_bar.visible = false
	if APPROVED_EFFECT_SHELLS:
		_title.text = ""
		_add_invisible_button(Rect2(29, 120, 157, 135), _open_settings)
		_add_invisible_button(Rect2(199, 120, 156, 135), func(): open("exit_confirm", "pause"))
		return
	_title.text = "暂停中"
	_title.add_theme_color_override("font_color", Color.WHITE)
	_place_title(Rect2(96, 24, 192, 55), 33)
	_add_hit_label_button("设置", Rect2(29, 120, 157, 135), Rect2(29, 203, 157, 44), _open_settings, 26, Color.WHITE)
	_add_hit_label_button("退出", Rect2(199, 120, 156, 135), Rect2(199, 203, 156, 44), func(): open("exit_confirm", "pause"), 26, Color.WHITE)


func _build_confirm(copy: String, left: String, right: String, left_call: Callable, right_call: Callable) -> void:
	_title_bar.visible = false
	_title.text = ""
	var is_exit := page_id == "exit_confirm"
	if APPROVED_EFFECT_SHELLS:
		var left_hit := Rect2(14, 89, 127, 63) if is_exit else Rect2(27, 105, 124, 59)
		var right_hit := Rect2(155, 89, 128, 63) if is_exit else Rect2(175, 105, 124, 59)
		_add_invisible_button(left_hit, left_call)
		_add_invisible_button(right_hit, right_call)
		return
	var display_copy := copy if is_exit else "将删除章节、新手\n及局内进度"
	var message := _label(display_copy, 20 if is_exit else 12, Color.WHITE if is_exit else Color("17345d"))
	message.position = Vector2(20, 8) if is_exit else Vector2(25, 25)
	message.size = Vector2(259, 54) if is_exit else Vector2(_panel.size.x - 50, 63)
	_content.add_child(message)
	var left_rect := Rect2(14, 89, 127, 63) if is_exit else Rect2(27, 105, 124, 59)
	var right_rect := Rect2(155, 89, 128, 63) if is_exit else Rect2(175, 105, 124, 59)
	if is_exit:
		_add_hit_label_button(left, left_rect, Rect2(left_rect.position - Vector2(0, 3), left_rect.size), left_call, 23, Color.WHITE, 900)
		_add_hit_label_button(right, right_rect, Rect2(right_rect.position - Vector2(3, 3), right_rect.size), right_call, 23, Color.WHITE, 900)
	else:
		_add_shell_button(left, left_rect, left_call, Color.WHITE, 15)
		_add_shell_button(right, right_rect, right_call, Color.WHITE, 15)


func _build_settings() -> void:
	_title_bar.visible = false
	if APPROVED_EFFECT_SHELLS:
		_title.text = ""
		_add_invisible_button(Rect2(22, 18, 72, 72), close)
		for index in range(3):
			var ids := ["music", "sound", "vibration"]
			var id: String = ids[index]
			_add_invisible_button(Rect2(350, 128 + index * 95, 110, 60), func():
				match id:
					"music": service.music_enabled = not service.music_enabled
					"sound": service.sound_enabled = not service.sound_enabled
					"vibration": service.vibration_enabled = not service.vibration_enabled
				setting_changed.emit(id, true)
				service.changed.emit()
			)
		_add_invisible_button(Rect2(90, 410, 390, 82), func(): _show_notice("帮助与反馈功能已预留"))
		_add_invisible_button(Rect2(90, 503, 390, 82), func(): _show_notice("隐私与用户协议为本地测试占位"))
		_add_invisible_button(Rect2(108, 615, 296, 70), func(): open("clear_confirm", source))
		return
	_title.text = "设置"
	UiTypographyScript.clear_shadow(_title)
	_title.add_theme_constant_override("outline_size", 0)
	_place_title(Rect2(155, 12, 202, 62), 28)
	_add_invisible_button(Rect2(22, 18, 72, 72), close)
	var settings := [
		["音乐", "music", service.music_enabled, "music.png"], ["音效", "sound", service.sound_enabled, "sound.png"], ["震动", "vibration", service.vibration_enabled, "vibration.png"],
	]
	for index in range(settings.size()):
		var row: Array = settings[index]
		_add_setting_toggle(str(row[0]), str(row[1]), bool(row[2]), 113 + index * 95, str(row[3]))
	_add_row_action("帮助与反馈", 408, "help.png", func(): _show_notice("帮助与反馈功能已预留"))
	_add_row_action("隐私 / 用户协议", 503, "privacy_shield.png", func(): _show_notice("隐私与用户协议为本地测试占位"))
	_add_hit_label_button("清空本地数据", Rect2(108, 625, 296, 58), Rect2(108, 625, 296, 58), func(): open("clear_confirm", source), 18, Color("d8443f"))


func _add_setting_toggle(text: String, id: String, enabled: bool, y: float, icon_file: String) -> void:
	var row := Control.new()
	row.position = Vector2(58, y)
	row.size = Vector2(410, 82)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(row)
	var name_label := _label(text, 30, Color("17345d"), HORIZONTAL_ALIGNMENT_LEFT)
	name_label.position = Vector2(62, 0)
	name_label.size = Vector2(210, 82)
	name_label.add_theme_font_size_override("font_size", 22)
	row.add_child(name_label)
	# Cover the master's layout placeholder with the real current state so the
	# switch changes visually instead of remaining frozen at the concept value.
	var switch_art := TextureRect.new()
	switch_art.name = "Switch_%s" % id
	switch_art.texture = load(SETTINGS_CONTROLS + ("switch_on.png" if enabled else "switch_off.png"))
	switch_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	switch_art.stretch_mode = TextureRect.STRETCH_SCALE
	switch_art.position = Vector2(297, 24)
	switch_art.size = Vector2(102, 48)
	switch_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(switch_art)
	var button := Button.new()
	button.flat = true
	button.position = Vector2(292, 18)
	button.size = Vector2(112, 60)
	button.pressed.connect(func():
		match id:
			"music": service.music_enabled = not service.music_enabled
			"sound": service.sound_enabled = not service.sound_enabled
			"vibration": service.vibration_enabled = not service.vibration_enabled
		setting_changed.emit(id, not enabled)
		service.changed.emit()
	)
	row.add_child(button)


func _add_row_action(text: String, y: float, icon_file: String, callback: Callable) -> void:
	var row := Control.new()
	row.position = Vector2(58, y)
	row.size = Vector2(410, 82)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(row)
	var button := Button.new()
	button.flat = true
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.position = Vector2(62, 0)
	button.size = Vector2(300, 82)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color("17345d"))
	button.add_theme_color_override("font_hover_color", Color("17345d"))
	button.pressed.connect(callback)
	row.add_child(button)


func _build_daily() -> void:
	_title_bar.visible = false
	_title.text = ""
	_daily_tab = "combined"

	var task_layer := Control.new()
	task_layer.name = "DailyTaskSection"
	task_layer.position = Vector2.ZERO
	task_layer.size = Vector2(915, 1047)
	task_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(task_layer)
	_add_combined_task_shell(task_layer)
	_build_combined_task_text(task_layer)

	var signin_layer := Control.new()
	signin_layer.name = "DailySigninSection"
	signin_layer.position = Vector2(0, 1060)
	signin_layer.size = Vector2(915, 453)
	signin_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(signin_layer)
	_add_combined_signin_shell(signin_layer)
	_build_combined_signin_text(signin_layer)

	_add_daily_close_button()


func _add_combined_task_shell(parent: Control) -> void:
	# The new production pack supplies one continuous fixed shell.  Keeping it
	# as a single layer removes the seams and doubled borders from the old V03
	# top/middle/bottom composition.
	_add_stretched_texture(
		parent,
		load(DAILY_PROGRAM_BACKPLATES + "daily_task_panel_shell_fixed_v01.png"),
		Rect2(-12, 90, 942, 970),
		"TaskPanelShell"
	)
	_add_daily_program_nine_patch(
		parent,
		"daily_title_tab_v01.png",
		Rect2(31, 5, 400, 125),
		Vector4(42, 28, 42, 50),
		"TaskTab"
	)


func _add_combined_signin_shell(parent: Control) -> void:
	_add_stretched_texture(
		parent,
		load(DAILY_PROGRAM_BACKPLATES + "daily_signin_panel_shell_fixed_v01.png"),
		Rect2(-9, 75, 938, 374),
		"SigninShell"
	)
	_add_daily_program_nine_patch(
		parent,
		"daily_title_tab_v01.png",
		Rect2(31, 2, 308, 112),
		Vector4(42, 28, 42, 50),
		"SigninTab"
	)
	var inner := Panel.new()
	inner.name = "SigninCardField"
	inner.position = Vector2(25, 130)
	inner.size = Vector2(870, 281)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("18589f")
	style.border_color = Color("78bdf4")
	style.set_border_width_all(3)
	style.set_corner_radius_all(22)
	inner.add_theme_stylebox_override("panel", style)
	parent.add_child(inner)
	parent.move_child(inner, 1)


func _add_stretched_texture(parent: Control, texture: Texture2D, rect: Rect2, node_name: String) -> TextureRect:
	var piece := TextureRect.new()
	piece.name = node_name
	piece.texture = texture
	piece.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	piece.stretch_mode = TextureRect.STRETCH_SCALE
	piece.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	piece.position = rect.position
	piece.size = rect.size
	piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(piece)
	return piece


func _build_combined_task_text(parent: Control) -> void:
	_add_daily_text(parent, "任务", Rect2(31, 16, 400, 84), 48, Color.WHITE)
	var activity := service.get_activity()
	_add_daily_program_nine_patch(
		parent,
		# The activity summary uses the warm highlighted backplate from the
		# approved daily composition. Task rows below keep their own default /
		# claimable state backgrounds.
		"daily_task_row_selected_v01.png",
		# This source has a 13 px transparent left edge and a 14 px transparent
		# right edge, while normal task rows only reserve 7 px per side. Expand
		# the placement by that delta so the painted bounds share one grid.
		# 872 × 179 leaves a painted 845 × 145 plate after the source's
		# transparent gutter is accounted for. This matches the supplied long
		# activity backplate ratio without colliding with the first task row.
		Rect2(24, 126, 872, 179),
		Vector4(28, 24, 28, 24),
		"ActivityRow"
	)
	_add_icon(parent, DAILY_PROGRAM_ICONS + "daily_icon_activity_star_v01.png", Rect2(38, 126, 178, 178))
	_add_daily_text(parent, "今日活跃度", Rect2(201, 167, 330, 48), 30, Color("17345d"), HORIZONTAL_ALIGNMENT_LEFT)
	_add_daily_program_progress(parent, Rect2(199, 216, 426, 40), float(activity) / 100.0)
	_add_daily_text(parent, "%d/100" % activity, Rect2(199, 216, 426, 40), 22, Color.WHITE)
	_add_daily_activity_dots(parent)
	# The approved reward art is tightly cropped. These frames preserve the
	# former on-screen silhouette without scaling the icon into nearby text.
	var chest := _add_icon(parent, DAILY_PROGRAM_ICONS + "daily_icon_chest_v01.png", Rect2(728, 156, 114, 108))
	if service.activity_claimed:
		chest.modulate = Color(0.62, 0.68, 0.76, 0.88)
	_add_daily_text(parent, "100", Rect2(735, 241, 112, 34), 22, Color.WHITE)
	var activity_ready := activity >= 100 and not service.activity_claimed
	var activity_hit := _add_invisible_button_to(parent, Rect2(710, 135, 170, 150), _claim_activity, activity_ready)
	activity_hit.name = "ActivityChestButton"

	var names := {"settle_once": "完成 1 次挑战", "merge_20": "合成 20 次", "kill_30": "击败 30 个怪物", "login": "今日登录"}
	var rewards := {"settle_once": "×10", "merge_20": "×30", "kill_30": "×50", "login": "×20"}
	var task_icons := {
		"settle_once": DAILY_PROGRAM_ICONS + "daily_icon_challenge_v01.png",
		"merge_20": DAILY_PROGRAM_ICONS + "daily_icon_merge_v01.png",
		"kill_30": DAILY_PROGRAM_ICONS + "daily_icon_monster_v01.png",
		"login": DAILY_PROGRAM_ICONS + "daily_icon_login_v01.png",
	}
	var reward_icons := {
		"settle_once": DAILY_PROGRAM_ICONS + "daily_icon_gem_v01.png",
		"merge_20": DAILY_PROGRAM_ICONS + "daily_icon_coin_v01.png",
		"kill_30": DAILY_PROGRAM_ICONS + "daily_icon_coin_v01.png",
		"login": DAILY_PROGRAM_ICONS + "daily_icon_gem_v01.png",
	}
	var task_icon_rects := {
		"settle_once": Rect2(4, 3, 180, 180),
		"merge_20": Rect2(-1, -2, 185, 185),
		"kill_30": Rect2(0, 3, 184, 184),
		"login": Rect2(3, -4, 175, 175),
	}
	var reward_icon_rects := {
		"settle_once": Rect2(506, 42, 80, 84),
		"merge_20": Rect2(511, 48, 74, 74),
		"kill_30": Rect2(511, 48, 74, 74),
		"login": Rect2(506, 42, 80, 84),
	}
	var task_ids := ["settle_once", "merge_20", "kill_30", "login"]
	var row_y := [288.0, 473.0, 658.0, 843.0]
	var row_heights := [183.0, 184.0, 207.0, 180.0]
	var row_shell_rects := [
		Rect2(30, 284, 860, 190),
		Rect2(30, 469, 860, 191),
		Rect2(30, 654, 860, 191),
		Rect2(30, 839, 860, 186),
	]
	var progress_rects := [
		Rect2(172, 102, 255, 38),
		Rect2(171, 102, 255, 38),
		Rect2(170, 102, 255, 38),
		Rect2(170, 97, 255, 38),
	]
	var slot_y := [23.0, 23.0, 23.0, 20.0]
	for index in range(task_ids.size()):
		var task_id: String = task_ids[index]
		var definition := MetaProgressService.TASKS[task_id] as Dictionary
		var progress := int(service.task_progress.get(task_id, 0))
		var target := int(definition["target"])
		var claimed := bool(service.task_claimed.get(task_id, false))
		var can_claim := progress >= target and not claimed
		var y: float = row_y[index]
		var row_rect := Rect2(33, y, 856, float(row_heights[index]))
		var content_offset := Vector2(3, 2)
		var row_shell_rect: Rect2 = row_shell_rects[index] as Rect2
		if can_claim:
			# Selection expands only the painted backdrop. The content container
			# stays on the same absolute grid, so task state changes never move an
			# icon, label, progress bar or hit target.
			row_shell_rect = Rect2(20, y - 15.0, 884, 215)
		_add_daily_program_nine_patch(
			parent,
			"daily_task_row_selected_v01.png" if can_claim else "daily_task_row_default_v01.png",
			row_shell_rect,
			Vector4(28, 24, 28, 24),
			"TaskRowBackdrop_%s" % task_id
		)
		var row := Control.new()
		row.name = "TaskRow_%s" % task_id
		row.position = row_rect.position
		row.size = row_rect.size
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(row)
		var slot_file := "daily_icon_slot_selected_v01.png" if can_claim else "daily_icon_slot_v01.png"
		_add_stretched_texture(row, load(DAILY_PROGRAM_BACKPLATES + slot_file), Rect2(Vector2(25, slot_y[index]) + content_offset, Vector2(128, 132)), "TaskIconSlot_%s" % task_id)
		_add_icon(row, str(task_icons[task_id]), task_icon_rects[task_id] as Rect2)
		_add_daily_text(row, str(names[task_id]), Rect2(Vector2(177, 32) + content_offset, Vector2(340, 52)), 30, Color("17345d"), HORIZONTAL_ALIGNMENT_LEFT)
		var progress_rect: Rect2 = progress_rects[index] as Rect2
		_add_daily_program_progress(row, Rect2(progress_rect.position + content_offset, progress_rect.size), float(progress) / float(target))
		_add_daily_text(row, "%d/%d" % [progress, target], Rect2(progress_rect.position + content_offset, progress_rect.size), 22, Color.WHITE)
		_add_icon(row, str(reward_icons[task_id]), reward_icon_rects[task_id] as Rect2)
		_add_daily_text(row, str(rewards[task_id]), Rect2(Vector2(493, 121) + content_offset, Vector2(100, 37)), 24, Color("17345d"))
		var button_text := "已领取" if claimed else "领取" if can_claim else "未完成"
		var callback := Callable() if claimed or not can_claim else func(): _claim_task(task_id)
		var state := "claimed" if claimed else "claim" if can_claim else "disabled"
		var button_rect := Rect2(Vector2(635, 48) + content_offset, Vector2(189, 88))
		var button_font_size := 31
		if can_claim:
			button_rect = Rect2(Vector2(637, 35) + content_offset, Vector2(190, 108))
			button_font_size = 36
		_add_daily_program_button(row, button_text, button_rect, callback, state, can_claim, button_font_size)


func _add_daily_activity_dots(parent: Control) -> void:
	for index in range(4):
		var dot := Polygon2D.new()
		dot.name = "ActivityMilestoneDot_%d" % (index + 1)
		var points := PackedVector2Array()
		for segment in range(16):
			var angle := TAU * float(segment) / 16.0
			points.append(Vector2(cos(angle), sin(angle)) * 6.0)
		dot.polygon = points
		dot.position = Vector2(642.0 + float(index) * 28.0, 235.0)
		dot.color = Color("356ba8")
		dot.z_index = 5
		parent.add_child(dot)


func _daily_signin_display_day() -> int:
	var preview_day := service.get_signin_preview_day()
	# After today's reward is claimed, keep the service's real date gate intact
	# but preview tomorrow's card so the next reward is visually unambiguous.
	if not service.is_signin_available() and service.get_signin_claimed_days() > 0:
		return preview_day % 7 + 1
	return preview_day


func _daily_signin_card_rects() -> Array[Rect2]:
	var current_index := _daily_signin_display_day() - 1
	# These are the compact-card anchors measured from the approved 941 px
	# composition. A selected card adds 70 px of occupied width, so only cards
	# after it move; the two panel edges therefore remain visually locked.
	var reference_x := [35.0, 142.0, 250.0, 352.0, 463.0, 570.0, 675.0]
	var rects: Array[Rect2] = []
	for index in range(7):
		var selected_expansion := 70.0 if current_index < 6 and index > current_index else 0.0
		var x: float = reference_x[index] + selected_expansion
		if current_index == 6:
			x += 10.0
		if index == current_index:
			rects.append(Rect2(x, 133, 178, 280))
		elif index == 6:
			rects.append(Rect2(x, 148, 140, 251))
		else:
			rects.append(Rect2(x, 148, 105, 251))
	return rects


func _build_combined_signin_text(parent: Control) -> void:
	_add_daily_text(parent, "签到", Rect2(31, 8, 308, 77), 41, Color.WHITE)
	var reward_labels := ["×20", "×30", "×20", "×50", "×20", "×30", "×100"]
	var reward_art := [
		"daily_icon_gem_v01.png", "daily_icon_coin_v01.png", "daily_icon_gem_v01.png",
		"daily_icon_coin_v01.png", "daily_icon_gem_v01.png", "daily_icon_coin_v01.png",
		"daily_icon_chest_v01.png",
	]
	var claimed_days := service.get_signin_claimed_days()
	var available := service.is_signin_available()
	var is_tomorrow_preview := not available and claimed_days > 0
	var current_index := _daily_signin_display_day() - 1
	var card_rects := _daily_signin_card_rects()
	for index in range(7):
		var is_current := index == current_index
		var is_premium := index == 6
		var card_rect: Rect2 = card_rects[index]
		var card_file := "daily_signin_card_premium_v01.png" if is_premium else "daily_signin_card_default_v01.png"
		if is_current and not is_premium:
			card_file = "daily_signin_card_selected_v01.png"
		var layer_z := 10 if is_current else 2
		var card_back := _add_stretched_texture(parent, load(DAILY_PROGRAM_BACKPLATES + card_file), card_rect, "SigninCard_%d" % (index + 1))
		card_back.z_index = layer_z
		# Keep day numbers optically centered in the dark header rather than
		# touching its top edge. The selected card is taller, so it needs a
		# slightly larger offset to retain the same visual center.
		var day_label_offset_y := 30.0 if is_current else 26.0
		var day_label := _add_daily_text(parent, "第%d天" % (index + 1), Rect2(card_rect.position.x, card_rect.position.y + day_label_offset_y, card_rect.size.x, 36), 24, Color.WHITE)
		day_label.z_index = layer_z + 1
		var icon_size := Vector2(78, 86) if is_current else Vector2(74, 82)
		var icon_offset_y := 68.0 if is_current else 70.0
		if index == 1 or index == 3 or index == 5:
			icon_size = Vector2(80, 80) if is_current else Vector2(74, 74)
			icon_offset_y = 78.0 if is_current else 71.0
		elif is_premium:
			icon_size = Vector2(120, 108)
			icon_offset_y = 58.0
		var reward_icon := _add_icon(parent, DAILY_PROGRAM_ICONS + str(reward_art[index]), Rect2(card_rect.position.x + (card_rect.size.x - icon_size.x) * 0.5, card_rect.position.y + icon_offset_y, icon_size.x, icon_size.y))
		reward_icon.name = "SigninReward_%d" % (index + 1)
		reward_icon.z_index = layer_z + 1
		var reward_y := card_rect.position.y + (177.0 if is_premium else 145.0)
		var reward_label := _add_daily_text(parent, str(reward_labels[index]), Rect2(card_rect.position.x, reward_y, card_rect.size.x, 36), 24, Color.WHITE)
		reward_label.z_index = layer_z + 1
		if index < claimed_days and not (is_tomorrow_preview and is_current):
			var claimed_check := _add_icon(parent, DAILY_PROGRAM_ICONS + "daily_icon_claimed_check_v01.png", Rect2(card_rect.position.x + (card_rect.size.x - 116) * 0.5, card_rect.position.y + 158, 116, 94))
			claimed_check.z_index = layer_z + 2
		if is_current and available:
			var signin_hit := _add_daily_program_button(parent, "今日签到", Rect2(card_rect.position.x + 20, card_rect.position.y + 197, card_rect.size.x - 40, 62), _claim_signin, "claim", true, 24)
			signin_hit.name = "CurrentSigninButton"
			signin_hit.z_index = layer_z + 3
		elif is_current and is_tomorrow_preview:
			var tomorrow_badge := _add_daily_program_button(parent, "明日领取", Rect2(card_rect.position.x + 20, card_rect.position.y + 197, card_rect.size.x - 40, 62), Callable(), "claim", false, 22)
			tomorrow_badge.name = "TomorrowSigninBadge"
			tomorrow_badge.z_index = layer_z + 3


func _add_daily_text(parent: Control, text: String, rect: Rect2, font_size: int, color: Color, alignment := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label := _label(text, font_size, color, alignment)
	label.position = rect.position
	label.size = rect.size
	if color == Color.WHITE:
		label.add_theme_color_override("font_outline_color", Color("07172f"))
		label.add_theme_constant_override("outline_size", 4)
	parent.add_child(label)
	return label


func _add_invisible_button_to(parent: Control, rect: Rect2, callback: Callable, enabled: bool) -> Button:
	var button := Button.new()
	button.flat = true
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.disabled = not enabled
	if enabled and callback.is_valid():
		button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _add_daily_close_button() -> void:
	var button := TextureButton.new()
	button.name = "DailyCloseButton"
	button.texture_normal = load(DAILY_PROGRAM_BACKPLATES + "daily_return_button_v02.png")
	button.texture_pressed = button.texture_normal
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	button.position = Vector2(796, 8)
	button.size = Vector2(97, 89)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(close)
	button.button_down.connect(func(): button.scale = Vector2(0.94, 0.94); button.pivot_offset = button.size * 0.5)
	button.button_up.connect(func(): button.scale = Vector2.ONE)
	var arrow := TextureRect.new()
	arrow.name = "ArrowGlyph"
	arrow.texture = load(DAILY_PROGRAM_ICONS + "daily_return_arrow_v02.png")
	arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arrow.stretch_mode = TextureRect.STRETCH_SCALE
	arrow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	arrow.position = Vector2(5, 6)
	arrow.size = Vector2(88, 80)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(arrow)
	_content.add_child(button)


func _add_daily_sparkle_trail() -> void:
	# The approved composition uses one non-interactive golden reward trail to
	# visually connect the activity chest with today's sign-in card.
	var current_index := service.get_signin_preview_day() - 1
	var selected_rect: Rect2 = _daily_signin_card_rects()[current_index]
	var selected_center := Vector2(
		selected_rect.position.x + selected_rect.size.x * 0.5,
		1060.0 + selected_rect.position.y + selected_rect.size.y * 0.5
	)
	var approach_direction := 1.0 if selected_center.x < 560.0 else -1.0
	var approach := Vector2(selected_center.x + 90.0 * approach_direction, 1228.0)
	var curve := Curve2D.new()
	curve.bake_interval = 8.0
	curve.add_point(Vector2(700, 102), Vector2.ZERO, Vector2(-18, 96))
	curve.add_point(Vector2(682, 505), Vector2(-10, -120), Vector2(12, 118))
	curve.add_point(Vector2(875, 780), Vector2(-120, -80), Vector2(8, 82))
	curve.add_point(Vector2(674, 1018), Vector2(130, -92), Vector2(-34, 92))
	curve.add_point(approach, Vector2(72 * approach_direction, -88), Vector2(-34 * approach_direction, 58))
	curve.add_point(selected_center, Vector2(40 * approach_direction, -52), Vector2.ZERO)
	var glow := Line2D.new()
	glow.name = "DailyRewardTrailGlow"
	glow.points = curve.get_baked_points()
	glow.width = 9.0
	glow.default_color = Color(1.0, 0.72, 0.16, 0.12)
	glow.antialiased = true
	glow.joint_mode = Line2D.LINE_JOINT_ROUND
	glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	glow.end_cap_mode = Line2D.LINE_CAP_ROUND
	glow.z_index = 29
	_content.add_child(glow)
	var trail := Line2D.new()
	trail.name = "DailyRewardTrail"
	trail.points = curve.get_baked_points()
	trail.width = 2.25
	trail.default_color = Color(1.0, 0.83, 0.32, 0.78)
	trail.antialiased = true
	trail.joint_mode = Line2D.LINE_JOINT_ROUND
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	trail.z_index = 30
	_content.add_child(trail)
	for spec in [
		[Vector2(700, 102), 8.0], [Vector2(682, 505), 5.0],
		[Vector2(842, 780), 8.0], [Vector2(674, 1018), 6.0],
		[approach, 7.0], [selected_center, 9.0],
	]:
		var point: Vector2 = spec[0]
		var radius: float = spec[1]
		var sparkle := Polygon2D.new()
		sparkle.name = "RewardSparkle"
		sparkle.polygon = PackedVector2Array([
			Vector2(0, -radius), Vector2(radius * 0.34, -radius * 0.34),
			Vector2(radius, 0), Vector2(radius * 0.34, radius * 0.34),
			Vector2(0, radius), Vector2(-radius * 0.34, radius * 0.34),
			Vector2(-radius, 0), Vector2(-radius * 0.34, -radius * 0.34),
		])
		sparkle.position = point
		sparkle.color = Color(1.0, 0.91, 0.48, 0.92)
		sparkle.z_index = 31
		_content.add_child(sparkle)


func _add_daily_program_nine_patch(parent: Control, file_name: String, rect: Rect2, margins: Vector4, node_name: String) -> NinePatchRect:
	var plate := NinePatchRect.new()
	plate.name = node_name
	plate.texture = load(DAILY_PROGRAM_BACKPLATES + file_name)
	plate.patch_margin_left = int(margins.x)
	plate.patch_margin_top = int(margins.y)
	plate.patch_margin_right = int(margins.z)
	plate.patch_margin_bottom = int(margins.w)
	plate.position = rect.position
	plate.size = rect.size
	plate.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(plate)
	return plate


func _add_daily_program_progress(parent: Control, rect: Rect2, ratio: float) -> void:
	# Leave an actual center strip. A top+bottom sum equal to the full height
	# collapses the NinePatch middle and folds both rounded caps together.
	var vertical_margin := maxi(1, int(floorf((rect.size.y - 2.0) * 0.5)))
	_add_daily_program_nine_patch(
		parent,
		"daily_progress_track_v01.png",
		rect,
		Vector4(24, vertical_margin, 24, vertical_margin),
		"ProgressTrack"
	)
	var clipped_ratio := clampf(ratio, 0.0, 1.0)
	if clipped_ratio <= 0.0:
		return
	var clip := Control.new()
	clip.name = "ProgressFillClip"
	clip.clip_contents = true
	clip.position = Vector2(roundf(rect.position.x), roundf(rect.position.y))
	var clip_width := rect.size.x if is_equal_approx(clipped_ratio, 1.0) else roundf(rect.size.x * clipped_ratio)
	clip.size = Vector2(clip_width, roundf(rect.size.y))
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(clip)
	var fill := NinePatchRect.new()
	fill.name = "ProgressFill"
	fill.texture = load(DAILY_PROGRAM_BACKPLATES + "daily_progress_fill_v01.png")
	fill.patch_margin_left = 24
	fill.patch_margin_top = vertical_margin
	fill.patch_margin_right = 24
	fill.patch_margin_bottom = vertical_margin
	fill.size = rect.size
	fill.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(fill)


func _add_daily_program_button(parent: Control, text: String, rect: Rect2, callback: Callable, state: String, enabled: bool, font_size: int = 32) -> TextureButton:
	var file_name := {
		"disabled": "daily_button_disabled_v01.png",
		"claimed": "daily_button_claimed_v01.png",
		"claim": "daily_button_claim_v01.png",
	}.get(state, "daily_button_disabled_v01.png") as String
	var button := TextureButton.new()
	button.name = "TaskStateButton_%s" % state
	button.texture_normal = load(DAILY_PROGRAM_BACKPLATES + file_name)
	button.texture_pressed = button.texture_normal
	button.texture_disabled = button.texture_normal
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	button.position = rect.position
	button.size = rect.size
	button.disabled = not enabled
	button.focus_mode = Control.FOCUS_NONE
	if enabled and callback.is_valid():
		button.pressed.connect(callback)
		button.button_down.connect(func(): button.scale = Vector2(0.96, 0.96); button.pivot_offset = button.size * 0.5)
		button.button_up.connect(func(): button.scale = Vector2.ONE)
	var text_color := Color.WHITE if state == "claim" else Color("d7e1ee") if state == "disabled" else Color("b9cbe2")
	var label := _label(text, font_size, text_color)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if state == "claim":
		label.add_theme_color_override("font_outline_color", Color("7a3d08"))
		label.add_theme_constant_override("outline_size", 4)
	else:
		label.add_theme_color_override("font_outline_color", Color("263a59"))
		label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)
	parent.add_child(button)
	return button


func _build_task_content() -> void:
	var names := {"settle_once": "完成 1 次挑战", "merge_20": "合成 20 次", "kill_30": "击败 30 个怪物", "login": "今日登录"}
	var rewards := {"settle_once": "×10", "merge_20": "×30", "kill_30": "×50", "login": "×20"}
	var task_icons := {
		"settle_once": ICONS + "task_swords.png",
		"merge_20": DAILY_PROGRAM_ICONS + "daily_icon_merge_v01.png",
		"kill_30": DAILY_PROGRAM_ICONS + "daily_icon_monster_v01.png",
		"login": "res://assets/runtime/ui/shared/meta_icons/atlas_regions/lobby_icon_signin_calendar_v01.tres",
	}
	var reward_icons := {
		"settle_once": "res://assets/runtime/ui/shared/meta_icons/atlas_regions/lobby_icon_currency_diamond_v01.tres",
		"merge_20": ICONS + "coin.png",
		"kill_30": ICONS + "coin.png",
		"login": "res://assets/runtime/ui/shared/meta_icons/atlas_regions/lobby_icon_currency_diamond_v01.tres",
	}
	_build_activity_strip()
	var row_positions := [388.0, 555.0, 724.0, 890.0]
	var task_ids := ["settle_once", "merge_20", "kill_30", "login"]
	for index in range(task_ids.size()):
		var task_id: String = task_ids[index]
		var definition := MetaProgressService.TASKS[task_id] as Dictionary
		var progress := int(service.task_progress.get(task_id, 0))
		var target := int(definition["target"])
		var row := Control.new()
		row.position = Vector2(53, row_positions[index])
		row.size = Vector2(774, 158)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_content.add_child(row)
		_add_icon(row, DAILY_PROGRAM_ICONS + "daily_icon_slot_v01.png", Rect2(14, 15, 112, 112))
		_add_icon(row, str(task_icons[task_id]), Rect2(28, 28, 84, 84))
		var name_label := _label(str(names[task_id]), 25, Color("17345d"), HORIZONTAL_ALIGNMENT_LEFT)
		name_label.position = Vector2(145, 17)
		name_label.size = Vector2(330, 44)
		row.add_child(name_label)
		_add_progress_to(row, Rect2(158, 88, 258, 33), float(progress) / float(target))
		var progress_label := _label("%d/%d" % [progress, target], 19, Color.WHITE)
		progress_label.position = Vector2(158, 86)
		progress_label.size = Vector2(258, 37)
		row.add_child(progress_label)
		_add_icon(row, str(reward_icons[task_id]), Rect2(461, 21, 96, 96))
		var reward_label := _label(str(rewards[task_id]), 18, Color("17345d"))
		reward_label.position = Vector2(456, 101)
		reward_label.size = Vector2(98, 35)
		row.add_child(reward_label)
		var claimed := bool(service.task_claimed.get(task_id, false))
		var can_claim := progress >= target and not claimed
		var button_text := "已领取" if claimed else "领取" if can_claim else "前往"
		var button_color := "gray" if claimed else "claim" if can_claim else "go"
		var button_call := Callable() if claimed else func(): _claim_task(task_id) if can_claim else close()
		_add_task_button(row, button_text, Rect2(584, 43, 178, 78), button_call, button_color, not claimed)


func _build_activity_strip() -> void:
	var activity := service.get_activity()
	var tag_tip := Polygon2D.new()
	tag_tip.polygon = PackedVector2Array([Vector2(198, 122), Vector2(212, 146), Vector2(198, 170)])
	tag_tip.color = Color("ffc34c")
	_content.add_child(tag_tip)
	var tag := Panel.new()
	tag.position = Vector2(44, 122)
	tag.size = Vector2(154, 48)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tag_style := StyleBoxFlat.new()
	tag_style.bg_color = Color("ffc34c")
	tag_style.border_color = Color("ed8d12")
	tag_style.set_border_width_all(2)
	tag_style.corner_radius_top_left = 8
	tag_style.corner_radius_bottom_left = 8
	tag_style.corner_radius_top_right = 4
	tag_style.corner_radius_bottom_right = 4
	tag.add_theme_stylebox_override("panel", tag_style)
	_content.add_child(tag)
	var caption := _label("今日活跃", 25, Color("7b4606"), HORIZONTAL_ALIGNMENT_LEFT)
	caption.position = Vector2(16, 0)
	caption.size = Vector2(138, 48)
	tag.add_child(caption)
	_add_progress_to(_content, Rect2(93, 220, 696, 24), float(activity) / 100.0)
	# Rebuild the activity-start medal from a formal gold star plus the red
	# ribbon backplate. The previous blue-square task icon did not match the
	# approved effect and visually read as a separate task button.
	var ribbon := Panel.new()
	ribbon.position = Vector2(80, 170)
	ribbon.size = Vector2(32, 46)
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ribbon_style := StyleBoxFlat.new()
	ribbon_style.bg_color = Color("c73827")
	ribbon_style.border_color = Color("8a2119")
	ribbon_style.set_border_width_all(2)
	ribbon_style.corner_radius_top_left = 5
	ribbon_style.corner_radius_top_right = 5
	ribbon.add_theme_stylebox_override("panel", ribbon_style)
	_content.add_child(ribbon)
	_add_icon(_content, "res://assets/runtime/ui/components/rating_stars/icons/star_active.png", Rect2(58, 178, 76, 70))
	var points := [0, 25, 50, 75, 100]
	var centers := [96.0, 276.0, 447.0, 618.0, 789.0]
	for index in range(points.size()):
		if index > 0:
			var milestone := int(points[index])
			var chest_file := "daily_chest_ready_v01.png" if activity >= milestone else "daily_chest_locked_v01.png"
			_add_icon(_content, DAILY_PROGRAM_ICONS + "daily_icon_chest_v01.png", Rect2(centers[index] - 42, 177, 84, 63))
		var number := _label(str(points[index]), 19, Color("73440c"))
		number.position = Vector2(centers[index] - 38, 247)
		number.size = Vector2(76, 32)
		_content.add_child(number)
	var activity_value := _label(str(activity), 19, Color.WHITE)
	activity_value.position = Vector2(67, 194)
	activity_value.size = Vector2(58, 35)
	_content.add_child(activity_value)
	var activity_ready := activity >= 100 and not service.activity_claimed
	var activity_text := "已领取" if service.activity_claimed else "领取" if activity_ready else "更多奖励"
	var activity_call := Callable() if service.activity_claimed else _claim_activity if activity_ready else func(): _daily_tab = "signin"; _refresh(); _layout()
	_add_task_button(_content, activity_text, Rect2(650, 308, 166, 66), activity_call, "gray" if service.activity_claimed else "claim" if activity_ready else "go", not service.activity_claimed)


func _add_progress_to(parent: Control, rect: Rect2, ratio: float) -> void:
	var track := TextureRect.new()
	track.texture = load(DAILY_PROGRAM_BACKPLATES + "daily_progress_track_v01.png")
	track.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	track.stretch_mode = TextureRect.STRETCH_SCALE
	track.position = rect.position
	track.size = rect.size
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(track)
	var clip := Control.new()
	clip.clip_contents = true
	clip.position = rect.position + Vector2(4, 4)
	clip.size = Vector2((rect.size.x - 8) * clampf(ratio, 0.0, 1.0), rect.size.y - 8)
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(clip)
	var fill := TextureRect.new()
	fill.texture = load(DAILY_PROGRAM_BACKPLATES + "daily_progress_fill_v01.png")
	fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fill.stretch_mode = TextureRect.STRETCH_SCALE
	fill.size = Vector2(rect.size.x - 8, rect.size.y - 8)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(fill)


func _add_task_button(parent: Control, text: String, rect: Rect2, callback: Callable, color: String, enabled: bool) -> void:
	var button := TextureButton.new()
	var button_file := "daily_button_disabled_v01.png" if color == "gray" else "daily_button_claim_v01.png" if color == "claim" else "daily_return_button_v02.png"
	var normal_path := DAILY_PROGRAM_BACKPLATES + button_file
	button.texture_normal = load(normal_path)
	button.texture_pressed = button.texture_normal
	button.texture_disabled = button.texture_normal
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.position = rect.position
	button.size = rect.size
	button.disabled = not enabled
	button.focus_mode = Control.FOCUS_NONE
	if enabled and callback.is_valid():
		button.pressed.connect(callback)
		button.button_down.connect(func(): button.scale = Vector2(0.96, 0.96); button.pivot_offset = button.size * 0.5)
		button.button_up.connect(func(): button.scale = Vector2.ONE)
	var label := _label(text, 34, Color.WHITE if color != "gray" else Color("53657e"))
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(label)
	parent.add_child(button)


func _claim_task(task_id: String) -> void:
	if not service.claim_task(task_id).is_empty():
		wallet_changed.emit()


func _claim_activity() -> void:
	if not service.claim_activity_chest().is_empty():
		wallet_changed.emit()


func _claim_signin() -> void:
	if not service.claim_signin().is_empty():
		wallet_changed.emit()


func _build_benefits() -> void:
	# Dedicated layered composition (back to front): new outer shell, title
	# ribbon, shield/title, offer cards, product icons and the live state text.
	# Every visual here is a runtime copy of the approved benefits cutout pack;
	# the production source is deliberately never referenced by the scene.
	_content.set_meta("benefits_layout_revision", BENEFITS_LAYOUT_REVISION)
	var title_ribbon := _add_stretched_texture(
		_content,
		load(BENEFITS_PROGRAM_BACKPLATES + "benefits_title_ribbon_v01.png"),
		# The approved composition deliberately uses a wide, shallow ribbon;
		# keeping the source aspect here made the title look like a compact tag.
		# Keep the painted title outline on the popup's top edge.  Its former
		# vertical inset made the lower title outline cut into the body frame.
		_benefit_rect(Rect2(-5, 0, 342, 75)),
		"BenefitTitleRibbon"
	)
	_content.move_child(title_ribbon, 0)
	var left_card := _add_stretched_texture(
		_content,
		load(BENEFITS_PROGRAM_BACKPLATES + "benefits_offer_card_v01.png"),
		# The card source has a long, intentionally quiet lower area.  It must be
		# kept visible so the benefit copy and the green permanent-state button
		# remain inside the same card, rather than floating on the popup shell.
		# The art has a 12 px transparent gutter. These values align the painted
		# card edges (not its source canvas) to the two-card grid in the approval.
		_benefit_rect(Rect2(20, 82, 200, 298)),
		"BenefitCard_double_coin"
	)
	_content.move_child(left_card, 0)
	var right_card := _add_stretched_texture(
		_content,
		load(BENEFITS_PROGRAM_BACKPLATES + "benefits_offer_card_v01.png"),
		_benefit_rect(Rect2(225, 82, 200, 298)),
		"BenefitCard_remove_ads"
	)
	_content.move_child(right_card, 0)
	# Match the shield to the ribbon's painted vertical center.  The source has
	# transparent top padding, so its control starts above neither the title nor
	# the ribbon—even though the visible emblem does.
	_add_icon(_content, BENEFITS_PROGRAM_ICONS + "benefits_icon_shield_star_v01.png", _benefit_rect(Rect2(24, 14, 72, 58))).name = "BenefitShieldIcon"
	_add_icon(_content, BENEFITS_PROGRAM_ICONS + "benefits_icon_coin_stack_v01.png", _benefit_rect(Rect2(50, 98, 132, 102))).name = "BenefitCoinIcon"
	_add_icon(_content, BENEFITS_PROGRAM_ICONS + "benefits_icon_no_ad_base_v01.png", _benefit_rect(Rect2(251, 98, 124, 104))).name = "BenefitNoAdIcon"
	_title.text = "权益"
	_title.add_theme_color_override("font_color", Color.WHITE)
	_title.add_theme_color_override("font_outline_color", Color("17345d"))
	_title.add_theme_constant_override("outline_size", _benefit_metric(2))
	_title.add_theme_color_override("font_shadow_color", Color(0.02, 0.05, 0.14, 0.52))
	_title.add_theme_constant_override("shadow_offset_x", _benefit_metric(1))
	_title.add_theme_constant_override("shadow_offset_y", _benefit_metric(2))
	_place_title(_benefit_rect(Rect2(80, 16, 122, 48)), _benefit_metric(34))

	var double_marker := _add_benefit_label("BenefitDoubleMarker", "x2", Rect2(140, 165, 55, 37), 34, 900, Color("66bc16"))
	double_marker.add_theme_color_override("font_outline_color", Color("17320a"))
	double_marker.add_theme_constant_override("outline_size", _benefit_metric(2))
	var ad_marker := _add_benefit_label("BenefitAdMarker", "AD", Rect2(259, 118, 108, 64), 44, 900, Color("f7f8f6"))
	ad_marker.add_theme_color_override("font_outline_color", Color("16191e"))
	ad_marker.add_theme_constant_override("outline_size", _benefit_metric(3))

	# Product names sit 15 final screen pixels higher than the copy row, matching
	# the approved card rhythm without moving the icon or lower benefit details.
	var double_name := _add_benefit_label("BenefitName_double_coin", "双倍金币", Rect2(27, 210.5, 180, 38), 26)
	var remove_ads_name := _add_benefit_label("BenefitName_remove_ads", "去广告", Rect2(238, 210.5, 180, 38), 26)
	for name_label in [double_name, remove_ads_name]:
		name_label.add_theme_color_override("font_outline_color", Color("f7f8f4"))
		name_label.add_theme_constant_override("outline_size", _benefit_metric(2))
		name_label.add_theme_color_override("font_shadow_color", Color(0.04, 0.08, 0.14, 0.20))
		name_label.add_theme_constant_override("shadow_offset_y", _benefit_metric(1))
	_add_benefit_label("BenefitCopy_double_coin", "挑战结算金币 +100%", Rect2(30, 260, 174, 40), 15, 700, Color("17243a"))
	_add_benefit_label("BenefitCopy_remove_ads", "移除非主动广告\n奖励广告保留", Rect2(241, 258, 174, 58), 15, 700, Color("17243a"))
	_add_stretched_texture(
		_content,
		load(BENEFITS_PROGRAM_BACKPLATES + "benefits_button_entitled_v01.png"),
		# The approved green plate occupies 78% of the card's painted width.
		# Its former 180-unit width filled almost the entire card and made the
		# button read as skewed against the right edge.
		_benefit_rect(Rect2(41, 293, 158, 46)),
		"BenefitPermanentPlate"
	)
	var permanent_label := _add_benefit_label("BenefitPermanent", "永久生效", Rect2(45, 297, 150, 35), 17, 800, Color("17345d"))
	permanent_label.add_theme_color_override("font_outline_color", Color("e8ffc6"))
	permanent_label.add_theme_constant_override("outline_size", _benefit_metric(1))

	_benefits_purchase_button = _add_button(
		"",
		# The button source also carries a transparent safety edge.  Positioning
		# its canvas this way makes the yellow painted plate share the center line
		# and lower baseline of the approved effect.
		_benefit_rect(Rect2(104, 359, 232, 74)),
		func(): _request_purchase("benefits_bundle"),
		"yellow",
		true,
		_benefit_metric(34)
	)
	_benefits_purchase_button.name = "BenefitsPurchaseButton"
	_benefits_purchase_button.texture_normal = load(BENEFITS_PROGRAM_BACKPLATES + "benefits_button_purchase_v01.png")
	_benefits_purchase_button.texture_pressed = _benefits_purchase_button.texture_normal
	for child in _benefits_purchase_button.get_children():
		if child is Label:
			var cta_label := child as Label
			cta_label.add_theme_color_override("font_outline_color", Color("7a3d08"))
			cta_label.add_theme_constant_override("outline_size", _benefit_metric(3))
			cta_label.add_theme_color_override("font_shadow_color", Color(0.31, 0.12, 0.02, 0.55))
			cta_label.add_theme_constant_override("shadow_offset_y", _benefit_metric(2))
	_refresh_benefits_purchase_button()


func _add_benefit_label(node_name: String, text: String, rect: Rect2, font_size: int, weight := 800, color := Color("17345d")) -> Label:
	var label := _label(text, _benefit_metric(font_size), color)
	UiTypographyScript.apply(label, weight)
	label.name = node_name
	var final_rect := _benefit_rect(rect)
	label.position = final_rect.position
	label.size = final_rect.size
	_content.add_child(label)
	return label


func _benefit_rect(rect: Rect2) -> Rect2:
	return Rect2(
		(rect.position * BENEFITS_LAYOUT_SCALE).round(),
		(rect.size * BENEFITS_LAYOUT_SCALE).round()
	)


func _benefit_metric(value: int) -> int:
	return maxi(1, roundi(float(value) * BENEFITS_LAYOUT_SCALE))


func _refresh_benefits_purchase_button() -> void:
	if not is_instance_valid(_benefits_purchase_button):
		return
	var owned := service.is_benefits_bundle_owned()
	var product := service._product("benefits_bundle")
	var price := str(product.get("price", ""))
	_benefits_purchase_button.disabled = owned
	_benefits_purchase_button.modulate = Color(0.72, 0.76, 0.82, 0.92) if owned else Color.WHITE
	_benefits_purchase_button.tooltip_text = "已拥有" if owned else "权益包：%s" % price
	for child in _benefits_purchase_button.get_children():
		if child is Label:
			(child as Label).text = "已拥有" if owned else price
			break


func _build_first_purchase() -> void:
	if APPROVED_EFFECT_SHELLS:
		_title.text = ""
		_add_invisible_button(Rect2(99, 365, 263, 62), func(): _request_purchase("first_purchase"), not service.first_purchase_owned)
		return
	_title.text = "首充礼包"
	_title.add_theme_color_override("font_color", Color.WHITE)
	# The source shell already owns its ribbon and gift. Keep a single header
	# layer and place live text in the free left section of that ribbon.
	_place_title(Rect2(18, 4, 155, 58), 20)
	var limited := _label("首次购买限定", 16, Color("8a4a08"))
	limited.position = Vector2(126, 76)
	limited.size = Vector2(210, 30)
	_content.add_child(limited)
	var rewards := ["×980", "×30,000", "×10", "×10"]
	for index in range(rewards.size()):
		if index == 2:
			_add_icon(_content, FIRST_PURCHASE_ROOT + "decorations/reward_slot_purple.png", Rect2(239, 119, 76, 58))
		var reward := _label(rewards[index], 16, Color.WHITE)
		reward.position = Vector2(24 + index * 104, 145)
		reward.size = Vector2(94, 28)
		_content.add_child(reward)
	_add_icon(_content, "res://assets/runtime/ui/components/card_icons/atlas_regions/ascension_hammer.tres", Rect2(250, 121, 50, 50))
	_add_shell_button("已领取" if service.first_purchase_owned else "¥6", Rect2(99, 365, 263, 62), Callable() if service.first_purchase_owned else func(): _request_purchase("first_purchase"), Color.WHITE)


func _build_piggy() -> void:
	if APPROVED_EFFECT_SHELLS:
		_title.text = ""
		_add_invisible_button(Rect2(90, 397, 265, 62), func(): _request_purchase("piggy_bank") if service.piggy_coins > 0 else _show_notice("当前尚未积累"))
		return
	_title.text = "存钱罐"
	_title.add_theme_color_override("font_color", Color.WHITE)
	_place_title(Rect2(87, 5, 270, 58), 24)
	var text := _label("%d / 1000\n挑战可积累金币" % service.piggy_coins, 18, Color("17345d"))
	text.position = Vector2(70, 316)
	text.size = Vector2(305, 65)
	_content.add_child(text)
	_add_shell_button("¥12", Rect2(90, 397, 265, 62), func(): _request_purchase("piggy_bank") if service.piggy_coins > 0 else _show_notice("当前尚未积累"), Color.WHITE)


func _add_progress(rect: Rect2, ratio: float) -> void:
	var track := TextureRect.new()
	track.texture = load(COMMON + "progress_track.png")
	track.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	track.stretch_mode = TextureRect.STRETCH_SCALE
	track.position = rect.position
	track.size = rect.size
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(track)
	var clip := Control.new()
	clip.clip_contents = true
	clip.position = rect.position + Vector2(8, 10)
	clip.size = Vector2((rect.size.x - 16) * clampf(ratio, 0.0, 1.0), rect.size.y - 20)
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(clip)
	var fill := TextureRect.new()
	fill.texture = load(COMMON + "progress_fill.png")
	fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fill.stretch_mode = TextureRect.STRETCH_SCALE
	fill.size = Vector2(rect.size.x - 16, rect.size.y - 20)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(fill)


func _build_shop() -> void:
	if APPROVED_EFFECT_SHELLS:
		_title.text = ""
		var category_ids := ["recommended", "currency", "crystal", "imprint"]
		for index in range(4):
			var category_id: String = category_ids[index]
			_add_invisible_button(Rect2(17 + index * 109, 76, 104, 42), func(): _shop_category = category_id; _shop_page = 0; _refresh())
		var products := _shop_products()
		for index in range(mini(4, products.size())):
			var product_id := str((products[index] as Dictionary)["id"])
			_add_invisible_button(Rect2(14 + index * 109, 132, 103, 238), func(): _request_purchase(product_id))
		return
	_title.text = "商城"
	_title.add_theme_color_override("font_color", Color.WHITE)
	var categories := [["推荐", "recommended"], ["货币", "currency"], ["水晶卡", "crystal"], ["印记", "imprint"]]
	_place_title(Rect2(68, 5, 150, 52), 21)
	for index in range(categories.size()):
		var category: Array = categories[index]
		_add_shell_button(str(category[0]), Rect2(17 + index * 109, 76, 104, 42), func(): _shop_category = str(category[1]); _shop_page = 0; _refresh(), Color.WHITE if _shop_category == str(category[1]) else Color("17345d"), 13)
	var products := _shop_products()
	var start := _shop_page * 4
	for index in range(start, mini(start + 4, products.size())):
		var product: Dictionary = products[index]
		var local := index - start
		var rect := Rect2(14 + local * 109, 132, 103, 238)
		_build_shop_product(product, rect)
	if products.size() > 4:
		_add_button("上一页", Rect2(220, 775, 180, 70), func(): _shop_page = maxi(0, _shop_page - 1); _refresh(), "blue", _shop_page > 0)
		_add_button("下一页", Rect2(450, 775, 180, 70), func(): _shop_page = mini(ceili(products.size() / 4.0) - 1, _shop_page + 1); _refresh(), "blue", start + 4 < products.size())


func _shop_products() -> Array[Dictionary]:
	var currency: Array[Dictionary] = [
		{"id": "coins_10000", "name": "金币 ×10,000", "price": "水晶 200"}, {"id": "crystals_500", "name": "水晶 ×500", "price": "¥12"},
	]
	var crystal: Array[Dictionary] = []
	for row in [["fire_conduit", "炉心龙纹管", 120], ["poison_tank", "腐蚀炼金罐", 120], ["star_boiler", "星核蒸汽炉", 120], ["rapid_clockwork", "迅流发条机", 180], ["twin_lens", "双塔折射镜", 250], ["piercing_cannon", "城墙穿透炮", 250]]:
		crystal.append({"id": "frag_%s" % row[0], "name": "%s碎片 ×5" % row[1], "price": "水晶 %d" % row[2]})
	var imprint: Array[Dictionary] = []
	var names := ["星阶铸锤", "万象数盘", "命运魔箱", "双生晶模", "王城魔炮", "龙焰投石"]
	for index in range(MetaProgressService.IMPRINT_IDS.size()):
		imprint.append({"id": "frag_imprint_%s" % MetaProgressService.IMPRINT_IDS[index], "name": "%s碎片 ×5" % names[index], "price": "水晶 250"})
	match _shop_category:
		"currency": return currency
		"crystal": return crystal
		"imprint": return imprint
		_: return [currency[0], currency[1], crystal[0], imprint[0]]


func _build_shop_product(product: Dictionary, rect: Rect2) -> void:
	var product_id := str(product["id"])
	var state := _product_state(product_id)
	var slot := Control.new()
	slot.position = rect.position
	slot.size = rect.size
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(slot)
	var icon_path := _shop_icon_path(product_id)
	if not icon_path.is_empty():
		_add_icon(slot, icon_path, Rect2(14, 14, rect.size.x - 28, 96))
	var label := _label(str(product["name"]), 10, Color("17345d"))
	label.position = Vector2(4, 120)
	label.size = Vector2(rect.size.x - 8, 48)
	slot.add_child(label)
	var price := _label(str(product["price"]), 9, Color.WHITE)
	price.position = Vector2(5, 166)
	price.size = Vector2(rect.size.x - 10, 27)
	slot.add_child(price)
	_add_child_button(slot, str(state["text"]), Rect2(5, 198, 93, 29), func(): _request_purchase(product_id), bool(state["enabled"]), 11)
	_add_invisible_button(Rect2(rect.position, rect.size), func(): _request_purchase(product_id), bool(state["enabled"]))


func _add_state_caption(copy: String, rect: Rect2, color: Color) -> void:
	var caption := _label(copy, 12, color)
	caption.position = rect.position
	caption.size = rect.size
	_content.add_child(caption)


func _shop_icon_path(product_id: String) -> String:
	var file := "icon_imprint_chest.png"
	match product_id:
		"coins_10000": file = "icon_coin_bundle.png"
		"crystals_500": return SHOP_ROOT + "icons/shop_crystal.png"
		"frag_fire_conduit": return "res://assets/runtime/ui/components/card_icons/atlas_regions/fire_conduit.tres"
		"frag_poison_tank": return "res://assets/runtime/ui/components/card_icons/atlas_regions/poison_tank.tres"
		"frag_star_boiler": return "res://assets/runtime/ui/components/card_icons/atlas_regions/star_boiler.tres"
		"frag_rapid_clockwork": return "res://assets/runtime/ui/components/card_icons/atlas_regions/rapid_clockwork.tres"
		"frag_twin_lens": return "res://assets/runtime/ui/components/card_icons/atlas_regions/twin_lens.tres"
		"frag_piercing_cannon": return "res://assets/runtime/ui/components/card_icons/atlas_regions/piercing_cannon.tres"
		_:
			if product_id.contains("ascension_hammer"):
				file = "icon_star_hammer.png"
	return SHOP_ROOT + "icons/" + file


func _build_product_card(name: String, copy: String, product_id: String, rect: Rect2) -> void:
	var slot := Control.new()
	slot.position = rect.position
	slot.size = rect.size
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(slot)
	var name_label := _label(name, 14, Color("17345d"))
	name_label.position = Vector2(8, 153)
	name_label.size = Vector2(rect.size.x - 16, 28)
	slot.add_child(name_label)
	var copy_label := _label(copy, 10, Color("17345d"))
	copy_label.position = Vector2(10, 182)
	copy_label.size = Vector2(rect.size.x - 20, 48)
	slot.add_child(copy_label)
	var owned := service._is_owned(product_id)
	var price := str((MetaProgressService.PRODUCTS[product_id] as Dictionary).get("price", ""))
	_add_child_button(slot, "已拥有" if owned else price, Rect2(25, 207, rect.size.x - 50, 38), func(): _request_purchase(product_id), not owned, 13)


func _product_state(product_id: String) -> Dictionary:
	var product := service._product(product_id)
	if product.is_empty():
		return {"text": "缺货", "enabled": false}
	var limit := int(product.get("daily_limit", 0))
	if limit > 0 and int(service.daily_limits.get(product_id, 0)) >= limit:
		return {"text": "今日售罄", "enabled": false}
	if str(product.get("kind", "")) == "crystals" and service.crystals < int(product.get("cost", 0)):
		return {"text": "水晶不足", "enabled": false}
	return {"text": "购买", "enabled": true}


func _request_purchase(product_id: String) -> void:
	_pending_product_id = product_id
	_purchase_return_page = page_id
	open("purchase_confirm", source)


func _build_purchase_confirm() -> void:
	if _pending_product_id != "benefits_bundle":
		_build_generic_purchase_confirm()
		return
	# The benefits entry is a single local bundle. Its confirmation screen is
	# composed from the approved cutouts so both included benefits remain
	# explicit instead of falling back to a generic text-only dialog.
	_title_bar.visible = false
	_title.text = ""
	var dark_blue := Color("17345d")
	var title := _label("确认购买", 34, dark_blue)
	title.position = Vector2(42, 18)
	title.size = Vector2(434, 58)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypographyScript.apply_title_shadow(title)
	_content.add_child(title)
	_add_stretched_texture(_content, load(PURCHASE_CONFIRM_BACKPLATES + "purchase_divider_horizontal_v01.png"), Rect2(42, 78, 434, 19), "PurchaseDividerHorizontal")
	_add_stretched_texture(_content, load(PURCHASE_CONFIRM_BACKPLATES + "purchase_divider_vertical_v01.png"), Rect2(257, 106, 14, 240), "PurchaseDividerVertical")
	_add_icon(_content, PURCHASE_CONFIRM_ICONS + "purchase_icon_double_coin_base_v01.png", Rect2(67, 99, 158, 158)).name = "PurchaseDoubleCoinIcon"
	_add_icon(_content, PURCHASE_CONFIRM_ICONS + "purchase_icon_no_ad_base_v01.png", Rect2(293, 99, 158, 158)).name = "PurchaseNoAdIcon"
	_add_purchase_copy("双倍金币", Rect2(32, 247, 228, 38), 27)
	_add_purchase_copy("去广告", Rect2(258, 247, 228, 38), 27)
	_add_purchase_copy("结算金币 +100%", Rect2(28, 285, 236, 32), 17)
	_add_purchase_copy("移除非主动广告\n奖励广告保留", Rect2(270, 280, 220, 58), 16)
	_add_stretched_texture(_content, load(PURCHASE_CONFIRM_BACKPLATES + "purchase_status_tag_permanent_v01.png"), Rect2(174, 337, 170, 57), "PurchasePermanentStatus")
	_add_purchase_copy("永久生效", Rect2(174, 345, 170, 42), 22, Color("276b1e"))
	_add_purchase_copy("¥6", Rect2(174, 393, 170, 51), 36)
	_add_purchase_art_button("取消", PURCHASE_CONFIRM_BACKPLATES + "purchase_button_cancel_default_v01.png", Rect2(35, 456, 184, 79), func(): open(_purchase_return_page, source), "PurchaseCancelButton")
	_add_purchase_art_button("确认购买", PURCHASE_CONFIRM_BACKPLATES + "purchase_button_confirm_default_v01.png", Rect2(299, 456, 184, 79), func(): _purchase(_pending_product_id), "PurchaseConfirmButton")


func _build_generic_purchase_confirm() -> void:
	_title.text = "购买确认"
	var product := service._product(_pending_product_id)
	var price := str(product.get("price", "水晶 %d" % int(product.get("cost", 0))))
	var message := _label("确认购买该商品？\n%s" % price, 31, Color("17345d"))
	message.position = Vector2(55, 120)
	message.size = Vector2(550, 125)
	_content.add_child(message)
	_add_button("取消", Rect2(55, 285, 250, 92), func(): open(_purchase_return_page, source), "blue")
	_add_button("确认购买", Rect2(355, 285, 250, 92), func(): _purchase(_pending_product_id), "yellow")


func _add_purchase_copy(text: String, rect: Rect2, font_size: int, color := Color("17345d")) -> Label:
	var label := _label(text, font_size, color)
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_constant_override("line_spacing", -2)
	_content.add_child(label)
	return label


func _add_purchase_art_button(text: String, texture_path: String, rect: Rect2, callback: Callable, node_name: String) -> TextureButton:
	var button := TextureButton.new()
	button.name = node_name
	button.texture_normal = load(texture_path)
	button.texture_pressed = button.texture_normal
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	button.button_down.connect(func():
		button.pivot_offset = button.size * 0.5
		button.scale = Vector2(0.97, 0.97)
	)
	button.button_up.connect(func(): button.scale = Vector2.ONE)
	var label := _label(text, 25, Color.WHITE)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)
	_content.add_child(button)
	return button


func _purchase(product_id: String) -> void:
	var result := service.try_purchase(product_id)
	if bool(result.get("success", false)):
		wallet_changed.emit()
		if product_id == "first_purchase":
			_play_first_purchase_reward()
		else:
			open(_purchase_return_page, source)
			_show_notice("购买成功")
	else:
		var copy: String = str({"insufficient": "货币不足", "limit": "今日已达限购", "owned": "已经拥有", "empty": "当前尚未积累", "payment_failed": "购买失败"}.get(str(result.get("reason", "")), "暂时无法购买"))
		_show_notice(str(copy))


func _play_first_purchase_reward() -> void:
	_locked = true
	_clear_dynamic_content()
	_title.text = "奖励已获得"
	var reward_art := TextureRect.new()
	reward_art.texture = load(FIRST_PURCHASE_ROOT + "rewards/first_chest_open.png")
	reward_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reward_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reward_art.position = Vector2(245, 100)
	reward_art.size = Vector2(170, 150)
	reward_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(reward_art)
	var chest := _label("宝箱开启！\n\n水晶 ×980     金币 ×30,000\n星阶铸锤碎片 ×10     炉心龙纹管碎片 ×10", 29, Color("17345d"))
	chest.position = Vector2(55, 255)
	chest.size = Vector2(550, 210)
	chest.scale = Vector2(0.75, 0.75)
	chest.pivot_offset = chest.size * 0.5
	_content.add_child(chest)
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(chest, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.7)
	tween.tween_callback(func():
		_locked = false
		visible = false
		first_purchase_completed.emit()
	)


func _clear_dynamic_content() -> void:
	# TitleBar and Title are permanent controller chrome. They are referenced by
	# every later _refresh(), so page/reward cleanup must never queue them for
	# deletion. Keeping this rule in one helper prevents another modal path from
	# leaving a stale, previously-freed _title reference behind.
	if not is_instance_valid(_content):
		return
	for child in _content.get_children():
		if child == _title_bar or child == _title:
			continue
		if not child.is_queued_for_deletion():
			_content.remove_child(child)
			child.queue_free()


func _show_notice(copy: String) -> void:
	var notice := _label(copy, 29, Color.WHITE)
	notice.position = Vector2((_panel.size.x - 360) * 0.5, _panel.size.y - 115)
	notice.size = Vector2(360, 70)
	notice.modulate = Color(0.04, 0.13, 0.28, 0.94)
	notice.z_index = 50
	_panel.add_child(notice)
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_interval(0.8)
	tween.tween_property(notice, "modulate:a", 0.0, 0.2)
	tween.tween_callback(notice.queue_free)


func _open_settings() -> void:
	open("settings", "pause")


func _cancel_exit() -> void:
	open("pause", "battle")


func _confirm_exit() -> void:
	_locked = true
	exit_confirmed.emit()


func _cancel_clear() -> void:
	open("settings", source)


func _confirm_clear() -> void:
	_locked = true
	clear_data_confirmed.emit()


func _on_shade_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and (page_id == "pause" or source == "hub"):
		close()
	elif event is InputEventScreenTouch and event.pressed and (page_id == "pause" or source == "hub"):
		close()


func _row(rect: Rect2) -> NinePatchRect:
	var row := NinePatchRect.new()
	row.texture = load(COMMON + "row_light.png")
	row.patch_margin_left = 22
	row.patch_margin_top = 22
	row.patch_margin_right = 22
	row.patch_margin_bottom = 22
	row.position = rect.position
	row.size = rect.size
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(row)
	return row


func _image_panel(texture_path: String, rect: Rect2, margins: Vector4) -> NinePatchRect:
	var panel := NinePatchRect.new()
	panel.texture = load(texture_path)
	panel.patch_margin_left = int(margins.x)
	panel.patch_margin_top = int(margins.y)
	panel.patch_margin_right = int(margins.z)
	panel.patch_margin_bottom = int(margins.w)
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(panel)
	return panel


func _add_tab(text: String, rect: Rect2, selected: bool, callback: Callable) -> TextureButton:
	var button := TextureButton.new()
	button.texture_normal = load(COMMON + ("tab_selected.png" if selected else "tab_default.png"))
	button.texture_pressed = button.texture_normal
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	var label := _label(text, 29, Color.WHITE if selected else Color("17345d"))
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(label)
	_content.add_child(button)
	return button


func _add_button(text: String, rect: Rect2, callback: Callable, color := "blue", enabled := true, font_size := 31) -> TextureButton:
	var button := TextureButton.new()
	var normal_path := SHARED_BUTTONS + "button_%s_default.png" % color
	var pressed_path := SHARED_BUTTONS + "button_%s_pressed.png" % color
	button.texture_normal = load(normal_path)
	button.texture_pressed = load(pressed_path) if ResourceLoader.exists(pressed_path) else button.texture_normal
	button.texture_disabled = load(SHARED_BUTTONS + "button_gray_disabled.png")
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.position = rect.position
	button.size = rect.size
	button.disabled = not enabled
	button.modulate = Color.WHITE if enabled else Color(0.55, 0.60, 0.68, 0.8)
	button.focus_mode = Control.FOCUS_NONE
	if enabled:
		button.pressed.connect(callback)
		button.button_down.connect(func():
			button.pivot_offset = button.size * 0.5
			button.scale = Vector2(0.96, 0.96)
			button.modulate = Color(0.84, 0.88, 0.94)
		)
		button.button_up.connect(func():
			button.scale = Vector2.ONE
			button.modulate = Color.WHITE
		)
	var label := _label(text, font_size, Color.WHITE)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(label)
	_content.add_child(button)
	return button


func _add_pause_action(text: String, icon_path: String, rect: Rect2, callback: Callable, color: String) -> void:
	var button := TextureButton.new()
	button.texture_normal = load(ROOT + "pages/pause/action_tile_%s.png" % color)
	button.texture_pressed = button.texture_normal
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	var icon := TextureRect.new()
	icon.texture = load(icon_path)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = Vector2(58, 22)
	icon.size = Vector2(119, 119)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)
	var label := _label(text, 34, Color.WHITE)
	label.position = Vector2(15, 145)
	label.size = Vector2(rect.size.x - 30, 60)
	button.add_child(label)
	_content.add_child(button)


func _add_shell_action(text: String, icon_path: String, rect: Rect2, callback: Callable) -> void:
	var button := Button.new()
	button.flat = true
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	var label := _label(text, 34, Color.WHITE)
	label.position = Vector2(15, 145)
	label.size = Vector2(rect.size.x - 30, 60)
	button.add_child(label)
	_content.add_child(button)


func _place_title(rect: Rect2, font_size: int) -> void:
	_title.position = rect.position
	_title.size = rect.size
	_title.add_theme_font_size_override("font_size", font_size)


func _add_hit_label_button(text: String, hit_rect: Rect2, label_rect: Rect2, callback: Callable, font_size: int, color: Color, font_weight := 800) -> void:
	var button := Button.new()
	button.name = "%sButton" % text
	button.flat = true
	button.tooltip_text = text
	button.position = hit_rect.position
	button.size = hit_rect.size
	button.focus_mode = Control.FOCUS_NONE
	if callback.is_valid():
		button.pressed.connect(callback)
	else:
		button.disabled = true
	_content.add_child(button)
	var label := _label(text, font_size, color)
	label.name = "%sLabel" % text
	if font_weight != 800:
		UiTypographyScript.apply(label, font_weight)
	label.position = label_rect.position
	label.size = label_rect.size
	_content.add_child(label)


func _add_shell_button(text: String, rect: Rect2, callback: Callable, color: Color, font_size := 28) -> Button:
	var button := Button.new()
	button.flat = true
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", color)
	button.add_theme_color_override("font_pressed_color", color.darkened(0.12))
	button.add_theme_color_override("font_outline_color", Color(0.04, 0.08, 0.15, 0.72))
	button.add_theme_constant_override("outline_size", 3 if color == Color.WHITE else 0)
	if callback.is_valid():
		button.pressed.connect(callback)
	else:
		button.disabled = true
	_content.add_child(button)
	return button


func _add_icon(parent: Control, texture_path: String, rect: Rect2) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = load(texture_path)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.position = rect.position
	icon.size = rect.size
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)
	return icon


func _add_icon_button(texture_path: String, rect: Rect2, callback: Callable) -> TextureButton:
	var button := TextureButton.new()
	button.texture_normal = load(texture_path)
	button.texture_pressed = button.texture_normal
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	_content.add_child(button)
	return button


func _add_divider(position: Vector2, width: float) -> void:
	var divider := TextureRect.new()
	divider.texture = load(COMMON + "divider_diamond.png")
	divider.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	divider.stretch_mode = TextureRect.STRETCH_SCALE
	divider.position = position
	divider.size = Vector2(width, 18)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(divider)


func _add_invisible_button(rect: Rect2, callback: Callable, enabled := true) -> Button:
	var button := Button.new()
	button.flat = true
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.disabled = not enabled
	if enabled and callback.is_valid():
		button.pressed.connect(callback)
	_content.add_child(button)
	return button


func _add_child_button(parent: Control, text: String, rect: Rect2, callback: Callable, enabled: bool, font_size := 24) -> void:
	var button := Button.new()
	button.flat = true
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.disabled = not enabled
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color("17345d"))
	button.add_theme_color_override("font_hover_color", Color("17345d"))
	button.add_theme_color_override("font_pressed_color", Color("17345d"))
	button.add_theme_color_override("font_disabled_color", Color("53657e"))
	UiTypographyScript.apply(button, 800)
	if enabled:
		button.pressed.connect(callback)
	parent.add_child(button)


func _add_small_button(text: String, rect: Rect2, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(callback)
	_content.add_child(button)


func _label(text: String, font_size: int, color: Color, alignment := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.04, 0.08, 0.15, 0.7))
	label.add_theme_constant_override("outline_size", 2 if color == Color.WHITE else 0)
	UiTypographyScript.apply(label, 800)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
