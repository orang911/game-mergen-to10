@tool
extends Control
class_name MainHubView

signal stage_pressed(stage_number: int)
# Kept for MainGame API compatibility. The V2 art-only lobby never emits it.
signal settings_pressed
signal entry_pressed(entry_id: String)

const UiTypographyScript := preload("res://scripts/ui_typography.gd")
const CurrencyAssetsScript := preload("res://scripts/currency_assets.gd")
const DESIGN_SIZE := Vector2(941.0, 1672.0)
const INTRO_DURATION := 0.24
const FOREST_ANIMATION_IDLE_MIN := 5.0
const FOREST_ANIMATION_IDLE_MAX := 10.0
const ASSET_ROOT := "res://assets/runtime/ui/interfaces/main_hub/"
const STANDALONE_ROOT := ASSET_ROOT + "standalone/"
const FRAME_ROOT := ASSET_ROOT + "backplates/"
const HUB_ICON_ROOT := ASSET_ROOT + "icons/"
const ICON_ROOT := "res://assets/runtime/ui/shared/meta_icons/atlas_regions/"
const FOREST_ISLAND_LOOP: SpriteFrames = preload("res://assets/runtime/ui/interfaces/main_hub/animations/forest_island_loop_v01/forest_island_loop_v01.tres")
const FRAME_SOURCE_SCALES := {
	"lobby_settings_button_frame_default_v01.png": 0.7142857,
	"lobby_mission_panel_with_reward_slot_default_v01.png": 0.71875,
	"lobby_mission_panel_plain_default_v01.png": 0.71875,
	"lobby_progress_track_default_v01.png": 0.4444444,
	"lobby_progress_fill_green_v01.png": 0.3953488,
	"lobby_reward_slot_purple_default_v02.png": 0.51953125,
	"lobby_side_menu_button_frame_default_v01.png": 0.6833333,
	"lobby_primary_level_button_default_v01.png": 0.6761905,
	"lobby_bottom_navigation_background_v01.png": 1.0,
	"lobby_navigation_tab_selected_v01.png": 0.625,
}
const PACKED_ICON_DEPENDENCIES := [
	preload("res://assets/runtime/ui/shared/meta_icons/atlas_regions/lobby_badge_alert_v01.tres"),
	preload("res://assets/runtime/ui/shared/meta_icons/atlas_regions/lobby_icon_ad_tv_v01.tres"),
	preload("res://assets/runtime/ui/shared/meta_icons/atlas_regions/lobby_icon_battle_crystal_v01.tres"),
	preload("res://assets/runtime/ui/shared/meta_icons/atlas_regions/lobby_icon_double_coin_x2_v01.tres"),
	preload("res://assets/runtime/ui/shared/meta_icons/atlas_regions/lobby_icon_locked_v01.tres"),
	preload("res://assets/runtime/ui/shared/meta_icons/atlas_regions/lobby_icon_piggy_bank_v02.tres"),
	preload("res://assets/runtime/ui/shared/meta_icons/atlas_regions/lobby_icon_plus_v01.tres"),
	preload("res://assets/runtime/ui/shared/meta_icons/atlas_regions/lobby_icon_reward_star_wand_v01.tres"),
	preload("res://assets/runtime/ui/shared/meta_icons/atlas_regions/lobby_icon_settings_gear_v01.tres"),
	preload("res://assets/runtime/ui/shared/meta_icons/atlas_regions/lobby_icon_shop_v01.tres"),
	preload("res://assets/runtime/ui/shared/meta_icons/atlas_regions/lobby_icon_signin_calendar_v01.tres"),
	preload("res://assets/runtime/ui/shared/meta_icons/atlas_regions/lobby_icon_task_notebook_v01.tres"),
	preload("res://assets/runtime/ui/interfaces/main_hub/icons/lobby_icon_battle_portal_v02.png"),
]

var _design_root: Control
var _stage_button: Button
var _stage_label: Label
var _stage_subtitle: Label
var _crystal_value: Label
var _coin_value: Label
var _entry_buttons: Dictionary = {}
var _entry_alerts: Dictionary = {}
var _interactive := false
var _intro_tween: Tween
var _pending_crystals := 120
var _pending_coins := 1804
var _pending_stage_text := "开始游戏"
var _pending_progress_text := ""
var _forest_island: TextureRect
var _forest_animation_time := 0.0
var _forest_animation_frame := 0
var _forest_animation_wait_remaining := 0.0
var _locked_notice: Panel
var _locked_notice_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_design_root = get_node_or_null("DesignRoot") as Control
	_build_lobby_art()
	set_resource_values(_pending_crystals, _pending_coins)
	set_stage_entry(_pending_stage_text, _pending_progress_text)
	set_interactive(false)
	if size.x > 0.0 and size.y > 0.0:
		layout_for_viewport(size)


func _process(delta: float) -> void:
	if not visible or _forest_island == null:
		return
	var frame_count := FOREST_ISLAND_LOOP.get_frame_count(&"default")
	var frame_rate := FOREST_ISLAND_LOOP.get_animation_speed(&"default")
	if frame_count <= 1 or frame_rate <= 0.0:
		return
	if _forest_animation_wait_remaining > 0.0:
		_forest_animation_wait_remaining -= delta
		if _forest_animation_wait_remaining > 0.0:
			return
		# The supplied final frame is the calm pose. Hold it for the complete
		# random interval, then restart cleanly from frame one.
		_forest_animation_wait_remaining = 0.0
		_forest_animation_time = 0.0
		_forest_animation_frame = 0
		_forest_island.texture = FOREST_ISLAND_LOOP.get_frame_texture(&"default", 0)
		return
	_forest_animation_time += delta
	var next_frame := floori(_forest_animation_time * frame_rate)
	if next_frame >= frame_count:
		_forest_animation_time = float(frame_count) / frame_rate
		_forest_animation_frame = frame_count - 1
		_forest_island.texture = FOREST_ISLAND_LOOP.get_frame_texture(&"default", _forest_animation_frame)
		_forest_animation_wait_remaining = randf_range(FOREST_ANIMATION_IDLE_MIN, FOREST_ANIMATION_IDLE_MAX)
		return
	if next_frame == _forest_animation_frame:
		return
	_forest_animation_frame = next_frame
	_forest_island.texture = FOREST_ISLAND_LOOP.get_frame_texture(&"default", _forest_animation_frame)


func _build_lobby_art() -> void:
	if _design_root == null or _design_root.get_child_count() > 0:
		return
	_add_texture("Background", STANDALONE_ROOT + "lobby_background_clean_v01.png", Rect2(Vector2.ZERO, DESIGN_SIZE), _design_root, TextureRect.STRETCH_SCALE)
	_forest_island = _add_texture("ForestIsland", STANDALONE_ROOT + "lobby_forest_island_v01.png", Rect2(166, 563, 610, 606), _design_root)
	if FOREST_ISLAND_LOOP.get_frame_count(&"default") > 0:
		_forest_island.texture = FOREST_ISLAND_LOOP.get_frame_texture(&"default", 0)

	# Top-left settings is intentionally static in the art-only pass.
	_add_frame("SettingsFrame", "lobby_settings_button_frame_default_v01.png", Rect2(23, 25, 127, 121), Vector4(48, 48, 48, 48))
	_add_texture("SettingsIcon", _icon_path("lobby_icon_settings_gear_v01.png"), Rect2(34, 33, 104, 104), _design_root)
	_add_entry_button("settings", Rect2(23, 25, 127, 121), func(): settings_pressed.emit())

	# Shared currency art keeps one source file, while the lobby uses smaller
	# per-slot bounds so neither icon overwhelms the compact top counters.
	_build_currency_counter("Crystal", Vector2(205, 53), CurrencyAssetsScript.DIAMOND_PATH, Rect2(203, 40, 82, 89), _pending_crystals)
	_build_currency_counter("Coin", Vector2(454, 53), CurrencyAssetsScript.COIN_PATH, Rect2(450, 39, 86, 87), _pending_coins)

	# The plain frame is derived from the source panel without its baked reward
	# socket. The purple reward slot below is therefore the only visible plate.
	_add_frame("MissionPanel", "lobby_mission_panel_plain_default_v01.png", Rect2(178, 174, 604, 165), Vector4(64, 64, 64, 64))
	var mission_title := _add_label("MissionTitle", "完成 1 次挑战", Rect2(220, 198, 370, 57), 37)
	mission_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_add_frame("MissionProgressTrack", "lobby_progress_track_default_v01.png", Rect2(215, 265, 395, 48), Vector4(42, 30, 42, 30))
	var fill_clip := Control.new()
	fill_clip.name = "MissionProgressFillClip"
	fill_clip.clip_contents = true
	_set_rect(fill_clip, Vector2(208, 265), Vector2(402, 43))
	fill_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_design_root.add_child(fill_clip)
	var mission_fill := _add_frame("Fill", "lobby_progress_fill_green_v01.png", Rect2(6, 0, 390, 44), Vector4(40, 28, 40, 28), fill_clip)
	mission_fill.visible = false
	_add_label("MissionProgressText", "0/1", Rect2(219, 266, 387, 45), 27)
	_add_frame("MissionRewardSlot", "lobby_reward_slot_purple_default_v02.png", Rect2(624, 195, 135, 118), Vector4(70, 70, 70, 70))
	_add_texture("MissionRewardIcon", CurrencyAssetsScript.DIAMOND_PATH, Rect2(648, 206, 84, 84), _design_root)
	_add_label("MissionRewardCount", "10", Rect2(696, 259, 55, 43), 31)
	_add_entry_button("mission_tasks", Rect2(178, 174, 604, 165), func(): entry_pressed.emit("tasks"))

	# Text must be rendered at its authored font size. A non-uniform Control
	# scale makes the glyph outlines visibly taller and softer on phones.
	_add_label("LobbyTitle", "魔幻森林", Rect2(212, 402, 525, 101), 70, Color.WHITE, 10)

	_build_side_entry("TaskEntry", "tasks", Rect2(20, 469, 141, 191), "lobby_icon_task_notebook_v01.png", "任务", true)
	_build_side_entry("SigninEntry", "signin", Rect2(20, 695, 141, 191), "lobby_icon_signin_calendar_v01.png", "签到", true)
	_build_side_entry("DoubleCoinEntry", "double_coin", Rect2(20, 922, 141, 191), "lobby_icon_double_coin_x2_v01.png", "双倍金币", false)
	_build_side_entry("AdEntry", "remove_ads", Rect2(780, 469, 141, 191), "lobby_icon_ad_tv_v01.png", "去广告", false)
	# First purchase is disabled in the current release. Move piggy bank into its
	# former second-row slot so the right rail stays compact and aligned with the
	# left-side sign-in entry; keep the third-row right slot intentionally empty.
	_build_side_entry("PiggyEntry", "piggy", Rect2(780, 695, 141, 191), "lobby_icon_piggy_bank_v02.png", "存钱罐", false)

	_stage_button = Button.new()
	_stage_button.name = "StageButton"
	var stage_style := _make_frame_style("lobby_primary_level_button_default_v01.png", Vector4(58, 54, 58, 54))
	for state in ["normal", "hover", "pressed", "disabled"]:
		_stage_button.add_theme_stylebox_override(state, stage_style)
	_stage_button.text = ""
	_stage_button.focus_mode = Control.FOCUS_NONE
	_stage_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_set_rect(_stage_button, Vector2(258, 1179), Vector2(426, 162))
	_stage_button.pressed.connect(func():
		if _interactive:
			stage_pressed.emit(1)
	)
	_wire_button_feedback(_stage_button)
	_design_root.add_child(_stage_button)
	_stage_label = _make_label("开始游戏", 65, Color.WHITE, 7)
	_stage_label.name = "Label"
	_set_rect(_stage_label, Vector2.ZERO, _stage_button.size)
	_stage_button.add_child(_stage_label)
	_stage_subtitle = _make_label("", 20, Color(1.0, 0.96, 0.84, 1.0), 3, 800)
	_stage_subtitle.name = "ProgressLabel"
	_set_rect(_stage_subtitle, Vector2(0, 81), Vector2(_stage_button.size.x, 37))
	_stage_button.add_child(_stage_subtitle)

	# The dock deliberately continues far beyond the 1672px design viewport.
	# This makes the viewport cut through the solid centre of both NinePatches,
	# keeping their transparent padding, rounded corners and lower border offscreen.
	_add_frame("BottomNavigation", "lobby_bottom_navigation_background_v01.png", Rect2(-64, 1450, 1069, 402), Vector4(48, 36, 48, 36))
	_add_frame("BattleSelectedTab", "lobby_navigation_tab_selected_v01.png", Rect2(307, 1448, 327, 404), Vector4(64, 64, 64, 64))
	var shop_icon := _add_texture("ShopIcon", _icon_path("lobby_icon_shop_v01.png"), Rect2(75, 1474, 161, 161), _design_root)
	shop_icon.modulate = Color(0.48, 0.48, 0.52, 1.0)
	_add_label("ShopLabel", "未解锁", Rect2(64, 1603, 178, 67), 32, Color(0.66, 0.68, 0.74, 1.0))
	_add_entry_button("locked_shop", Rect2(32, 1450, 253, 222), _show_locked_notice)
	_add_texture("BattleIcon", HUB_ICON_ROOT + "lobby_icon_battle_portal_v02.png", Rect2(360, 1430, 222, 200), _design_root)
	_add_label("BattleLabel", "战斗", Rect2(375, 1584, 198, 70), 41)
	_add_texture("CrystalNavIcon", _icon_path("lobby_icon_battle_crystal_v01.png"), Rect2(708, 1477, 152, 152), _design_root)
	_add_label("CrystalNavLabel", "水晶", Rect2(684, 1601, 198, 67), 32)
	_add_entry_button("crystal_upgrade", Rect2(680, 1446, 240, 226), func(): entry_pressed.emit("crystal_upgrade"))


func _build_currency_counter(prefix: String, panel_position: Vector2, icon_path: String, icon_rect: Rect2, value: int) -> void:
	# This asset is a complete 241 x 61 counter, including its right add-button
	# socket. It must render at native aspect instead of being reconstructed as a
	# NinePatch, which visibly distorted both the border and socket.
	var panel_rect := Rect2(panel_position, CurrencyAssetsScript.HUB_COUNTER_PANEL_SIZE)
	_add_texture(prefix + "Counter", CurrencyAssetsScript.HUB_COUNTER_PANEL_PATH, panel_rect, _design_root, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	# Currency cutouts were authored to the final top-bar silhouettes. Scale them
	# to the measured reference rectangles instead of adding letterbox padding.
	_add_texture(prefix + "Icon", icon_path, icon_rect, _design_root, TextureRect.STRETCH_SCALE)
	var value_label := _add_label(prefix + "Value", str(value), Rect2(panel_rect.position + Vector2(68, 2), Vector2(panel_rect.size.x - 112, panel_rect.size.y - 4)), 31)
	_add_texture(prefix + "Plus", _icon_path("lobby_icon_plus_v01.png"), Rect2(panel_rect.end - Vector2(58, 59), Vector2(57, 57)), _design_root)
	if prefix == "Crystal":
		_crystal_value = value_label
	else:
		_coin_value = value_label


func _build_side_entry(node_name: String, entry_id: String, rect: Rect2, icon_file: String, label_text: String, alert: bool, icon_rect := Rect2(3, 11, 135, 135)) -> void:
	var root := Control.new()
	root.name = node_name
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(root, rect.position, rect.size)
	_design_root.add_child(root)
	_add_frame("Frame", "lobby_side_menu_button_frame_default_v01.png", Rect2(-10, -7, 161, 205), Vector4(54, 54, 54, 54), root)
	var icon_path := icon_file if icon_file.begins_with("res://") else _icon_path(icon_file)
	_add_texture("Icon", icon_path, icon_rect, root)
	var label := _make_label(label_text, 33 if label_text.length() <= 3 else 27, Color.WHITE, 6)
	label.name = "Label"
	_set_rect(label, Vector2(-6, 122), Vector2(rect.size.x + 12, 56))
	root.add_child(label)
	if alert:
		_entry_alerts[entry_id] = _add_texture("Alert", _icon_path("lobby_badge_alert_v01.png"), Rect2(90, -24, 74, 74), root)
	_add_entry_button(entry_id, rect, func(): entry_pressed.emit(entry_id))


func _add_entry_button(entry_id: String, rect: Rect2, callback: Callable) -> void:
	var button := Button.new()
	button.name = entry_id.to_pascal_case() + "Button"
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.position = rect.position
	button.size = rect.size
	button.pressed.connect(func():
		if _interactive:
			callback.call()
	)
	_design_root.add_child(button)
	_entry_buttons[entry_id] = button


func set_entry_visible(entry_id: String, entry_visible: bool) -> void:
	var button := _entry_buttons.get(entry_id) as Control
	if button:
		button.visible = entry_visible


func set_entry_alert(entry_id: String, alert_visible: bool) -> void:
	var alert := _entry_alerts.get(entry_id) as Control
	if alert:
		alert.visible = alert_visible


func set_task_summary(task_state: Dictionary) -> void:
	var title := _design_root.get_node_or_null("MissionTitle") as Label
	var progress := _design_root.get_node_or_null("MissionProgressText") as Label
	var fill := _design_root.get_node_or_null("MissionProgressFillClip/Fill") as Control
	var reward_slot := _design_root.get_node_or_null("MissionRewardSlot") as Control
	var reward_icon := _design_root.get_node_or_null("MissionRewardIcon") as TextureRect
	var reward_count := _design_root.get_node_or_null("MissionRewardCount") as Label
	if task_state.is_empty():
		if title:
			title.text = "今日任务已完成"
		if progress:
			progress.text = "4/4"
		if fill:
			fill.visible = true
			fill.size.x = 390.0
		if reward_slot:
			reward_slot.visible = false
		if reward_icon:
			reward_icon.visible = false
		if reward_count:
			reward_count.visible = false
		return
	var current := int(task_state.get("progress", 0))
	var target := maxi(1, int(task_state.get("target", 1)))
	if title:
		title.text = str(task_state.get("title", ""))
	if progress:
		progress.text = "%d/%d" % [current, target]
	if fill:
		fill.visible = current > 0
		fill.size.x = 390.0 * clampf(float(current) / float(target), 0.0, 1.0)
	if reward_slot:
		reward_slot.visible = true
	var reward := task_state.get("reward", {}) as Dictionary
	var reward_kind := "crystals" if reward.has("crystals") else "coins"
	if reward_icon:
		reward_icon.visible = true
		reward_icon.texture = _load_texture(CurrencyAssetsScript.DIAMOND_PATH if reward_kind == "crystals" else CurrencyAssetsScript.COIN_PATH)
	if reward_count:
		reward_count.visible = true
		reward_count.text = str(int(reward.get(reward_kind, 0)))


func layout_for_viewport(viewport_size: Vector2) -> void:
	if _design_root == null or viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var scale_factor := minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	_design_root.position = (viewport_size - DESIGN_SIZE * scale_factor) * 0.5
	_design_root.size = DESIGN_SIZE
	_design_root.scale = Vector2.ONE * scale_factor


func show_menu() -> void:
	visible = true
	set_interactive(true)
	if _intro_tween and _intro_tween.is_valid():
		_intro_tween.kill()
	_design_root.modulate.a = 0.0
	_intro_tween = create_tween()
	_intro_tween.tween_property(_design_root, "modulate:a", 1.0, INTRO_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func hide_menu() -> void:
	if _intro_tween and _intro_tween.is_valid():
		_intro_tween.kill()
	_intro_tween = null
	_clear_locked_notice()
	set_interactive(false)
	visible = false


func _show_locked_notice() -> void:
	_clear_locked_notice()
	_locked_notice = Panel.new()
	_locked_notice.name = "LockedNotice"
	_locked_notice.position = Vector2(190, 785)
	_locked_notice.size = Vector2(561, 102)
	_locked_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_locked_notice.z_index = 200
	_locked_notice.modulate.a = 0.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.10, 0.24, 0.94)
	style.border_color = Color(0.34, 0.68, 1.0, 0.96)
	style.set_border_width_all(4)
	style.set_corner_radius_all(24)
	style.shadow_color = Color(0.0, 0.02, 0.08, 0.55)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 5)
	_locked_notice.add_theme_stylebox_override("panel", style)
	_design_root.add_child(_locked_notice)
	var copy := _make_label("未解锁，敬请期待", 38, Color.WHITE, 5)
	copy.name = "Copy"
	copy.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_locked_notice.add_child(copy)
	_locked_notice_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_locked_notice_tween.tween_property(_locked_notice, "modulate:a", 1.0, 0.12)
	_locked_notice_tween.tween_interval(1.20)
	_locked_notice_tween.tween_property(_locked_notice, "modulate:a", 0.0, 0.22)
	_locked_notice_tween.tween_callback(_clear_locked_notice)


func _clear_locked_notice() -> void:
	if _locked_notice_tween and _locked_notice_tween.is_valid():
		_locked_notice_tween.kill()
	_locked_notice_tween = null
	if is_instance_valid(_locked_notice):
		_locked_notice.queue_free()
	_locked_notice = null


func set_interactive(enabled: bool) -> void:
	_interactive = enabled
	if _stage_button:
		_stage_button.disabled = not enabled
		_stage_button.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	for value in _entry_buttons.values():
		var button := value as BaseButton
		if button:
			button.disabled = not enabled


func set_resource_values(crystals: int, coins: int) -> void:
	_pending_crystals = maxi(0, crystals)
	_pending_coins = maxi(0, coins)
	if _crystal_value:
		_crystal_value.text = _format_resource_value(_pending_crystals)
	if _coin_value:
		_coin_value.text = _format_resource_value(_pending_coins)


func set_stage_entry(primary_text: String, progress_text: String = "") -> void:
	_pending_stage_text = primary_text
	_pending_progress_text = progress_text
	if _stage_label:
		_stage_label.text = primary_text
		if progress_text.is_empty():
			_stage_label.position = Vector2.ZERO
			_stage_label.size = _stage_button.size
			_stage_label.add_theme_font_size_override("font_size", 65)
			_stage_label.add_theme_constant_override("outline_size", 7)
		else:
			_stage_label.position = Vector2(0, 4)
			_stage_label.size = Vector2(_stage_button.size.x, 65)
			_stage_label.add_theme_font_size_override("font_size", 43)
			_stage_label.add_theme_constant_override("outline_size", 5)
	if _stage_subtitle:
		_stage_subtitle.text = progress_text
		_stage_subtitle.visible = not progress_text.is_empty()
		_stage_subtitle.position = Vector2(0, 70)
		_stage_subtitle.size = Vector2(_stage_button.size.x, 54)
		_stage_subtitle.add_theme_font_size_override("font_size", 38)
		_stage_subtitle.add_theme_constant_override("outline_size", 4)


func set_muted(_muted: bool) -> void:
	# Settings remains a non-interactive visual during the art assembly pass.
	pass


func _add_frame(node_name: String, file_name: String, rect: Rect2, margins: Vector4, parent: Control = null) -> NinePatchRect:
	var node := NinePatchRect.new()
	node.name = node_name
	node.texture = _load_texture(FRAME_ROOT + file_name)
	node.draw_center = true
	# Production margins are recorded against the original HD cutouts. The
	# mobile frame sources were uniformly downscaled first, so apply the same
	# factor to the source split coordinates and stretch only the safe centre.
	var margin_scale := float(FRAME_SOURCE_SCALES.get(file_name, 1.0))
	node.patch_margin_left = roundi(margins.x * margin_scale)
	node.patch_margin_top = roundi(margins.y * margin_scale)
	node.patch_margin_right = roundi(margins.z * margin_scale)
	node.patch_margin_bottom = roundi(margins.w * margin_scale)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(node, rect.position, rect.size)
	(parent if parent else _design_root).add_child(node)
	return node


func _make_frame_style(file_name: String, margins: Vector4) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = _load_texture(FRAME_ROOT + file_name)
	var margin_scale := float(FRAME_SOURCE_SCALES.get(file_name, 1.0))
	style.texture_margin_left = roundi(margins.x * margin_scale)
	style.texture_margin_top = roundi(margins.y * margin_scale)
	style.texture_margin_right = roundi(margins.z * margin_scale)
	style.texture_margin_bottom = roundi(margins.w * margin_scale)
	return style


func _format_resource_value(value: int) -> String:
	# Keep ordinary balances exact; compact six-digit counters so they remain in
	# the art-approved text safe area instead of colliding with the plus icon.
	if value >= 100_000:
		return "%dK" % roundi(float(value) / 1000.0)
	return str(value)


func _add_texture(node_name: String, path: String, rect: Rect2, parent: Control, stretch: TextureRect.StretchMode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED) -> TextureRect:
	var node := TextureRect.new()
	node.name = node_name
	node.texture = _load_texture(path)
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = stretch
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(node, rect.position, rect.size)
	parent.add_child(node)
	return node


func _add_label(node_name: String, text: String, rect: Rect2, font_size: int, color: Color = Color.WHITE, outline_size: int = 6) -> Label:
	var node := _make_label(text, font_size, color, outline_size)
	node.name = node_name
	_set_rect(node, rect.position, rect.size)
	_design_root.add_child(node)
	return node


func _make_label(text: String, font_size: int, color: Color, outline_size: int, weight: int = 900) -> Label:
	var node := Label.new()
	node.text = text
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_outline_color", Color(0.025, 0.045, 0.09, 1.0))
	node.add_theme_constant_override("outline_size", outline_size)
	UiTypographyScript.apply(node, weight)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


func _load_texture(path: String) -> Texture2D:
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


func _icon_path(file_name: String) -> String:
	return ICON_ROOT + file_name.get_basename() + ".tres"


func _set_rect(node: Control, position: Vector2, node_size: Vector2) -> void:
	node.position = position
	node.size = node_size
	node.pivot_offset = node_size * 0.5


func _wire_button_feedback(button: BaseButton) -> void:
	button.button_down.connect(func():
		var tween := create_tween()
		tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.06)
	)
	button.button_up.connect(func():
		var tween := create_tween()
		tween.tween_property(button, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)


func _exit_tree() -> void:
	if _intro_tween and _intro_tween.is_valid():
		_intro_tween.kill()
	if _locked_notice_tween and _locked_notice_tween.is_valid():
		_locked_notice_tween.kill()
