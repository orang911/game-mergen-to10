extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/ui/loading_view.tscn") as PackedScene
	var view := packed.instantiate() as LoadingView
	root.add_child(view)
	await process_frame

	_check(view.get_node_or_null("DesignRoot/BalanceSimulationButton") == null, "Loading must not contain a visible simulation entry")
	_check((view.get_node("DesignRoot/StatusLabel") as Label).text == "正在加载…", "Loading status copy must match the approved text")

	for viewport_size in [Vector2(941.0, 1672.0), Vector2(720.0, 1600.0), Vector2(1080.0, 1920.0)]:
		view.layout_for_viewport(viewport_size)
		var design_root := view.get_node("DesignRoot") as Control
		var displayed_size := LoadingView.DESIGN_SIZE * design_root.scale.x
		_check(design_root.position.x >= -0.01 and design_root.position.y >= -0.01, "Loading controls must stay inside the top-left viewport bounds")
		_check(design_root.position.x + displayed_size.x <= viewport_size.x + 0.01 and design_root.position.y + displayed_size.y <= viewport_size.y + 0.01, "Loading controls must stay inside narrow-screen bounds")

	view.begin_loading()
	await _wait_seconds(0.35)
	var elapsed_before_pause := view._elapsed
	(view.get_node("DesignRoot/ClearLocalDataButton") as Button).pressed.emit()
	await _wait_seconds(0.25)
	_check(is_equal_approx(view._elapsed, elapsed_before_pause), "opening clear confirmation must pause Loading immediately")
	(view.get_node("ClearLocalDataConfirm") as ConfirmationDialog).canceled.emit()
	await _wait_seconds(0.20)
	_check(view._elapsed > elapsed_before_pause, "canceling clear confirmation must resume from the current progress")

	var clear_state := {"requested": false}
	view.clear_local_data_requested.connect(func():
		clear_state["requested"] = true
		view.restart_loading()
	)
	(view.get_node("DesignRoot/ClearLocalDataButton") as Button).pressed.emit()
	(view.get_node("ClearLocalDataConfirm") as ConfirmationDialog).confirmed.emit()
	await process_frame
	_check(bool(clear_state["requested"]), "confirming clear must emit clear_local_data_requested")
	_check(view._elapsed < 0.10 and (view.get_node("DesignRoot/ProgressBar/PercentLabel") as Label).text == "0%", "confirmed clear must restart the full Loading presentation")

	var completion_state := {"count": 0}
	view.loading_completed.connect(func(): completion_state["count"] = int(completion_state["count"]) + 1)
	await _wait_seconds(2.75)
	_check(int(completion_state["count"]) == 1, "Loading must complete once after 2.5 seconds plus fade")

	view.queue_free()
	await process_frame
	if failures.is_empty():
		print("LOADING_VIEW_SMOKE_OK")
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
