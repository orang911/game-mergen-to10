extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.muted = true

	_check(game.loading_view != null and game.loading_view.visible, "game should open on the login page")
	_check(game.main_hub_view != null and not game.main_hub_view.visible, "main hub should stay hidden before login play")

	game._on_play_pressed()
	await _wait_seconds(0.30)
	_check(game.main_layer.visible, "login play should keep the menu layer visible")
	_check(not game.loading_view.visible, "login page should hide after login play")
	_check(game.main_hub_view.visible, "login play should open the main hub")
	_check(not game.game_layer.visible, "opening the hub must not start combat")
	_check(game.main_hub_view._interactive, "hub should become interactive after its intro")

	var design_root := game.main_hub_view.get_node("DesignRoot") as Control
	var stage_button := game.main_hub_view.get_node("DesignRoot/StageButton") as TextureButton
	var stage_label := game.main_hub_view.get_node("DesignRoot/StageButton/Label") as Label
	_check(stage_button.texture_normal != null, "stage one button art should load")
	_check(stage_label.text == "第1关", "the first playable button should be labeled stage one")
	for path in [
		"DesignRoot/Background",
		"DesignRoot/Portal",
		"DesignRoot/GuardianCrystal",
		"DesignRoot/LightningToken",
		"DesignRoot/FireToken",
		"DesignRoot/FrostToken",
		"DesignRoot/CriticalToken",
		"DesignRoot/PoisonToken",
		"DesignRoot/BottomNavigation",
	]:
		var texture_node := game.main_hub_view.get_node(path) as TextureRect
		_check(texture_node != null and texture_node.texture != null, "%s should load its supplied texture" % path)

	for viewport_size in [Vector2(951.0, 1654.0), Vector2(941.0, 1800.0), Vector2(1280.0, 1672.0)]:
		game.main_hub_view.layout_for_viewport(viewport_size)
		_check(is_equal_approx(design_root.scale.x, design_root.scale.y), "hub scaling should remain proportional")
		var display_size := MainHubView.DESIGN_SIZE * design_root.scale.x
		_check(
			design_root.position.x >= -0.01
				and design_root.position.y >= -0.01
				and design_root.position.x + display_size.x <= viewport_size.x + 0.01
				and design_root.position.y + display_size.y <= viewport_size.y + 0.01,
			"hub should remain centered inside the viewport"
		)

	game.main_hub_view.stage_pressed.emit(1)
	await process_frame
	_check(game.game_layer.visible and not game.main_layer.visible, "clicking stage one should enter combat")

	game.over_game()
	await _wait_seconds(0.30)
	_check(game.main_layer.visible and game.main_hub_view.visible, "returning home should reopen the main hub")
	_check(not game.loading_view.visible, "returning home should not return to the login page")

	game.queue_free()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("MAIN_HUB_FLOW_SMOKE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _wait_seconds(seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
