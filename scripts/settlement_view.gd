extends Control
class_name SettlementView

signal retry_pressed
signal revive_pressed
signal home_pressed

const DESIGN_SIZE := Vector2(941.0, 1672.0)
const ASSET_DIR := "res://assets/runtime/ui/screens/settlement/"

const PANEL_TEXTURE := preload(ASSET_DIR + "settlement_panel.png")
const WIN_TITLE := preload(ASSET_DIR + "title_victory.png")
const LOSE_TITLE := preload(ASSET_DIR + "title_defeat.png")
const RECORD_TEXTURE := preload(ASSET_DIR + "badge_new_record.png")
const REWARD_PANEL := preload(ASSET_DIR + "reward_panel.png")
const REWARD_CHEST := preload(ASSET_DIR + "reward_chest.png")
const REWARD_COIN := preload(ASSET_DIR + "reward_coin.png")
const REWARD_CRYSTAL := preload(ASSET_DIR + "reward_crystal.png")

const TAB_STATS := preload(ASSET_DIR + "tab_stats_active.png")
const TAB_DECK := preload(ASSET_DIR + "tab_deck_inactive.png")
const MAIN_HIGHEST := preload(ASSET_DIR + "main_highest_frame.png")
const MAIN_KILLS := preload(ASSET_DIR + "main_kills_frame.png")
const SUMMARY_FRAME := preload(ASSET_DIR + "summary_frame.png")
const SECONDARY_LEFT := preload(ASSET_DIR + "secondary_left_frame.png")
const SECONDARY_RIGHT := preload(ASSET_DIR + "secondary_right_frame.png")
const DAMAGE_FRAME := preload(ASSET_DIR + "damage_frame.png")
const DAMAGE_ROW := preload(ASSET_DIR + "damage_row.png")

const ICON_HIGHEST := preload(ASSET_DIR + "icon_highest_number.png")
const ICON_KILLS := preload(ASSET_DIR + "icon_kills.png")
const ICON_MERGES := preload(ASSET_DIR + "icon_merges.png")
const ICON_MAX_MERGE := preload(ASSET_DIR + "icon_max_merge.png")
const ICON_CASTLE := preload(ASSET_DIR + "icon_castle_health.png")
const ICON_LEAKS := preload(ASSET_DIR + "icon_leaks.png")
const ICON_BOARD_DAMAGE := preload(ASSET_DIR + "icon_board_damage.png")
const ICON_CRYSTAL_DAMAGE := preload(ASSET_DIR + "icon_crystal_damage.png")
const ICON_SKILL_DAMAGE := preload(ASSET_DIR + "icon_skill_damage.png")
const STAR_ACTIVE_TEXTURE := preload("res://assets/runtime/ui/cards/stars/star_active.png")
const STAR_SLOT_TEXTURE := preload("res://assets/runtime/ui/cards/stars/star_slot.png")

const PAGE_STATS := "stats"
const PAGE_DECK := "deck"
const DECK_CARD_SIZE := Vector2(165.0, 322.0)

var _won := false
var _stats: Dictionary = {}
var _content: Control
var _page_content: Control
var _stats_tab_art: TextureRect
var _deck_tab_art: TextureRect
var _stats_tab_label: Label
var _deck_tab_label: Label
var _active_page := PAGE_STATS


func setup(won: bool, stats: Dictionary) -> void:
	_won = won
	_stats = stats.duplicate(true)
	process_mode = Node.PROCESS_MODE_ALWAYS
	position = Vector2.ZERO
	size = DESIGN_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	_play_intro()


func _build() -> void:
	var shade := ColorRect.new()
	shade.name = "SettlementShade"
	shade.color = Color(0.015, 0.02, 0.04, 0.78)
	shade.size = DESIGN_SIZE
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	_content = Control.new()
	_content.name = "SettlementContent"
	_content.size = DESIGN_SIZE
	_content.pivot_offset = DESIGN_SIZE * 0.5
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)

	# Both result states share the full-height panel because rewards and the
	# run-deck page remain available after a defeat as well.
	_add_texture(_content, "SettlementPanel", PANEL_TEXTURE, Vector2(53.0, 80.0), Vector2(835.0, 1512.0))
	_add_texture(_content, "ResultTitle", WIN_TITLE if _won else LOSE_TITLE, Vector2(220.0, 82.0), Vector2(500.0, 195.0))

	_page_content = Control.new()
	_page_content.name = "PageContent"
	_page_content.size = DESIGN_SIZE
	_page_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_page_content)

	_build_tabs(286.0)
	_build_action_buttons()
	_switch_page(PAGE_STATS)


func _build_stats_page() -> void:
	_build_reward(Vector2(110.0, 370.0))
	_add_main_stat(Vector2(112.0, 731.0), MAIN_HIGHEST, ICON_HIGHEST, "最高数字", str(_stats.get("highest", 0)))
	_add_main_stat(Vector2(480.0, 731.0), MAIN_KILLS, ICON_KILLS, "击杀怪物", _format_number(int(_stats.get("kills", 0))))
	_build_summary(Vector2(116.0, 983.0), false)
	_add_secondary_stat(Vector2(116.0, 1112.0), SECONDARY_LEFT, ICON_MERGES, "合成次数", str(_stats.get("merges", 0)), 0.92)
	_add_secondary_stat(Vector2(486.0, 1112.0), SECONDARY_RIGHT, ICON_MAX_MERGE, "最大单次合成", str(_stats.get("max_merge", 0)), 0.92)
	_add_secondary_stat(Vector2(116.0, 1205.0), SECONDARY_LEFT, ICON_CASTLE, "城堡耐久", "%d/%d" % [int(_stats.get("castle", 0)), int(_stats.get("castle_max", 20))], 0.92)
	_add_secondary_stat(Vector2(486.0, 1205.0), SECONDARY_RIGHT, ICON_LEAKS, "漏怪", str(_stats.get("leaks", 0)), 0.92)
	_build_damage(Vector2(116.0, 1300.0), 0.66)


func _build_action_buttons() -> void:
	if _won:
		_add_action_button("再次挑战", Rect2(154.0, 1460.0, 282.0, 80.0), Color(0.16, 0.52, 0.98), func(): retry_pressed.emit())
		_add_action_button("返回主页", Rect2(504.0, 1460.0, 282.0, 80.0), Color(0.42, 0.46, 0.66), func(): home_pressed.emit())
	else:
		_add_action_button("复活", Rect2(130.0, 1460.0, 220.0, 80.0), Color(0.16, 0.52, 0.98), func(): revive_pressed.emit())
		_add_action_button("重新开始", Rect2(365.0, 1460.0, 220.0, 80.0), Color(0.42, 0.46, 0.66), func(): retry_pressed.emit())
		_add_action_button("返回主页", Rect2(600.0, 1460.0, 210.0, 80.0), Color(0.42, 0.46, 0.66), func(): home_pressed.emit())


func _build_tabs(top: float) -> void:
	_stats_tab_art = _add_texture(_content, "StatsTab", TAB_STATS, Vector2(110.0, top), Vector2(360.0, 92.0))
	_deck_tab_art = _add_texture(_content, "DeckTab", TAB_DECK, Vector2(471.0, top), Vector2(360.0, 92.0))
	_stats_tab_label = _add_label(_content, "本局战绩", Rect2(110.0, top + 2.0, 360.0, 84.0), 35, Color.WHITE, 3)
	_deck_tab_label = _add_label(_content, "本局卡组", Rect2(471.0, top + 2.0, 360.0, 84.0), 35, Color(0.96, 0.97, 1.0), 3)
	_add_tab_button("StatsTabButton", Rect2(110.0, top, 360.0, 92.0), func(): _switch_page(PAGE_STATS))
	_add_tab_button("DeckTabButton", Rect2(471.0, top, 360.0, 92.0), func(): _switch_page(PAGE_DECK))


func _add_tab_button(node_name: String, rect: Rect2, action: Callable) -> void:
	var button := Button.new()
	button.name = node_name
	button.flat = true
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_set_rect(button, rect.position, rect.size)
	button.pressed.connect(action)
	_content.add_child(button)


func _switch_page(page: String) -> void:
	_active_page = page
	_stats_tab_art.texture = TAB_STATS if page == PAGE_STATS else TAB_DECK
	_deck_tab_art.texture = TAB_STATS if page == PAGE_DECK else TAB_DECK
	_stats_tab_label.add_theme_color_override("font_color", Color.WHITE if page == PAGE_STATS else Color(0.82, 0.84, 0.93))
	_deck_tab_label.add_theme_color_override("font_color", Color.WHITE if page == PAGE_DECK else Color(0.82, 0.84, 0.93))
	for child in _page_content.get_children():
		_page_content.remove_child(child)
		child.queue_free()
	if page == PAGE_DECK:
		_build_deck_page()
	else:
		_build_stats_page()


func _build_deck_page() -> void:
	var cards_value: Variant = _stats.get("cards", [])
	var cards: Array = cards_value if cards_value is Array else []
	if cards.is_empty():
		_add_label(_page_content, "本局尚未获得卡牌", Rect2(120.0, 650.0, 700.0, 120.0), 36, Color(0.32, 0.38, 0.57), 0)
		return

	var scroll := ScrollContainer.new()
	scroll.name = "RunDeckScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_set_rect(scroll, Vector2(108.0, 390.0), Vector2(725.0, 1025.0))
	_page_content.add_child(scroll)

	var grid := GridContainer.new()
	grid.name = "RunDeckGrid"
	grid.columns = 4
	grid.custom_minimum_size = Vector2(700.0, 0.0)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 18)
	scroll.add_child(grid)
	for card_value in cards:
		if card_value is Dictionary:
			grid.add_child(_make_deck_card(card_value as Dictionary))


func _make_deck_card(card_info: Dictionary) -> Control:
	var card_id := str(card_info.get("id", ""))
	var level := clampi(int(card_info.get("level", 1)), 1, GameConfig.MAX_CARD_LEVEL)
	var selections := maxi(1, int(card_info.get("selections", 1)))
	var definition := CardCatalog.get_definition(card_id)
	var accent: Color = GameConfig.CARD_QUALITY_COLORS.get(level, Color(0.30, 0.67, 1.0))

	var tile := Control.new()
	tile.name = "RunCard_%s" % card_id
	tile.custom_minimum_size = DECK_CARD_SIZE
	tile.size = DECK_CARD_SIZE
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel := Panel.new()
	panel.name = "CardPanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _deck_card_style(accent))
	tile.add_child(panel)

	var header := ColorRect.new()
	header.name = "QualityHeader"
	header.color = accent
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(header, Vector2(5.0, 5.0), Vector2(155.0, 14.0))
	tile.add_child(header)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = load(str(definition.get("icon", ""))) as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(icon, Vector2(13.0, 29.0), Vector2(139.0, 133.0))
	tile.add_child(icon)

	var item_name := str(definition.get("item_name", card_id))
	_add_label(tile, item_name, Rect2(8.0, 165.0, 149.0, 48.0), 22 if item_name.length() <= 5 else 18, Color(0.16, 0.23, 0.42), 0)
	for i in range(GameConfig.MAX_CARD_LEVEL):
		var star := TextureRect.new()
		star.name = "Star_%d" % (i + 1)
		star.texture = STAR_ACTIVE_TEXTURE if i < level else STAR_SLOT_TEXTURE
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_rect(star, Vector2(15.0 + float(i) * 28.0, 218.0), Vector2(24.0, 24.0))
		tile.add_child(star)

	var separator := ColorRect.new()
	separator.color = Color(0.67, 0.71, 0.82, 0.65)
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(separator, Vector2(14.0, 258.0), Vector2(137.0, 2.0))
	tile.add_child(separator)
	_add_label(tile, "选择%d次" % selections, Rect2(7.0, 267.0, 151.0, 43.0), 21, Color(0.22, 0.29, 0.50), 0)
	return tile


func _deck_card_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.94, 0.95, 0.99, 0.98)
	style.border_color = accent.darkened(0.18)
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0.08, 0.10, 0.20, 0.34)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0.0, 4.0)
	return style


func _build_reward(pos: Vector2) -> void:
	_add_texture(_page_content, "RewardPanel", REWARD_PANEL, pos, Vector2(720.0, 350.0))
	_add_label(_page_content, "◆  本局奖励  ◆", Rect2(pos + Vector2(0.0, 18.0), Vector2(720.0, 58.0)), 34, Color(0.55, 0.25, 0.045), 1)
	_add_texture(_page_content, "RewardChest", REWARD_CHEST, pos + Vector2(269.0, 74.0), Vector2(182.0, 130.0))
	_add_texture(_page_content, "RewardCoin", REWARD_COIN, pos + Vector2(92.0, 225.0), Vector2(68.0, 68.0))
	_add_texture(_page_content, "RewardCrystal", REWARD_CRYSTAL, pos + Vector2(430.0, 220.0), Vector2(60.0, 75.0))
	_add_label(_page_content, _format_number(int(_stats.get("reward_coins", 0))), Rect2(pos + Vector2(160.0, 216.0), Vector2(220.0, 88.0)), 53, Color(0.56, 0.25, 0.035), 2)
	_add_label(_page_content, str(_stats.get("reward_crystals", 0)), Rect2(pos + Vector2(490.0, 216.0), Vector2(160.0, 88.0)), 53, Color(0.56, 0.25, 0.035), 2)
	if bool(_stats.get("new_record", false)):
		_add_texture(_page_content, "NewRecord", RECORD_TEXTURE, pos + Vector2(560.0, 50.0), Vector2(122.5, 57.5))


func _build_summary(pos: Vector2, show_history: bool) -> void:
	_add_texture(_page_content, "SummaryFrame", SUMMARY_FRAME, pos, Vector2(700.0, 126.0))
	var values := [
		"%d/%d" % [int(_stats.get("waves", 0)), int(_stats.get("wave_total", 0))],
		_format_time(float(_stats.get("elapsed", 0.0))),
		_format_number(int(_stats.get("score", 0))),
	]
	var captions := ["波次", "游戏时长", "本局分数"]
	for i in range(3):
		_add_label(_page_content, values[i], Rect2(pos + Vector2(float(i) * 233.0, 8.0), Vector2(234.0, 55.0)), 38, Color(0.16, 0.22, 0.39), 0)
		_add_label(_page_content, captions[i], Rect2(pos + Vector2(float(i) * 233.0, 62.0), Vector2(234.0, 42.0)), 21, Color(0.28, 0.34, 0.50), 0)
	if show_history:
		_add_label(_page_content, "历史最高   %s" % _format_number(int(_stats.get("best", 0))), Rect2(pos + Vector2(0.0, 122.0), Vector2(700.0, 60.0)), 27, Color(0.18, 0.23, 0.39), 0)


func _add_main_stat(pos: Vector2, frame: Texture2D, icon: Texture2D, title: String, value: String) -> void:
	_add_texture(_page_content, title + "Frame", frame, pos, Vector2(330.0, 252.0))
	_add_texture(_page_content, title + "Icon", icon, pos + Vector2(28.0, 72.0), Vector2(105.0, 105.0))
	_add_label(_page_content, title, Rect2(pos + Vector2(125.0, 20.0), Vector2(190.0, 52.0)), 27, Color(0.20, 0.27, 0.48), 0)
	_add_label(_page_content, value, Rect2(pos + Vector2(126.0, 74.0), Vector2(190.0, 120.0)), 65, Color(0.16, 0.25, 0.49), 0)


func _add_secondary_stat(pos: Vector2, frame: Texture2D, icon: Texture2D, title: String, value: String, height_scale: float = 1.0) -> void:
	var box_size := Vector2(330.0, 98.0 * height_scale)
	var expanded := height_scale > 1.01
	_add_texture(_page_content, title + "Frame", frame, pos, box_size, expanded)
	var icon_size := 69.0 * (1.24 if expanded else 1.0)
	var icon_top := (box_size.y - icon_size) * 0.5
	_add_texture(_page_content, title + "Icon", icon, pos + Vector2(14.0, icon_top), Vector2(icon_size, icon_size))
	var text_left := 106.0 if expanded else 91.0
	var title_height := 50.0 if expanded else 38.0
	_add_label(_page_content, title, Rect2(pos + Vector2(text_left, 8.0), Vector2(205.0, title_height)), 26 if expanded else 21, Color(0.20, 0.27, 0.45), 0, HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(_page_content, value, Rect2(pos + Vector2(text_left, 48.0 if expanded else 39.0), Vector2(205.0, 68.0 if expanded else 49.0)), 44 if expanded else 34, Color(0.18, 0.25, 0.43), 0, HORIZONTAL_ALIGNMENT_LEFT)


func _build_damage(pos: Vector2, display_scale: float) -> void:
	# Keep the result detail panel aligned with the 700 px summary area. Only
	# compress its height to fit above the action buttons; uniformly scaling it
	# made the entire block narrow and left-aligned.
	var size := Vector2(700.0, 238.0 * display_scale)
	_add_texture(_page_content, "DamageFrame", DAMAGE_FRAME, pos, size, true)
	_add_label(_page_content, "◆  伤害构成  ◆", Rect2(pos, Vector2(size.x, 42.0 * display_scale)), int(28.0 * display_scale), Color(0.20, 0.27, 0.45), 0)
	var entries := [
		{"name": "棋盘合成", "icon": ICON_BOARD_DAMAGE, "value": int(_stats.get("board_damage", 0)), "color": Color(0.48, 0.76, 0.14)},
		{"name": "水晶塔", "icon": ICON_CRYSTAL_DAMAGE, "value": int(_stats.get("crystal_damage", 0)), "color": Color(0.05, 0.72, 0.92)},
		{"name": "道具技能", "icon": ICON_SKILL_DAMAGE, "value": int(_stats.get("skill_damage", 0)), "color": Color(1.0, 0.57, 0.04)},
	]
	var total := 0
	for entry in entries:
		total += int(entry["value"])
	for i in range(entries.size()):
		var entry: Dictionary = entries[i]
		var row_pos := pos + Vector2(0.0, (48.0 + float(i) * 60.0) * display_scale)
		var row_size := Vector2(700.0, 58.0 * display_scale)
		_add_texture(_page_content, "DamageRow%d" % i, DAMAGE_ROW, row_pos, row_size, true)
		_add_texture(_page_content, "DamageIcon%d" % i, entry["icon"] as Texture2D, row_pos + Vector2(16.0, 5.0 * display_scale), Vector2(48.0, 48.0) * display_scale)
		_add_label(_page_content, str(entry["name"]), Rect2(row_pos + Vector2(70.0, 0.0), Vector2(130.0, 58.0 * display_scale)), int(22.0 * display_scale), Color(0.20, 0.27, 0.43), 0, HORIZONTAL_ALIGNMENT_LEFT)
		var ratio := float(entry["value"]) / float(total) if total > 0 else 0.0
		_add_bar(row_pos + Vector2(205.0, 18.0 * display_scale), Vector2(280.0, 22.0 * display_scale), ratio, entry["color"] as Color)
		_add_label(_page_content, _format_number(int(entry["value"])), Rect2(row_pos + Vector2(490.0, 0.0), Vector2(120.0, 58.0 * display_scale)), int(22.0 * display_scale), Color(0.20, 0.27, 0.43), 0)
		_add_label(_page_content, "%d%%" % roundi(ratio * 100.0), Rect2(row_pos + Vector2(608.0, 0.0), Vector2(82.0, 58.0 * display_scale)), int(22.0 * display_scale), entry["color"] as Color, 0)


func _add_bar(pos: Vector2, bar_size: Vector2, ratio: float, color: Color) -> void:
	var track := Panel.new()
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var track_style := StyleBoxFlat.new()
	track_style.bg_color = Color(0.64, 0.68, 0.82, 0.75)
	track_style.corner_radius_top_left = 8
	track_style.corner_radius_top_right = 8
	track_style.corner_radius_bottom_left = 8
	track_style.corner_radius_bottom_right = 8
	track.add_theme_stylebox_override("panel", track_style)
	_set_rect(track, pos, bar_size)
	_page_content.add_child(track)
	var fill := ColorRect.new()
	fill.color = color
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.position = Vector2(2.0, 2.0)
	fill.size = Vector2(maxf(0.0, (bar_size.x - 4.0) * clampf(ratio, 0.0, 1.0)), maxf(0.0, bar_size.y - 4.0))
	track.add_child(fill)


func _add_action_button(text_value: String, rect: Rect2, base_color: Color, action: Callable) -> void:
	var button := Button.new()
	button.text = text_value
	button.focus_mode = Control.FOCUS_NONE
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.add_theme_font_size_override("font_size", 31)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_outline_color", Color(0.08, 0.10, 0.18, 0.95))
	button.add_theme_constant_override("outline_size", 3)
	button.add_theme_stylebox_override("normal", _button_style(base_color, 0.0))
	button.add_theme_stylebox_override("hover", _button_style(base_color.lightened(0.10), 2.0))
	button.add_theme_stylebox_override("pressed", _button_style(base_color.darkened(0.12), 0.0))
	_set_rect(button, rect.position, rect.size)
	button.pressed.connect(action)
	_content.add_child(button)


func _button_style(color: Color, expand: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = color.lightened(0.34)
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0.06, 0.08, 0.18, 0.7)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0.0, 4.0)
	style.expand_margin_left = expand
	style.expand_margin_top = expand
	style.expand_margin_right = expand
	style.expand_margin_bottom = expand
	return style


func _add_texture(parent: Node, node_name: String, texture: Texture2D, pos: Vector2, node_size: Vector2, fill_rect: bool = false) -> TextureRect:
	var node := TextureRect.new()
	node.name = node_name
	node.texture = texture
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_SCALE if fill_rect else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(node, pos, node_size)
	parent.add_child(node)
	return node


func _add_label(parent: Node, value: String, rect: Rect2, font_size: int, color: Color, outline: int, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", maxi(12, font_size))
	label.add_theme_color_override("font_color", color)
	if outline > 0:
		label.add_theme_color_override("font_outline_color", Color(0.035, 0.05, 0.10, 0.95))
		label.add_theme_constant_override("outline_size", outline)
	_set_rect(label, rect.position, rect.size)
	parent.add_child(label)
	return label


func _set_rect(node: Control, pos: Vector2, node_size: Vector2) -> void:
	node.position = pos
	node.size = node_size
	node.pivot_offset = node_size * 0.5


func _play_intro() -> void:
	_content.modulate.a = 0.0
	_content.scale = Vector2(0.94, 0.94)
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.parallel().tween_property(_content, "modulate:a", 1.0, 0.18)
	tween.parallel().tween_property(_content, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _format_time(seconds_value: float) -> String:
	var seconds := maxi(0, floori(seconds_value))
	return "%02d:%02d" % [seconds / 60, seconds % 60]


func _format_number(value: int) -> String:
	var source := str(maxi(0, value))
	var result := ""
	for i in range(source.length()):
		if i > 0 and (source.length() - i) % 3 == 0:
			result += ","
		result += source[i]
	return result
