extends SceneTree

const REVIEW_SCENE := preload("res://scenes/ui/ui_global_review.tscn")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var review := REVIEW_SCENE.instantiate()
	root.add_child(review)
	await process_frame
	await process_frame

	var ids: Array[String] = review.get_registered_page_ids()
	_check(ids.size() == 29, "global review should register all 29 approved runtime states")
	var unique: Dictionary = {}
	for page_id in ids:
		unique[page_id] = true
	_check(unique.size() == ids.size(), "global review page ids must be unique")
	_check(ids.has("loading") and ids.has("hub_continue") and ids.has("battle"), "startup, hub and battle references must be present")
	_check(ids.has("daily_tasks") and ids.has("daily_signin") and ids.has("shop"), "secondary hub pages must be present")
	_check(ids.has("imprint") and ids.has("crystal_choice"), "both live card-choice interfaces must be present")
	_check(ids.has("node_complete") and ids.has("max_level_success") and ids.has("settlement_win") and ids.has("settlement_lose"), "completion, max-level success and settlement states must be present")

	var overview_deadline := Time.get_ticks_msec() + 12000
	while not review._overview_built and Time.get_ticks_msec() < overview_deadline:
		await process_frame
	_check(review._overview_built, "live overview should finish building")
	_check(review._overview_grid.get_child_count() == ids.size(), "overview should contain one live card per registered state")

	for page_id in ids:
		_check(review.show_page(page_id), "registered page should open: %s" % page_id)
		await process_frame
		await process_frame
		var base_layer := review._focus_viewport.get_node_or_null("ReviewBaseLayer") as Control
		var overlay_layer := review._focus_viewport.get_node_or_null("ReviewOverlayLayer") as Control
		_check(base_layer != null and overlay_layer != null, "focused page should have fixed base and overlay layers: %s" % page_id)
		_check(overlay_layer.z_index > base_layer.z_index, "formal modal layer must render above the runtime base: %s" % page_id)
		_check(not paused, "reviewing a modal must not leave the audit tree paused: %s" % page_id)

	_check(not review.show_page("missing_page"), "unknown pages should be rejected")
	review.show_page("battle")
	await process_frame
	await process_frame
	await process_frame
	var battle_base := review._focus_viewport.get_node("ReviewBaseLayer") as Control
	_check(battle_base.get_node_or_null("BattleBackground") != null, "battle review must include the formal full-screen battle background")
	var review_board := battle_base.get_node_or_null("ReviewBoard") as Control
	_check(review_board != null and review_board.get_child_count() == GameConfig.GRID_SIZE * GameConfig.GRID_SIZE, "battle review must include the complete 5x5 board")
	_check(battle_base.get_node_or_null("BattleLayer") is BattleLayerView, "battle review must retain the formal battle HUD/path scene")
	_check(battle_base.get_node_or_null("ReviewEnergyHud") is EnergyHud, "battle review must include the formal energy and item HUD")
	review.show_page("daily_signin")
	await process_frame
	var focused_ui := review._focus_viewport.get_node_or_null("ReviewOverlayLayer/SecondaryUiController") as SecondaryUiController
	_check(focused_ui != null and focused_ui.page_id == "daily" and focused_ui._daily_tab == "combined", "task and sign-in review aliases should open the same combined daily sheet")
	var guides := review._focus_viewport.get_node_or_null("ReviewGuides") as Control
	for guide in guides.get_children():
		if guide.name.begins_with("SafeGuide"):
			_check(not guide.visible, "all safe-area guide lines must remain hidden by default")
	review.show_page("imprint_selected")
	await process_frame
	await process_frame
	await process_frame
	var focused_imprint := review._focus_viewport.get_node_or_null("ReviewOverlayLayer/ImprintChoiceModalV2") as ImprintChoiceModalV2
	_check(focused_imprint != null and focused_imprint._selected_index == 1, "selected imprint review state should use the formal V2 modal")
	_check(focused_imprint._slot_views.size() == 3, "imprint audit state must show all three formal choices")
	for entry in focused_imprint._slot_views:
		_check(is_equal_approx((entry["root"] as Control).modulate.a, 1.0), "imprint review cards must not be captured mid-intro")
	review.show_page("crystal_choice")
	await process_frame
	await process_frame
	await process_frame
	var focused_crystal := review._focus_viewport.get_node_or_null("ReviewOverlayLayer/CrystalCardChoiceModalV2") as CrystalCardChoiceModalV2
	_check(focused_crystal != null and focused_crystal._cards.size() == 3, "crystal audit state must show the complete three-choice interface")
	for card in focused_crystal._cards:
		_check(card.is_revealed() and is_equal_approx(card.modulate.a, 1.0), "crystal review cards must be fully revealed")
	review.show_page("max_level_success")
	await process_frame
	await process_frame
	await process_frame
	var max_popup := review._focus_viewport.get_node_or_null("ReviewOverlayLayer/MaxLevelSuccessView") as Control
	_check(max_popup != null, "max-level merge congratulations must use the formal runtime view")
	_check(max_popup.get_node_or_null("SuccessPanel/MaxLevelBlock") != null, "max-level success view must show the maximum block")
	_check(max_popup.get_node_or_null("SuccessPanel/ContinueButton") != null, "max-level success view must include its Continue action")

	review.free()
	paused = false
	if not _failed:
		print("UI_GLOBAL_REVIEW_SMOKE_OK")
	quit(1 if _failed else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
