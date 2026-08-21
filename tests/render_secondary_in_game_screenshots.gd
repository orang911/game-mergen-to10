extends SceneTree

const OUT := "res://art/production/ui/chapter01/2026-08-14_secondary_in_game_acceptance/"
const HUB_SCENE := preload("res://scenes/ui/main_hub.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "hub"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "battle"))
	await _render_hub_pages()
	await _render_daily_narrow()
	await _render_battle_pages()
	print("SECONDARY_IN_GAME_SCREENSHOTS_OK")
	quit(0)


func _make_viewport(viewport_size := Vector2i(941, 1672)) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)
	return viewport


func _make_service() -> MetaProgressService:
	var service := MetaProgressService.new()
	service.setup(8888, 8888, {})
	service.sync_day("2026-08-14")
	service.task_progress["settle_once"] = 0
	service.task_progress["merge_20"] = 12
	service.task_progress["kill_30"] = 30
	service.task_progress["login"] = 1
	service.task_claimed["login"] = true
	service.signin_last_date = "2026-08-13"
	service.signin_streak = 3
	service.piggy_coins = 680
	return service


func _render_hub_pages() -> void:
	var viewport := _make_viewport()
	var game := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	viewport.add_child(game)
	await process_frame
	await process_frame
	game.loading_view.stop_animations()
	game.loading_view.visible = false
	game.muted = true
	game._first_wave_tutorial_completed = true
	game._crystal_awakened_unlocked = true
	game._wallet_crystals = 8888
	game._wallet_coins = 8888
	game.meta_progress = _make_service()
	game.secondary_ui.setup(game.meta_progress)
	game.show_main_menu()
	game.main_hub_view.set_resource_values(8888, 8888)
	game.main_hub_view.set_stage_entry("继续挑战")
	var ui := game.secondary_ui as SecondaryUiController
	await _settle_frames()

	for spec in [
		["settings", "tasks"], ["clear_confirm", "tasks"],
		["daily", "combined"],
		["benefits", "tasks"], ["first_purchase", "tasks"],
		["piggy", "tasks"], ["shop", "tasks"],
	]:
		ui._daily_tab = spec[1]
		ui.open(spec[0], "hub")
		await _settle_frames()
		var suffix: String = "_combined" if spec[0] == "daily" else ""
		await _save(viewport, OUT + "hub/" + spec[0] + suffix + ".png")
		if spec[0] == "daily":
			await _save(
				viewport,
				"res://art/production/ui/daily_program_composition/2026-08-16_cutouts_v02/previews/daily_program_runtime_941x1672_v02.png"
			)
			game.meta_progress.claim_signin()
			await _settle_frames()
			await _save(
				viewport,
				"res://art/production/ui/daily_program_composition/2026-08-16_cutouts_v02/previews/daily_program_runtime_after_claim_941x1672_v02.png"
			)
			game.meta_progress.signin_last_date = ""
			game.meta_progress.signin_streak = 0
			game.meta_progress.changed.emit()
			await _settle_frames()
			await _save(
				viewport,
				"res://art/production/ui/daily_program_composition/2026-08-16_cutouts_v02/previews/daily_program_runtime_day1_941x1672_v02.png"
			)
			game.meta_progress.signin_last_date = "2026-08-13"
			game.meta_progress.signin_streak = 3
			game.meta_progress.changed.emit()
			await _settle_frames()
	game.queue_free()
	viewport.queue_free()
	await process_frame


func _render_daily_narrow() -> void:
	var viewport := _make_viewport(Vector2i(568, 1012))
	var game := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	viewport.add_child(game)
	await process_frame
	await process_frame
	game.loading_view.stop_animations()
	game.loading_view.visible = false
	game.muted = true
	game._first_wave_tutorial_completed = true
	game._crystal_awakened_unlocked = true
	game.meta_progress = _make_service()
	game.meta_progress.signin_last_date = ""
	game.meta_progress.signin_streak = 0
	game.secondary_ui.setup(game.meta_progress)
	game.show_main_menu()
	game.secondary_ui.open("daily", "hub")
	await _settle_frames()
	await _save(
		viewport,
		"res://art/production/ui/daily_program_composition/2026-08-16_cutouts_v02/previews/daily_program_runtime_day1_568x1012_v02.png"
	)
	game.queue_free()
	viewport.queue_free()
	await process_frame


func _render_battle_pages() -> void:
	var viewport := _make_viewport()
	var game := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	viewport.add_child(game)
	await process_frame
	await process_frame
	game.loading_view.stop_animations()
	game.loading_view.visible = false
	game.muted = true
	game._first_wave_tutorial_completed = true
	game._stop_first_wave_tutorial()
	game.main_layer.visible = false
	game.game_layer.visible = true
	game.game_status = game.GameStatus.START
	game._chapter_active = true
	game._campaign_mode = "chapter"
	game._toggle_manual_pause()
	await _settle_frames()
	await _save(viewport, OUT + "battle/pause.png")
	game.secondary_ui.open("exit_confirm", "pause")
	await _settle_frames()
	await _save(viewport, OUT + "battle/exit_confirm.png")
	game.get_tree().paused = false
	viewport.queue_free()
	await process_frame


func _settle_frames() -> void:
	var deadline := Time.get_ticks_msec() + 280
	while Time.get_ticks_msec() < deadline:
		await process_frame


func _save(viewport: SubViewport, path: String) -> void:
	var image := viewport.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("No rendered image for %s" % path)
		return
	var absolute_path := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var error := image.save_png(absolute_path)
	if error != OK:
		push_error("Failed to save %s: %s" % [path, error_string(error)])
