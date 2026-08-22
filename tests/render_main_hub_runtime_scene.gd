extends SceneTree

const OUTPUT := "res://../art/production/lobby/2026-08-16_main_hub_runtime_alignment_v01/runtime_main_scene_941x1672.png"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(941, 1672)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)

	var game := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	viewport.add_child(game)
	await process_frame
	await process_frame
	game.loading_view.stop_animations()
	game.loading_view.visible = false
	game._first_wave_tutorial_completed = true
	game._crystal_awakened_unlocked = true
	game.show_main_menu()
	game.main_hub_view.set_resource_values(2823, 114000)
	game.main_hub_view.set_stage_entry("第5关")
	for index in range(8):
		await process_frame

	var panel := game.main_hub_view.get_node("DesignRoot/MissionPanel") as NinePatchRect
	var reward := game.main_hub_view.get_node("DesignRoot/MissionRewardSlot") as NinePatchRect
	if panel.position != Vector2(178, 174) or panel.size != Vector2(604, 165):
		push_error("MAIN_SCENE_MISSION_PANEL_MISMATCH: %s %s" % [panel.position, panel.size])
		quit(1)
		return
	if reward.position != Vector2(624, 195) or reward.size != Vector2(135, 118):
		push_error("MAIN_SCENE_MISSION_REWARD_MISMATCH: %s %s" % [reward.position, reward.size])
		quit(1)
		return

	var image := viewport.get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path(OUTPUT))
	if error != OK:
		push_error("MAIN_SCENE_SCREENSHOT_SAVE_FAILED: %s" % error_string(error))
		quit(1)
		return
	print("MAIN_HUB_RUNTIME_SCENE_OK")
	quit(0)
