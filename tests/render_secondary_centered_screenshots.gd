extends SceneTree

const OUT := "res://../art/production/ui/chapter01/2026-08-13_centered_interfaces_runtime_v04/qa/runtime_941x1672/"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(941, 1672)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)
	var background := TextureRect.new()
	background.texture = load("res://assets/runtime/ui/interfaces/main_hub/standalone/lobby_background_clean_v01.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(background)

	var service := MetaProgressService.new()
	service.setup(1804, 120, {})
	service.sync_day("2026-08-13")
	service.task_progress["settle_once"] = 1
	service.task_progress["merge_20"] = 12
	service.task_progress["kill_30"] = 30
	service.task_progress["login"] = 1
	service.piggy_coins = 680

	var ui := SecondaryUiController.new()
	ui.size = Vector2(941, 1672)
	viewport.add_child(ui)
	ui.setup(service)
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

	for spec in [
		["pause", "tasks"], ["exit_confirm", "tasks"], ["settings", "tasks"],
		["clear_confirm", "tasks"], ["daily", "tasks"], ["daily", "signin"],
		["benefits", "tasks"], ["first_purchase", "tasks"], ["piggy", "tasks"], ["shop", "tasks"],
	]:
		ui._daily_tab = spec[1]
		ui.open(spec[0], "hub")
		await process_frame
		await process_frame
		await process_frame
		var suffix: String = "_signin" if spec[0] == "daily" and spec[1] == "signin" else "_tasks" if spec[0] == "daily" else ""
		var image := viewport.get_texture().get_image()
		var path := ProjectSettings.globalize_path(OUT + spec[0] + suffix + ".png")
		var error := image.save_png(path)
		if error != OK:
			push_error("Failed to save %s: %s" % [path, error_string(error)])
	ui.queue_free()
	await process_frame
	print("SECONDARY_CENTERED_SCREENSHOTS_OK")
	quit(0)
