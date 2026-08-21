extends SceneTree

const HUB_SCENE := preload("res://scenes/ui/main_hub.tscn")
const OUT := "res://art/production/lobby/2026-08-16_main_hub_runtime_alignment_v01/"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var viewport := SubViewport.new()
	viewport.size = Vector2i(941, 1672)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)
	var hub := HUB_SCENE.instantiate() as MainHubView
	viewport.add_child(hub)
	await process_frame
	hub.set_resource_values(2823, 114000)
	hub.set_stage_entry("第5关")
	hub.show_menu()
	for index in range(8):
		await process_frame
	var image := viewport.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("MAIN_HUB_ACCEPTANCE_RENDER_EMPTY")
		quit(1)
		return
	var output := ProjectSettings.globalize_path(OUT + "runtime_941x1672.png")
	var error := image.save_png(output)
	if error != OK:
		push_error("MAIN_HUB_ACCEPTANCE_SAVE_FAILED: %s" % error_string(error))
		quit(1)
		return
	hub.set_stage_entry("继续挑战", "1-1")
	for index in range(3):
		await process_frame
	image = viewport.get_texture().get_image()
	output = ProjectSettings.globalize_path(OUT + "runtime_continue_941x1672.png")
	error = image.save_png(output)
	if error != OK:
		push_error("MAIN_HUB_CONTINUE_SAVE_FAILED: %s" % error_string(error))
		quit(1)
		return
	print("MAIN_HUB_ACCEPTANCE_RENDER_OK: %s" % output)
	quit(0)
