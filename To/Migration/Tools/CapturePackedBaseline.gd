extends SceneTree

var output := ""
var capture_size := Vector2i.ZERO

func _init() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			output = argument.trim_prefix("--capture-dir=")
		if argument.begins_with("--capture-size="):
			var parts := argument.trim_prefix("--capture-size=").split("x")
			capture_size = Vector2i(int(parts[0]),int(parts[1]))
	call_deferred("_run")

func _run() -> void:
	if output.is_empty() or DisplayServer.get_name() == "headless":
		push_error("A real rendering driver and --capture-dir are required")
		quit(1)
		return
	print("PACKAGED_USER_DATA=" + OS.get_user_data_dir())
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		quit(1)
		return
	var game := packed.instantiate()
	var surface: Viewport = root
	if capture_size != Vector2i.ZERO:
		var viewport := SubViewport.new()
		viewport.size = capture_size
		viewport.world_2d = World2D.new()
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		surface = viewport
	surface.add_child(game)
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var first := surface.get_texture().get_image().save_png(output.path_join("packed_loading.png"))
	await create_timer(3.5).timeout
	await RenderingServer.frame_post_draw
	var result := surface.get_texture().get_image()
	var second := result.save_png(output.path_join("packed_first_run.png"))
	print("CAPTURE_SIZE=%dx%d offscreen=%s" % [result.get_width(),result.get_height(),capture_size != Vector2i.ZERO])
	print("PACKAGED_VISUAL_SMOKE_OK" if first == OK and second == OK else "PACKAGED_VISUAL_SMOKE_FAILED")
	quit(0 if first == OK and second == OK else 1)
