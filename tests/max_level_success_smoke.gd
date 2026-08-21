extends SceneTree

const VIEW_SCRIPT := preload("res://scripts/max_level_success_view.gd")
const MAIN_GAME_SCRIPT := preload("res://scripts/main_game.gd")

var _failed := false
var _submissions := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Control.new()
	host.size = Vector2(941.0, 1672.0)
	root.add_child(host)
	var view = VIEW_SCRIPT.new()
	view.setup(GameConfig.MAX_BLOCK_LEVEL, false)
	view.size = host.size
	host.add_child(view)
	await process_frame

	_check(view.get_node_or_null("PopupShade") is ColorRect, "max-level success must block the full screen")
	_check(view.get_node_or_null("SuccessLight") is TextureRect, "max-level success must retain the rotating light")
	var panel := view.get_node_or_null("SuccessPanel") as TextureRect
	_check(panel != null and panel.size == Vector2(873.0, 1066.0), "max-level success must retain the formal panel geometry")
	var glyph := view.get_node_or_null("SuccessPanel/MaxLevelBlock/BlockGlyph") as TextureRect
	_check(glyph != null and glyph.texture != null, "maximum block glyph must be rendered")
	_check(GameConfig.get_level_label(GameConfig.MAX_BLOCK_LEVEL) == "Z", "the current maximum block must be level 36 / Z")
	var button := view.get_node_or_null("SuccessPanel/ContinueButton") as TextureButton
	_check(button != null and button.size == Vector2(510.0, 209.0), "Continue must retain the formal hit area")
	view.continue_pressed.connect(func(): _submissions += 1)
	button.pressed.emit()
	_check(_submissions == 1, "Continue must submit exactly once per press")

	# Exercise the real MainGame entry without adding MainGame to the tree, so
	# the test cannot load or mutate user:// progress.
	var integration_host := Control.new()
	integration_host.size = Vector2(941.0, 1672.0)
	root.add_child(integration_host)
	var game = MAIN_GAME_SCRIPT.new()
	game.size = integration_host.size
	game.popup_layer = integration_host
	game._show_success_popup()
	await process_frame
	_check(game._success_popup_active, "MainGame must retain the max-level modal arbitration flag")
	var integrated_view := integration_host.get_node_or_null("MaxLevelSuccessView") as Control
	_check(integrated_view != null, "MainGame and the audit center must share the formal max-level view")
	_check(integrated_view != null and integrated_view.size == integration_host.size, "MainGame must lay the max-level view over the complete design viewport")
	game.free()
	integration_host.free()

	host.free()
	if not _failed:
		print("MAX_LEVEL_SUCCESS_SMOKE_OK")
	quit(1 if _failed else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
