extends Control
## Stand-alone review board for the N-shot presentation only.
## It uses ProjectileSystem's schedule helpers and the production MergeBolt;
## it does not duplicate combat, target selection, or damage logic.

const ELEMENTS := ["poison", "ice", "critical", "fire"]
const REVIEW_COUNTS := [2, 3, 4, 5, 6]
const BoltScene := preload("res://scenes/combat/projectile_view.tscn")
const ParticlesScript := preload("res://scripts/element_trail_particles.gd")

var _board: Control
var _info: Label
var _element_index := 0
var _count_index := 0
var _generation := 0
var _paused := false


func _ready() -> void:
	_build_ui()
	_play_review()
	_cycle_review()


func _cycle_review() -> void:
	# The board advances through N=2..6 automatically; the buttons remain useful
	# for freezing a particular element/count while comparing screenshots.
	while is_inside_tree():
		await get_tree().create_timer(2.4, false).timeout
		if not is_inside_tree():
			return
		_count_index = (_count_index + 1) % REVIEW_COUNTS.size()
		if _count_index == 0:
			_element_index = (_element_index + 1) % ELEMENTS.size()
		_play_review()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("101827")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	_board = Control.new()
	_board.name = "ProjectileBoard"
	_board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_board)

	var title := Label.new()
	title.text = "N-shot projectile review"
	title.position = Vector2(28, 18)
	title.add_theme_font_size_override("font_size", 28)
	add_child(title)
	_info = Label.new()
	_info.position = Vector2(30, 62)
	_info.add_theme_font_size_override("font_size", 16)
	add_child(_info)

	var element_button := Button.new()
	element_button.text = "Element"
	element_button.position = Vector2(720, 20)
	element_button.pressed.connect(func():
		_element_index = (_element_index + 1) % ELEMENTS.size()
		_play_review()
	)
	add_child(element_button)
	var count_button := Button.new()
	count_button.text = "N value"
	count_button.position = Vector2(820, 20)
	count_button.pressed.connect(func():
		_count_index = (_count_index + 1) % REVIEW_COUNTS.size()
		_play_review()
	)
	add_child(count_button)
	var pause_button := Button.new()
	pause_button.text = "Pause / resume"
	pause_button.position = Vector2(900, 20)
	pause_button.pressed.connect(func():
		_paused = not _paused
		get_tree().paused = _paused
	)
	add_child(pause_button)


func _play_review() -> void:
	_generation += 1
	for child in _board.get_children():
		child.queue_free()
	var element_key: String = ELEMENTS[_element_index]
	var shot_count: int = REVIEW_COUNTS[_count_index]
	var offsets: Array[String] = []
	for shot_index in range(shot_count):
		offsets.append("%.2f" % ProjectileSystem.get_multi_shot_launch_offset(shot_index, shot_count))
	var sample := BoltScene.instantiate() as MergeBolt
	var metrics: Dictionary = {}
	if sample:
		sample.apply_element_key(element_key, 1)
		sample.configure_sequence_presentation(0, shot_count)
		metrics = sample.get_sequence_presentation_metrics()
		sample.free()
	_info.text = "element=%s  N=%d  launch offsets=%s  core=%.2fx trail=%.2fx width=%.2fx" % [
		element_key,
		shot_count,
		", ".join(offsets),
		float(metrics.get("core_scale", 1.0)),
		float(metrics.get("trail_length_scale", 1.0)),
		float(metrics.get("trail_width_scale", 1.0)),
	]
	_spawn_sequence(element_key, shot_count, _generation)


func _spawn_sequence(element_key: String, shot_count: int, generation: int) -> void:
	var row_y := 180.0
	for shot_index in range(shot_count):
		var delay := ProjectileSystem.get_multi_shot_launch_offset(shot_index, shot_count)
		_spawn_review_shot(element_key, shot_index, shot_count, delay, row_y, generation)


func _spawn_review_shot(element_key: String, shot_index: int, shot_count: int, delay: float, row_y: float, generation: int) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay, false).timeout
	if generation != _generation:
		return
	var bolt := BoltScene.instantiate() as MergeBolt
	if bolt == null:
		return
	bolt.name = "Review_%s_%d" % [element_key, shot_index]
	bolt.apply_element_key(element_key, 1)
	bolt.configure_sequence_presentation(shot_index, shot_count)
	bolt.configure_trail_history(ProjectileSystem.MERGE_BOLT_DURATION, ProjectileSystem.ELEMENT_TRAIL_HISTORY_DURATION)
	bolt.start_pos = Vector2(170.0, row_y)
	bolt.end_pos = Vector2(920.0, row_y + 16.0)
	_board.add_child(bolt)
	var particles := ParticlesScript.new()
	particles.configure_sequence_presentation(shot_index, shot_count)
	_board.add_child(particles)
	particles.follow(bolt, element_key)
	var tween := bolt.create_tween()
	tween.tween_property(bolt, "progress", 1.0, ProjectileSystem.MERGE_BOLT_DURATION).set_trans(Tween.TRANS_LINEAR)
	tween.tween_interval(0.20)
	tween.tween_callback(bolt.queue_free)
	tween.tween_callback(particles.stop_emitting)
