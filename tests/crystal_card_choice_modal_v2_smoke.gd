extends SceneTree

const ModalScene := preload("res://scenes/ui/crystal_card_choice_modal_v2.tscn")

var _failed := false
var _chosen_id := ""
var _closed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var modal := ModalScene.instantiate() as CrystalCardChoiceModalV2
	root.add_child(modal)
	modal.choice_committed.connect(func(_kind: String, card_id: String, _element: String, _level: int): _chosen_id = card_id)
	modal.modal_closed.connect(func(_kind: String): _closed = true)
	modal.setup(
		"milestone",
		["fire_conduit", "poison_tank", "rapid_clockwork"],
		Vector2(170.0, 1510.0),
		Vector2(470.0, 430.0),
		[1, 2, 3],
		[true, false, true]
	)
	await create_timer(0.70, true).timeout
	var cards_root := modal.get_node("ContentRoot/CardsRoot")
	_check(cards_root.get_child_count() == 3, "crystal choice should build three cards")
	var title_label := modal.get_node("ContentRoot/TitleRibbon/Title") as Label
	_check(title_label.text == "选择合成印记", "new title copy should match the reference")
	_check(title_label.get_theme_font_size("font_size") == CrystalCardChoiceModalV2.TITLE_FONT_SIZE, "title must use the enlarged reference scale")
	_check((title_label.get_theme_font("font") as SystemFont).font_weight >= 800, "title must use the bold Chinese UI font")
	_check(modal.has_node("ContentRoot/TitleRibbon/LeftDiamond") and modal.has_node("ContentRoot/TitleRibbon/RightDiamond"), "title ribbon must include both reference diamond ornaments")
	_check(modal._selected_index == -1, "crystal choice should not preselect a card")
	_check((modal.get_node("ContentRoot/ConfirmButton") as TextureButton).disabled, "confirm should be disabled before selection")
	var first_card := cards_root.get_child(0) as CrystalChoiceCardViewV2
	_check(first_card.get_child(0).name == "SelectionFrame", "yellow selection frame must render below all card content")
	_check(first_card.get_node("CardTransform").get_index() > first_card.get_node("SelectionFrame").get_index(), "card artwork and copy must render above the selection frame")
	_check(first_card.get_node_or_null("CardTransform/Front/Backplate") != null, "card should use the new supplied backplate")
	_check((first_card.get_node("CardTransform/Front/ItemName") as Label).text == str(CardCatalog.get_definition("fire_conduit").get("item_name", "")), "card name should come from the existing catalog")
	_check(((first_card.get_node("CardTransform/Front/ItemName") as Label).get_theme_font("font") as SystemFont).font_weight >= 800, "card names must use the bold Chinese UI font")
	_check(first_card.get_node_or_null("CardTransform/Front/NewBadge") != null, "unseen card should show the supplied NEW badge")
	var long_copy_card := cards_root.get_child(2) as CrystalChoiceCardViewV2
	var long_copy := long_copy_card.get_node("CardTransform/Front/Description") as Label
	_check(long_copy.text == "当前游戏局提高攻击速度\n缩短水晶普通攻击间隔", "long-copy probe must use the rapid-clockwork description")
	_check(long_copy.get_theme_font_size("font_size") == 17, "eleven-character crystal-card lines must use the smaller non-orphaning font size")
	_check(long_copy.get_line_count() == 2, "rapid-clockwork copy must remain two balanced lines without a one-character orphan")
	_check(long_copy.clip_text and long_copy.get_theme_constant("line_spacing") == 2, "crystal-card copy must remain inside its safe text box")
	for crystal_id in GameConfig.CRYSTAL_CARD_IDS:
		var copy_probe := CrystalChoiceCardViewV2.new()
		copy_probe.size = Vector2(284.0, 530.0)
		root.add_child(copy_probe)
		copy_probe.setup(crystal_id, 1, false)
		await process_frame
		var probe_description := copy_probe.get_node("CardTransform/Front/Description") as Label
		var authored_lines := probe_description.text.count("\n") + 1
		_check(probe_description.get_line_count() == authored_lines, "%s description must not create an orphan wrap beyond its authored lines" % crystal_id)
		copy_probe.queue_free()
	modal._select_card(1)
	_check(modal._selected_index == 1, "clicking a card should select without immediately committing")
	_check(not (modal.get_node("ContentRoot/ConfirmButton") as TextureButton).disabled, "selection should enable confirm")
	_check(_chosen_id.is_empty(), "selection alone must not commit the card")
	modal._confirm_selection()
	await create_timer(1.05, true).timeout
	_check(_chosen_id == "poison_tank", "confirm should commit the selected existing card")
	_check(_closed, "modal should close after the selected card reaches its target")
	_check(not paused, "modal close should restore the pause state")
	if not _failed:
		print("CRYSTAL_CARD_CHOICE_MODAL_V2_SMOKE_OK")
	quit(1 if _failed else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
