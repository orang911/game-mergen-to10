extends Control

const DESIGN_SIZE := Vector2i(941, 1672)
const HUB_SCENE := preload("res://scenes/ui/main_hub.tscn")
const LOADING_SCENE := preload("res://scenes/ui/loading_view.tscn")
const BATTLE_SCENE := preload("res://scenes/combat/battle_layer.tscn")
const IMPRINT_SCENE := preload("res://scenes/ui/imprint_choice_modal_v2.tscn")
const CRYSTAL_SCENE := preload("res://scenes/ui/crystal_card_choice_modal_v2.tscn")
const NODE_COMPLETE_SCENE := preload("res://scenes/ui/chapter_node_complete_modal.tscn")
const MAX_LEVEL_SUCCESS_SCRIPT := preload("res://scripts/max_level_success_view.gd")
const MERGE_BLOCK_SCRIPT := preload("res://scripts/block.gd")
const ENERGY_HUD_SCRIPT := preload("res://scripts/energy_hud.gd")
const MONSTER_VIEW_SCENE := preload("res://scenes/combat/monster_view.tscn")
const BATTLE_BACKGROUND_TEXTURE := preload("res://assets/runtime/ui/interfaces/battle/standalone/battle_background.png")
const BOARD_BACKDROP_TEXTURE := preload("res://assets/runtime/ui/interfaces/battle/board/standalone/battle_board_backdrop.png")

const PAGE_SPECS := [
	{"id": "loading", "group": "启动与大厅", "title": "Loading 启动页", "kind": "loading", "source": "scenes/ui/loading_view.tscn"},
	{"id": "hub_new", "group": "启动与大厅", "title": "大厅 / 新用户", "kind": "hub", "state": "new", "source": "scenes/ui/main_hub.tscn"},
	{"id": "hub_continue", "group": "启动与大厅", "title": "大厅 / 继续挑战", "kind": "hub", "state": "continue", "source": "scenes/ui/main_hub.tscn"},

	{"id": "battle", "group": "战斗与教学", "title": "战斗主界面", "kind": "battle", "source": "scenes/combat/battle_layer.tscn"},
	{"id": "tutorial_merge", "group": "战斗与教学", "title": "新手 / 首次合成", "kind": "tutorial", "state": "merge", "source": "scripts/first_wave_tutorial_view.gd"},
	{"id": "tutorial_core", "group": "战斗与教学", "title": "新手 / 唤醒晶核", "kind": "tutorial", "state": "core", "source": "scripts/first_wave_tutorial_view.gd"},

	{"id": "pause", "group": "二级界面", "title": "战斗暂停", "kind": "secondary", "page": "pause", "base": "battle", "source": "scripts/secondary_ui_controller.gd"},
	{"id": "exit_confirm", "group": "二级界面", "title": "退出确认", "kind": "secondary", "page": "exit_confirm", "base": "battle", "source": "scripts/secondary_ui_controller.gd"},
	{"id": "settings", "group": "二级界面", "title": "设置", "kind": "secondary", "page": "settings", "base": "hub", "source": "scripts/secondary_ui_controller.gd"},
	{"id": "clear_confirm", "group": "二级界面", "title": "清空数据确认", "kind": "secondary", "page": "clear_confirm", "base": "hub", "source": "scripts/secondary_ui_controller.gd"},
	{"id": "daily_tasks", "group": "二级界面", "title": "日常 / 任务", "kind": "secondary", "page": "daily", "tab": "tasks", "base": "hub", "source": "scripts/secondary_ui_controller.gd"},
	{"id": "daily_signin", "group": "二级界面", "title": "日常 / 签到", "kind": "secondary", "page": "daily", "tab": "signin", "base": "hub", "source": "scripts/secondary_ui_controller.gd"},
	{"id": "benefits", "group": "二级界面", "title": "权益 / 未购买", "kind": "secondary", "page": "benefits", "base": "hub", "source": "scripts/secondary_ui_controller.gd"},
	{"id": "benefits_owned", "group": "二级界面", "title": "权益 / 已拥有", "kind": "secondary", "page": "benefits", "state": "owned", "base": "hub", "source": "scripts/secondary_ui_controller.gd"},
	{"id": "first_purchase", "group": "二级界面", "title": "首充礼包", "kind": "secondary", "page": "first_purchase", "base": "hub", "source": "scripts/secondary_ui_controller.gd"},
	{"id": "piggy_progress", "group": "二级界面", "title": "存钱罐 / 积累中", "kind": "secondary", "page": "piggy", "state": "progress", "base": "hub", "source": "scripts/secondary_ui_controller.gd"},
	{"id": "piggy_full", "group": "二级界面", "title": "存钱罐 / 已满", "kind": "secondary", "page": "piggy", "state": "full", "base": "hub", "source": "scripts/secondary_ui_controller.gd"},
	{"id": "shop", "group": "二级界面", "title": "商城 / 默认", "kind": "secondary", "page": "shop", "base": "hub", "source": "scripts/secondary_ui_controller.gd"},
	{"id": "shop_insufficient", "group": "二级界面", "title": "商城 / 货币不足", "kind": "secondary", "page": "shop", "state": "insufficient", "base": "hub", "source": "scripts/secondary_ui_controller.gd"},
	{"id": "purchase_confirm", "group": "二级界面", "title": "商城 / 购买确认", "kind": "secondary", "page": "purchase_confirm", "base": "hub", "source": "scripts/secondary_ui_controller.gd"},

	{"id": "imprint", "group": "卡牌与印记", "title": "道具印记 / 未选择", "kind": "imprint", "source": "scenes/ui/imprint_choice_modal_v2.tscn"},
	{"id": "imprint_selected", "group": "卡牌与印记", "title": "道具印记 / 已选择", "kind": "imprint", "state": "selected", "source": "scenes/ui/imprint_choice_modal_v2.tscn"},
	{"id": "crystal_choice", "group": "卡牌与印记", "title": "水晶强化 / 未选择", "kind": "crystal", "source": "scenes/ui/crystal_card_choice_modal_v2.tscn"},
	{"id": "crystal_selected", "group": "卡牌与印记", "title": "水晶强化 / 已选择", "kind": "crystal", "state": "selected", "source": "scenes/ui/crystal_card_choice_modal_v2.tscn"},

	{"id": "node_complete", "group": "完成与结算", "title": "节点完成 / 1-2", "kind": "node_complete", "source": "scenes/ui/chapter_node_complete_modal.tscn"},
	{"id": "chapter_complete", "group": "完成与结算", "title": "第一章完成", "kind": "chapter_complete", "source": "scenes/ui/chapter_node_complete_modal.tscn"},
	{"id": "max_level_success", "group": "完成与结算", "title": "最高数字 / 合成恭喜", "kind": "max_level_success", "source": "scripts/max_level_success_view.gd"},
	{"id": "settlement_win", "group": "完成与结算", "title": "战斗结算 / 胜利", "kind": "settlement", "state": "win", "source": "scripts/settlement_view.gd"},
	{"id": "settlement_lose", "group": "完成与结算", "title": "战斗结算 / 失败", "kind": "settlement", "state": "lose", "source": "scripts/settlement_view.gd"},
]

var _overview_scroll: ScrollContainer
var _overview_grid: GridContainer
var _focus_box: VBoxContainer
var _focus_viewport: SubViewport
var _focus_title: Label
var _focus_source: Label
var _center_guides_enabled := false
var _safe_guides_enabled := false
var _current_page_id := ""
var _overview_viewports: Array[SubViewport] = []
var _overview_built := false
var _overview_building := false
var _status_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	# The game itself is portrait, while the audit workspace needs room for a
	# navigation rail and four live page previews. This applies only when this
	# dedicated scene is run directly and never changes the production project.
	if DisplayServer.get_name() != "headless":
		get_window().size = Vector2i(1600, 960)
	_build_review_shell()
	_build_navigation()
	show_overview()
	call_deferred("_build_overview_async")


func get_registered_page_ids() -> Array[String]:
	var ids: Array[String] = []
	for spec in PAGE_SPECS:
		ids.append(str(spec["id"]))
	return ids


func show_overview() -> void:
	_current_page_id = ""
	_overview_scroll.visible = true
	_focus_box.visible = false
	if _focus_viewport:
		_focus_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_status_label.text = "总览模式 · %d 个正式运行状态" % PAGE_SPECS.size()


func show_page(page_id: String) -> bool:
	var spec := _find_spec(page_id)
	if spec.is_empty():
		return false
	_current_page_id = page_id
	_overview_scroll.visible = false
	_focus_box.visible = true
	_focus_title.text = str(spec.get("title", page_id))
	_focus_source.text = "正式引用：res://%s" % str(spec.get("source", ""))
	_status_label.text = "单页审核 · %s" % page_id
	_spawn_page(spec, _focus_viewport, true)
	return true


func refresh_current_page() -> void:
	if _current_page_id.is_empty():
		_rebuild_overview()
	else:
		show_page(_current_page_id)


func _build_review_shell() -> void:
	var background := ColorRect.new()
	background.color = Color("101827")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("separation", 10)
	outer.offset_left = 14.0
	outer.offset_top = 12.0
	outer.offset_right = -14.0
	outer.offset_bottom = -12.0
	add_child(outer)

	var toolbar := HBoxContainer.new()
	toolbar.custom_minimum_size.y = 54.0
	toolbar.add_theme_constant_override("separation", 10)
	outer.add_child(toolbar)
	var heading := _make_label("全局 UI 审核中心", 27, Color.WHITE)
	heading.custom_minimum_size.x = 260.0
	toolbar.add_child(heading)
	var overview_button := _make_button("全部界面")
	overview_button.pressed.connect(show_overview)
	toolbar.add_child(overview_button)
	var refresh_button := _make_button("刷新正式引用")
	refresh_button.pressed.connect(refresh_current_page)
	toolbar.add_child(refresh_button)
	var center_toggle := CheckButton.new()
	center_toggle.text = "中心线"
	center_toggle.add_theme_font_size_override("font_size", 18)
	center_toggle.toggled.connect(func(enabled: bool):
		_center_guides_enabled = enabled
		_refresh_focus_guides()
	)
	toolbar.add_child(center_toggle)
	var safe_toggle := CheckButton.new()
	safe_toggle.text = "安全区"
	safe_toggle.add_theme_font_size_override("font_size", 18)
	safe_toggle.toggled.connect(func(enabled: bool):
		_safe_guides_enabled = enabled
		_refresh_focus_guides()
	)
	toolbar.add_child(safe_toggle)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(spacer)
	_status_label = _make_label("", 17, Color("9db7d8"))
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_status_label.custom_minimum_size.x = 340.0
	toolbar.add_child(_status_label)

	var body := HSplitContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.split_offset = 270
	outer.add_child(body)

	var sidebar_panel := PanelContainer.new()
	sidebar_panel.custom_minimum_size.x = 260.0
	sidebar_panel.add_theme_stylebox_override("panel", _flat_style(Color("16243a"), Color("2c466c"), 1, 12))
	body.add_child(sidebar_panel)
	var sidebar_margin := MarginContainer.new()
	_set_margins(sidebar_margin, 10)
	sidebar_panel.add_child(sidebar_margin)
	var sidebar_scroll := ScrollContainer.new()
	sidebar_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sidebar_margin.add_child(sidebar_scroll)
	var sidebar_list := VBoxContainer.new()
	sidebar_list.name = "PageList"
	sidebar_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sidebar_list.add_theme_constant_override("separation", 5)
	sidebar_scroll.add_child(sidebar_list)

	var content_panel := PanelContainer.new()
	content_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_panel.add_theme_stylebox_override("panel", _flat_style(Color("0b1220"), Color("30496d"), 1, 12))
	body.add_child(content_panel)
	var content_margin := MarginContainer.new()
	_set_margins(content_margin, 12)
	content_panel.add_child(content_margin)
	var content_stack := Control.new()
	content_stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_margin.add_child(content_stack)

	_overview_scroll = ScrollContainer.new()
	_overview_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overview_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_stack.add_child(_overview_scroll)
	_overview_grid = GridContainer.new()
	_overview_grid.columns = 4
	_overview_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_overview_grid.add_theme_constant_override("h_separation", 12)
	_overview_grid.add_theme_constant_override("v_separation", 12)
	_overview_scroll.add_child(_overview_grid)

	_focus_box = VBoxContainer.new()
	_focus_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_focus_box.add_theme_constant_override("separation", 4)
	content_stack.add_child(_focus_box)
	_focus_title = _make_label("", 25, Color.WHITE)
	_focus_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_focus_box.add_child(_focus_title)
	_focus_source = _make_label("", 15, Color("91a9c8"))
	_focus_source.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_focus_box.add_child(_focus_source)
	var focus_center := CenterContainer.new()
	focus_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	focus_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_focus_box.add_child(focus_center)
	var focus_container := TextureRect.new()
	focus_container.custom_minimum_size = Vector2(405, 720)
	focus_container.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	focus_container.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	focus_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_center.add_child(focus_container)
	_focus_viewport = _make_viewport()
	focus_container.add_child(_focus_viewport)
	focus_container.texture = _focus_viewport.get_texture()


func _build_navigation() -> void:
	var sidebar_list := find_child("PageList", true, false) as VBoxContainer
	var current_group := ""
	for spec in PAGE_SPECS:
		var group_name := str(spec.get("group", "其他"))
		if group_name != current_group:
			current_group = group_name
			var group_label := _make_label(group_name, 18, Color("72b7ff"))
			group_label.custom_minimum_size.y = 34.0
			sidebar_list.add_child(group_label)
		var button := _make_button(str(spec.get("title", spec["id"])), 16)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.tooltip_text = "res://%s" % str(spec.get("source", ""))
		button.pressed.connect(show_page.bind(str(spec["id"])))
		sidebar_list.add_child(button)


func _build_overview_async() -> void:
	if _overview_built or _overview_building:
		return
	_overview_building = true
	var index := 0
	for spec in PAGE_SPECS:
		_create_overview_card(spec)
		index += 1
		if index % 3 == 0:
			await get_tree().process_frame
	await get_tree().process_frame
	# Twenty-eight live previews can make runtime intro tweens advance only a
	# fraction of a frame on slower editor machines. Snap those purely visual
	# intros to their completed state before freezing the thumbnails.
	_finish_review_tweens()
	await get_tree().process_frame
	_finish_review_tweens(true)
	for viewport in _overview_viewports:
		if is_instance_valid(viewport):
			viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
			viewport.process_mode = Node.PROCESS_MODE_DISABLED
	_overview_building = false
	_overview_built = true
	_status_label.text = "总览模式 · %d 个正式运行状态" % PAGE_SPECS.size()


func _create_overview_card(spec: Dictionary) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(248, 500)
	card.add_theme_stylebox_override("panel", _flat_style(Color("142237"), Color("35527a"), 1, 9))
	_overview_grid.add_child(card)
	var margin := MarginContainer.new()
	_set_margins(margin, 8)
	card.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	margin.add_child(column)
	var title := _make_label(str(spec.get("title", spec["id"])), 17, Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size.y = 30.0
	column.add_child(title)
	var preview_container := TextureRect.new()
	preview_container.custom_minimum_size = Vector2(220, 391)
	preview_container.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_container.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(preview_container)
	var viewport := _make_viewport()
	preview_container.add_child(viewport)
	preview_container.texture = viewport.get_texture()
	_overview_viewports.append(viewport)
	_spawn_page(spec, viewport, false)
	var path_label := _make_label(str(spec.get("source", "")), 12, Color("879bb8"))
	path_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	path_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	path_label.tooltip_text = "res://%s" % str(spec.get("source", ""))
	column.add_child(path_label)
	var open_button := _make_button("打开单页审核", 15)
	open_button.pressed.connect(show_page.bind(str(spec["id"])))
	column.add_child(open_button)


func _rebuild_overview() -> void:
	for child in _overview_grid.get_children():
		child.free()
	_overview_viewports.clear()
	_overview_built = false
	_overview_building = false
	call_deferred("_build_overview_async")


func _make_viewport() -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = DESIGN_SIZE
	viewport.process_mode = Node.PROCESS_MODE_ALWAYS
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	viewport.gui_disable_input = true
	return viewport


func _spawn_page(spec: Dictionary, viewport: SubViewport, include_guides: bool) -> void:
	for child in viewport.get_children():
		child.free()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.process_mode = Node.PROCESS_MODE_ALWAYS
	_create_review_layers(viewport)
	var kind := str(spec.get("kind", ""))
	match kind:
		"loading":
			_add_loading(viewport)
		"hub":
			_add_hub(viewport, str(spec.get("state", "new")))
		"battle":
			_add_battle(viewport)
		"tutorial":
			_add_tutorial(viewport, str(spec.get("state", "merge")))
		"secondary":
			_add_secondary(viewport, spec)
		"imprint":
			_add_imprint(viewport, str(spec.get("state", "")) == "selected")
		"crystal":
			_add_crystal_choice(viewport, str(spec.get("state", "")) == "selected")
		"node_complete":
			_add_node_complete(viewport, false)
		"chapter_complete":
			_add_node_complete(viewport, true)
		"max_level_success":
			_add_max_level_success(viewport)
		"settlement":
			_add_settlement(viewport, str(spec.get("state", "win")) == "win")
	if include_guides:
		_add_focus_guides(viewport)
	get_tree().paused = false
	call_deferred("_settle_page_preview", viewport)


func _settle_page_preview(viewport: SubViewport) -> void:
	# The audit workspace is a static visual inspector. Runtime modal intros are
	# still created by the formal scenes, then advanced to completion so no page
	# is reviewed halfway through a fade, flip or staggered card entrance.
	await get_tree().process_frame
	if not is_instance_valid(viewport):
		return
	_finish_review_tweens(true)
	_settle_imprint_modal(viewport)
	_settle_crystal_modal(viewport)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	if is_instance_valid(viewport) and viewport == _focus_viewport:
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS


func _settle_imprint_modal(viewport: SubViewport) -> void:
	var modal := viewport.get_node_or_null("ReviewOverlayLayer/ImprintChoiceModalV2") as ImprintChoiceModalV2
	if modal == null:
		return
	modal._mask.color = ImprintChoiceModalV2.MASK_COLOR
	modal._content_root.modulate = Color.WHITE
	modal._input_locked = false
	for entry in modal._slot_views:
		var root := entry["root"] as Control
		root.modulate = Color.WHITE
		root.position = entry["base_position"]
		root.scale = Vector2.ONE
	modal._refresh_selection_state(false)
	modal.process_mode = Node.PROCESS_MODE_DISABLED


func _settle_crystal_modal(viewport: SubViewport) -> void:
	var modal := viewport.get_node_or_null("ReviewOverlayLayer/CrystalCardChoiceModalV2") as CrystalCardChoiceModalV2
	if modal == null:
		return
	modal._mask.color = CrystalCardChoiceModalV2.MASK_COLOR
	modal._content_root.modulate = Color.WHITE
	modal._locked = false
	for index in range(modal._cards.size()):
		var card := modal._cards[index] as CrystalChoiceCardViewV2
		var selected := index == modal._selected_index
		card._back.visible = false
		card._front.visible = true
		card._revealed = true
		card._inner.scale = card._fit_scale
		card.position = modal._base_card_positions[index] + (Vector2(0.0, -11.0) if selected else Vector2.ZERO)
		card.scale = Vector2(1.045, 1.045) if selected else Vector2(0.96, 0.96) if modal._selected_index >= 0 else Vector2.ONE
		card.modulate = Color.WHITE if selected or modal._selected_index < 0 else Color(1.0, 1.0, 1.0, 0.82)
		card.z_index = 4 if selected else 0
		card.set_interactable(true)
		modal._selection_frames[index].visible = selected
	modal._set_confirm_enabled(modal._selected_index >= 0)
	modal.process_mode = Node.PROCESS_MODE_DISABLED


func _finish_review_tweens(kill_after_step: bool = false) -> void:
	for tween in get_tree().get_processed_tweens():
		if tween != null and tween.is_valid():
			tween.custom_step(4.0)
			if kill_after_step and tween.is_valid():
				tween.kill()


func _create_review_layers(viewport: SubViewport) -> void:
	var base_layer := Control.new()
	base_layer.name = "ReviewBaseLayer"
	base_layer.size = Vector2(DESIGN_SIZE)
	base_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base_layer.z_as_relative = false
	base_layer.z_index = 0
	viewport.add_child(base_layer)

	# Runtime battle decorations use absolute z values. Keeping every modal under
	# a separate absolute parent mirrors MainGame's popup/card layers and prevents
	# paths, gates or HUD children from drawing over an audit-page modal.
	var overlay_layer := Control.new()
	overlay_layer.name = "ReviewOverlayLayer"
	overlay_layer.size = Vector2(DESIGN_SIZE)
	overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_layer.z_as_relative = false
	overlay_layer.z_index = 500
	viewport.add_child(overlay_layer)


func _review_base(viewport: SubViewport) -> Control:
	return viewport.get_node("ReviewBaseLayer") as Control


func _review_overlay(viewport: SubViewport) -> Control:
	return viewport.get_node("ReviewOverlayLayer") as Control


func _add_loading(viewport: SubViewport) -> void:
	var loading := LOADING_SCENE.instantiate() as LoadingView
	_review_base(viewport).add_child(loading)
	loading.stop_animations()
	loading._update_progress(72.0)


func _add_hub(viewport: SubViewport, state: String = "continue") -> MainHubView:
	var hub := HUB_SCENE.instantiate() as MainHubView
	_review_base(viewport).add_child(hub)
	hub.set_resource_values(1160, 31884)
	hub.set_daily_activity(80)
	if state == "new":
		hub.set_stage_entry("开始游戏")
	else:
		hub.set_stage_entry("继续挑战", "1-1")
	hub.show_menu()
	return hub


func _add_battle(viewport: SubViewport) -> BattleLayerView:
	var base_layer := _review_base(viewport)
	_add_battle_background(base_layer)
	_add_review_board(base_layer)
	var battle := BATTLE_SCENE.instantiate() as BattleLayerView
	base_layer.add_child(battle)
	battle._show_editor_preview()
	battle.set_wave_text("1-4")
	battle.set_wave_progress(3, 7)
	battle.set_coin_value(1804)
	battle.set_elapsed_seconds(127.0)
	_add_review_monsters(base_layer)
	_add_review_energy_hud(base_layer)
	return battle


func _add_battle_background(parent: Control) -> void:
	var background := TextureRect.new()
	background.name = "BattleBackground"
	background.size = Vector2(DESIGN_SIZE)
	background.texture = BATTLE_BACKGROUND_TEXTURE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_as_relative = false
	background.z_index = -20
	parent.add_child(background)


func _add_review_board(parent: Control) -> void:
	var backdrop := TextureRect.new()
	backdrop.name = "BoardBackdrop"
	backdrop.position = GameConfig.get_board_plate_position(GameConfig.BOARD_GRID_POS)
	backdrop.size = GameConfig.get_board_backdrop_size()
	backdrop.texture = BOARD_BACKDROP_TEXTURE
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.z_as_relative = false
	backdrop.z_index = 6
	parent.add_child(backdrop)

	var board := Control.new()
	board.name = "ReviewBoard"
	board.position = GameConfig.BOARD_GRID_POS
	board.size = GameConfig.get_board_size()
	board.pivot_offset = Vector2(board.size.x * 0.5, board.size.y)
	board.scale = Vector2.ONE * GameConfig.BOARD_CONTENT_SCALE
	board.clip_contents = true
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.z_as_relative = false
	board.z_index = 8
	parent.add_child(board)

	var backgrounds: Dictionary = {}
	for color_name in GameConfig.BLOCK_BG_PATHS:
		backgrounds[color_name] = load(GameConfig.BLOCK_BG_PATHS[color_name]) as Texture2D
	var levels := [
		[3, 2, 1, 1, 2],
		[3, 1, 4, 4, 1],
		[2, 3, 2, 5, 3],
		[1, 4, 4, 3, 4],
		[3, 2, 1, 3, 3],
	]
	for row in range(GameConfig.GRID_SIZE):
		for column in range(GameConfig.GRID_SIZE):
			var block := MERGE_BLOCK_SCRIPT.new() as MergeBlock
			block.name = "Block_%d_%d" % [column, row]
			board.add_child(block)
			block.setup(int(levels[row][column]), backgrounds)
			block.position = GameConfig.get_block_position_for_site(Vector2i(column, GameConfig.GRID_SIZE - 1 - row))


func _add_review_monsters(parent: Control) -> void:
	var previews := [
		{"position": Vector2(300, 292), "appearance_id": "slime", "visual_tier": 1, "scale": 0.76},
		{"position": Vector2(420, 292), "appearance_id": "slime", "visual_tier": 2, "scale": 0.76},
		{"position": Vector2(738, 443), "appearance_id": "goblin", "visual_tier": 2, "scale": 0.82},
	]
	for index in range(previews.size()):
		var entry: Dictionary = previews[index]
		var monster := MONSTER_VIEW_SCENE.instantiate() as MonsterView
		monster.name = "ReviewMonster%d" % (index + 1)
		monster.z_as_relative = false
		monster.z_index = 18
		parent.add_child(monster)
		monster.configure({
			"type": "small", "hp": 20, "scale": float(entry["scale"]),
			"appearance_id": str(entry["appearance_id"]),
			"visual_tier": int(entry["visual_tier"]),
		})
		monster.position = entry["position"]


func _add_review_energy_hud(parent: Control) -> void:
	var energy_hud := ENERGY_HUD_SCRIPT.new() as EnergyHud
	energy_hud.name = "ReviewEnergyHud"
	energy_hud.position = GameConfig.ENERGY_HUD_POSITION
	energy_hud.size = GameConfig.ENERGY_HUD_SIZE
	energy_hud.z_as_relative = false
	energy_hud.z_index = 80
	parent.add_child(energy_hud)
	energy_hud.set_energy(66, GameConfig.SKILL_ENERGY_MAX)
	energy_hud.set_cluster_swap_count(1)
	energy_hud.set_crystal_rain_enabled(true)


func _add_tutorial(viewport: SubViewport, state: String) -> void:
	_add_battle(viewport)
	var tutorial := FirstWaveTutorialView.new()
	_review_overlay(viewport).add_child(tutorial)
	tutorial.setup(Rect2(138, 690, 633, 633), Rect2(138, 690, 380, 126), Vector2(470, 445))
	if state == "core":
		tutorial.show_core_reward()
	else:
		tutorial.show_first_merge_guide()


func _add_secondary(viewport: SubViewport, spec: Dictionary) -> void:
	if str(spec.get("base", "hub")) == "battle":
		_add_battle(viewport)
	else:
		_add_hub(viewport, "continue")
	var service := _make_review_service(str(spec.get("state", "")))
	var ui := SecondaryUiController.new()
	ui.name = "SecondaryUiController"
	ui.size = Vector2(DESIGN_SIZE)
	_review_overlay(viewport).add_child(ui)
	ui.setup(service)
	ui._daily_tab = str(spec.get("tab", "tasks"))
	if str(spec.get("page", "")) == "purchase_confirm":
		ui._pending_product_id = "coins_10000"
		ui._purchase_return_page = "shop"
	ui.open(str(spec.get("page", "")), "battle" if str(spec.get("base", "hub")) == "battle" else "hub")


func _make_review_service(state: String) -> MetaProgressService:
	var service := MetaProgressService.new()
	var coins := 31884
	var crystals := 1160
	if state == "insufficient":
		coins = 0
		crystals = 0
	service.setup(coins, crystals, {})
	service.sync_day("2026-08-16")
	service.task_progress["settle_once"] = 1
	service.task_progress["merge_20"] = 12
	service.task_progress["kill_30"] = 30
	service.task_progress["login"] = 1
	service.task_claimed["login"] = true
	service.signin_last_date = "2026-08-15"
	service.signin_streak = 3
	service.piggy_coins = 1000 if state == "full" else 680
	if state == "owned":
		service.double_coin_owned = true
		service.remove_ads_owned = true
	return service


func _add_imprint(viewport: SubViewport, selected: bool) -> void:
	_add_battle(viewport)
	var modal := IMPRINT_SCENE.instantiate() as ImprintChoiceModalV2
	_review_overlay(viewport).add_child(modal)
	modal.setup(
		["ascension_hammer", "unity_dial", "castle_cannon"],
		Vector2(175, 1510), [1, 2, 3], [false, false, true], [true, false, true], false
	)
	if selected:
		# The review preset needs the post-intro state immediately; selection still
		# goes through the formal modal handler rather than drawing a fake overlay.
		modal._input_locked = false
		modal._on_slot_pressed(1)


func _add_crystal_choice(viewport: SubViewport, selected: bool) -> void:
	_add_battle(viewport)
	var modal := CRYSTAL_SCENE.instantiate() as CrystalCardChoiceModalV2
	_review_overlay(viewport).add_child(modal)
	modal.setup(
		"chapter_reward", ["fire_conduit", "poison_tank", "rapid_clockwork"],
		Vector2(175, 1510), Vector2(470, 445), [1, 2, 3], [true, false, true]
	)
	if selected:
		modal._locked = false
		modal._select_card(1)


func _add_node_complete(viewport: SubViewport, chapter: bool) -> void:
	_add_battle(viewport)
	var modal := NODE_COMPLETE_SCENE.instantiate() as ChapterNodeCompleteModal
	_review_overlay(viewport).add_child(modal)
	if chapter:
		modal.setup_chapter_completion()
	else:
		modal.setup("1-2")


func _add_max_level_success(viewport: SubViewport) -> void:
	_add_battle(viewport)
	var popup = MAX_LEVEL_SUCCESS_SCRIPT.new()
	popup.name = "MaxLevelSuccessView"
	popup.setup(GameConfig.MAX_BLOCK_LEVEL, false)
	popup.size = Vector2(DESIGN_SIZE)
	_review_overlay(viewport).add_child(popup)


func _add_settlement(viewport: SubViewport, won: bool) -> void:
	_add_battle(viewport)
	var settlement := SettlementView.new()
	_review_overlay(viewport).add_child(settlement)
	settlement.setup(won, {
		"highest": 10, "kills": 38, "merges": 24, "max_merge": 5,
		"castle": 16, "castle_max": 20, "leaks": 2,
		"board_damage": 1860, "crystal_damage": 940, "skill_damage": 620,
		"reward_coins": 320, "reward_crystals": 18,
		"cards": [
			{"id": "fire_conduit", "level": 2, "selections": 2},
			{"id": "rapid_clockwork", "level": 1, "selections": 1},
		]
	})


func _add_focus_guides(viewport: SubViewport) -> void:
	var guides := Control.new()
	guides.name = "ReviewGuides"
	guides.size = Vector2(DESIGN_SIZE)
	guides.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guides.z_index = 1000
	viewport.add_child(guides)
	var vertical := ColorRect.new()
	vertical.name = "CenterVertical"
	vertical.position = Vector2(470, 0)
	vertical.size = Vector2(2, 1672)
	vertical.color = Color(1.0, 0.18, 0.32, 0.72)
	vertical.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guides.add_child(vertical)
	var horizontal := ColorRect.new()
	horizontal.name = "CenterHorizontal"
	horizontal.position = Vector2(0, 835)
	horizontal.size = Vector2(941, 2)
	horizontal.color = Color(1.0, 0.18, 0.32, 0.72)
	horizontal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guides.add_child(horizontal)
	for edge in [
		Rect2(40, 40, 861, 2), Rect2(40, 1630, 861, 2),
		Rect2(40, 40, 2, 1592), Rect2(899, 40, 2, 1592),
	]:
		var line := ColorRect.new()
		line.name = "SafeGuide"
		line.position = edge.position
		line.size = edge.size
		line.color = Color(0.15, 0.95, 0.62, 0.82)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		guides.add_child(line)
	_refresh_focus_guides()


func _refresh_focus_guides() -> void:
	if _focus_viewport == null:
		return
	var guides := _focus_viewport.get_node_or_null("ReviewGuides")
	if guides == null:
		return
	guides.visible = _center_guides_enabled or _safe_guides_enabled
	for child in guides.get_children():
		if child.name == "CenterVertical" or child.name == "CenterHorizontal":
			child.visible = _center_guides_enabled
		elif child.name.begins_with("SafeGuide"):
			child.visible = _safe_guides_enabled


func _find_spec(page_id: String) -> Dictionary:
	for spec in PAGE_SPECS:
		if str(spec.get("id", "")) == page_id:
			return spec
	return {}


func _make_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_button(text_value: String, font_size: int = 17) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size.y = 38.0
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_stylebox_override("normal", _flat_style(Color("203553"), Color("385a84"), 1, 8))
	button.add_theme_stylebox_override("hover", _flat_style(Color("29486f"), Color("65a8ec"), 1, 8))
	button.add_theme_stylebox_override("pressed", _flat_style(Color("152945"), Color("65a8ec"), 1, 8))
	button.focus_mode = Control.FOCUS_NONE
	return button


func _flat_style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 9.0
	style.content_margin_right = 9.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style


func _set_margins(container: MarginContainer, amount: int) -> void:
	container.add_theme_constant_override("margin_left", amount)
	container.add_theme_constant_override("margin_top", amount)
	container.add_theme_constant_override("margin_right", amount)
	container.add_theme_constant_override("margin_bottom", amount)
