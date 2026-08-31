extends SceneTree

const ModalScene := preload("res://scenes/ui/imprint_choice_modal_v2.tscn")
const MainGameScript := preload("res://scripts/main_game.gd")

var _failed := false
var _chosen_id := ""
var _closed := false
var _locked_press_count := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_random_offers()
	await _test_all_imprint_copy_fits()
	await _test_modal_states_and_commit()
	if not _failed:
		print("IMPRINT_CHOICE_MODAL_SMOKE_OK")
	quit(1 if _failed else 0)


func _test_random_offers() -> void:
	_check(GameConfig.ENERGY_IMPRINT_POOL_IDS.size() == 6, "energy imprint pool should retain all six imprints")
	_check(GameConfig.ENERGY_IMPRINT_OFFER_COUNT == 3, "energy modal should offer three imprints")
	_check(GameConfig.ENERGY_IMPRINT_FREE_SLOT_COUNT == 2, "only the first two displayed slots should be free")
	var game := MainGameScript.new()
	var seen: Dictionary = {}
	for _run_index in range(300):
		var draw: Dictionary = game._draw_unified_cards("energy")
		var ids: Array = draw.get("ids", [])
		_check(ids.size() == 3, "every energy draw should contain three ids")
		var unique: Dictionary = {}
		for card_id in ids:
			_check(GameConfig.ENERGY_IMPRINT_POOL_IDS.has(card_id), "draw contained an id outside the six-imprint pool")
			unique[card_id] = true
			seen[card_id] = true
		_check(unique.size() == 3, "one energy draw must not contain duplicate imprints")
	_check(seen.size() == GameConfig.ENERGY_IMPRINT_POOL_IDS.size(), "all six imprints should appear across repeated equal-weight draws")
	game.free()


func _test_all_imprint_copy_fits() -> void:
	var modal := ModalScene.instantiate() as ImprintChoiceModalV2
	root.add_child(modal)
	var batches: Array[Array] = [
		["ascension_hammer", "unity_dial", "fate_shuffler"],
		["twin_mold", "castle_cannon", "dragon_catapult"],
	]
	for batch in batches:
		var ids: Array[String] = []
		for card_id in batch:
			ids.append(str(card_id))
		modal.setup(ids, Vector2.ZERO, [1, 5, 5], [false, false, false], [false, false, false], false)
		await process_frame
		var slots_root := modal.get_node("ContentRoot/SlotsRoot")
		for slot in slots_root.get_children():
			var name_label := slot.get_node("Name") as Label
			var icon_clip := slot.get_node("IconClip") as Control
			var icon := icon_clip.get_node("Icon") as TextureRect
			var description := slot.get_node("Description") as Label
			var authored_lines := description.text.count("\n") + 1
			_check(name_label.get_minimum_size().x <= name_label.size.x + 0.01, "%s title must remain inside the card header" % slot.name)
			_check(icon_clip.clip_contents, "%s icon must be clipped to the card art safe area" % slot.name)
			_check(icon_clip.position == ImprintChoiceModalV2.ICON_SAFE_RECT.position and icon_clip.size == ImprintChoiceModalV2.ICON_SAFE_RECT.size, "%s icon clip must use the shared safe rect" % slot.name)
			_check(icon.position == Vector2.ZERO and icon.size == icon_clip.size, "%s icon must remain completely inside its clip container" % slot.name)
			_check(description.get_line_count() == authored_lines, "%s description must not create an extra wrapped line" % slot.name)
			_check(description.get_visible_line_count() >= authored_lines, "%s description must show every authored line" % slot.name)
			_check(description.position.x >= 34.0 and description.position.x + description.size.x <= slot.size.x - 34.0, "%s description must retain equal horizontal insets" % slot.name)
			_check(description.position.y + description.size.y <= slot.size.y - 80.0, "%s description must retain a bottom safe margin" % slot.name)
	paused = false
	modal.queue_free()
	await process_frame


func _test_modal_states_and_commit() -> void:
	var modal := ModalScene.instantiate() as ImprintChoiceModalV2
	root.add_child(modal)
	modal.choice_committed.connect(func(_kind: String, card_id: String, _element: String, _level: int): _chosen_id = card_id)
	modal.modal_closed.connect(func(_kind: String): _closed = true)
	modal.locked_slot_pressed.connect(func(_card_id: String): _locked_press_count += 1)
	var ids: Array[String] = ["ascension_hammer", "unity_dial", "castle_cannon"]
	var levels: Array[int] = [1, 2, 3]
	var locked: Array[bool] = [false, false, true]
	var new_flags: Array[bool] = [true, false, true]
	modal.setup(ids, Vector2(180.0, 1510.0), levels, locked, new_flags)
	await create_timer(0.55, true).timeout

	var slots_root := modal.get_node("ContentRoot/SlotsRoot")
	_check(slots_root.get_child_count() == 3, "modal should build three visible cards")
	_check(modal._selected_index == -1, "modal should open without a default selection")
	_check(not (slots_root.get_child(0).get_node("SelectionOutline") as Panel).visible, "unselected opening state should hide the outline")
	_check(not slots_root.get_child(0).has_node("SelectedCheck"), "imprint cards must not create the removed selected-check overlay")
	_check(not slots_root.get_child(2).has_node("Lock"), "ad placeholder must not cover the third reward with a lock")
	_check((slots_root.get_child(2).get_node("IconClip/Icon") as TextureRect).material == null, "ad placeholder must not grayscale the third reward")
	_check(slots_root.get_child(2).has_node("AdUnlockButton"), "third displayed slot should retain the ad placeholder")
	var ad_button := slots_root.get_child(2).get_node("AdUnlockButton") as TextureButton
	_check(ad_button.position.y >= slots_root.get_child(2).size.y, "ad placeholder should sit below, not inside, the third card")
	_check(modal.has_node("ContentRoot/TitleGroup/Title"), "title should use the clean floating title treatment")
	_check(not modal.has_node("ContentRoot/TitleBanner"), "title should not retain the opaque banner")
	_check(((modal.get_node("ContentRoot/TitleGroup/Title") as Label).get_theme_font("font") as SystemFont).font_weight >= 900, "imprint title must use the shared secondary-screen heavy font")
	var left_ornament := modal.get_node("ContentRoot/TitleGroup/LeftOrnament") as TextureRect
	var right_ornament := modal.get_node("ContentRoot/TitleGroup/RightOrnament") as TextureRect
	_check(left_ornament.texture.resource_path.ends_with("ui_title_banner_blank_304x52_v01.png"), "title must use the newly replaced ornament sprite")
	_check(left_ornament.flip_h and not right_ornament.flip_h, "supplied right ornament must be mirrored only on the left side")
	_check(left_ornament.position.x + left_ornament.size.x <= (modal.get_node("ContentRoot/TitleGroup/Title") as Label).position.x, "left ornament must not overlap title copy")
	_check((modal.get_node("ContentRoot/TitleGroup/Title") as Label).position.x + (modal.get_node("ContentRoot/TitleGroup/Title") as Label).size.x <= right_ornament.position.x, "right ornament must not overlap title copy")
	_check(not (modal.get_node("ContentRoot/SelectionHint") as Label).visible, "reference layout must not add an extra selection hint between cards and actions")
	_check((slots_root.get_child(0).get_node("NewBadge") as TextureRect).visible, "unseen free imprint should display NEW")
	_check((slots_root.get_child(2).get_node("NewBadge") as TextureRect).visible, "unseen locked preview may display NEW without being obtained")
	for slot in slots_root.get_children():
		var description := slot.get_node("Description") as Label
		_check(description.position == ImprintChoiceModalV2.DESCRIPTION_RECT.position, "imprint description must use the shared safe inset")
		_check(description.position.x + description.size.x <= slot.size.x - 29.0, "imprint description must not touch the right frame")
		_check(description.position.y + description.size.y <= slot.size.y - 54.0, "imprint description must stay above the lower card frame")
		_check(description.get_theme_font_size("font_size") <= ImprintChoiceModalV2.DESCRIPTION_MAX_FONT_SIZE, "imprint description font must fit the narrow card")
		_check(description.clip_text, "imprint description must be clipped to its safe text region")
		var card_frame := slot.get_node("CardFrame") as NinePatchRect
		_check(card_frame.material is ShaderMaterial, "card frame must clean the source-image white and black seam artifacts")
	_check((modal.get_node("ContentRoot/SelectionHint") as Label).text == "请选择技能印记", "empty selection should show the choice prompt")
	_check((modal.get_node("ContentRoot/ConfirmButton") as TextureButton).disabled, "confirm should stay disabled until an imprint is selected")
	var curve_start := Vector2(190.0, 480.0)
	var curve_target := Vector2(70.0, 1510.0)
	var curve_control: Vector2 = modal._make_commit_curve_control(curve_start, curve_target)
	var curved_midpoint: Vector2 = modal._quadratic_bezier(curve_start, curve_control, curve_target, 0.5)
	_check(absf(curved_midpoint.x - curve_start.lerp(curve_target, 0.5).x) > 30.0, "committed imprint should follow a visible curved path")
	_check(modal._quadratic_bezier(curve_start, curve_control, curve_target, 1.0).distance_to(curve_target) < 0.01, "curved flight must finish at the exact pending-slot center")
	modal._on_slot_button_down(0)
	_check(slots_root.get_child(0).position == modal._slot_views[0]["base_position"], "pressing a card must not offset its layout position")
	modal._on_slot_button_up(0)

	modal._on_slot_pressed(1)
	_check(modal._selected_index == 1, "second free slot should be selectable")
	_check((slots_root.get_child(1).get_node("SelectionOutline") as Panel).visible, "selected card should show its cyan outline")
	_check(not (modal.get_node("ContentRoot/ConfirmButton") as TextureButton).disabled, "a free selection should enable confirm")
	modal._on_slot_pressed(2)
	_check(modal._selected_index == 2, "the card carrying the ad placeholder must remain selectable")
	_check(not (modal.get_node("ContentRoot/ConfirmButton") as TextureButton).disabled, "selecting the third card should enable confirm")
	modal._on_locked_ad_pressed(2)
	_check(modal._selected_index == 2, "the visual-only ad placeholder must not change card selection")
	_check(_locked_press_count == 0, "the visual-only ad placeholder must not request an ad")

	modal._confirm_selection()
	await create_timer(0.85, true).timeout
	_check(_chosen_id == "castle_cannon", "confirm should commit the selected third imprint even with an ad placeholder")
	_check(_closed, "modal should close after the icon reaches the pending slot")
	_check(not paused, "closing the modal should restore the scene tree pause state")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
