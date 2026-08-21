extends Control
class_name LoadingView

signal loading_completed
signal clear_local_data_requested

const DESIGN_SIZE := Vector2(941.0, 1672.0)
const LOADING_DURATION := 2.5
const FADE_DURATION := 0.18

@onready var _design_root := get_node_or_null("DesignRoot") as Control
@onready var _progress_clip := get_node_or_null("DesignRoot/ProgressBar/FillClip") as Control
@onready var _percent_label := get_node_or_null("DesignRoot/ProgressBar/PercentLabel") as Label
@onready var _clear_data_button := get_node_or_null("DesignRoot/ClearLocalDataButton") as Button
@onready var _clear_confirm := get_node_or_null("ClearLocalDataConfirm") as ConfirmationDialog

var _elapsed := 0.0
var _loading := false
var _paused := false
var _completion_emitted := false
var _fade_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	if _clear_data_button and not _clear_data_button.pressed.is_connected(_show_clear_confirmation):
		_clear_data_button.pressed.connect(_show_clear_confirmation)
	if _clear_confirm:
		if not _clear_confirm.confirmed.is_connected(_on_clear_confirmed):
			_clear_confirm.confirmed.connect(_on_clear_confirmed)
		if not _clear_confirm.canceled.is_connected(_on_clear_canceled):
			_clear_confirm.canceled.connect(_on_clear_canceled)
	_update_progress(0.0)
	if size.x > 0.0 and size.y > 0.0:
		layout_for_viewport(size)


func _process(delta: float) -> void:
	if not _loading or _paused or _completion_emitted:
		return
	_elapsed = minf(_elapsed + delta, LOADING_DURATION)
	_update_progress(_progress_for_elapsed(_elapsed))
	if _elapsed >= LOADING_DURATION:
		_finish_loading()


func layout_for_viewport(viewport_size: Vector2) -> void:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0 or _design_root == null:
		return
	# Keep all controls inside the viewport while the independent background
	# uses cover scaling to remain full bleed on tall and narrow screens.
	var scale_factor := minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	_design_root.position = (viewport_size - DESIGN_SIZE * scale_factor) * 0.5
	_design_root.size = DESIGN_SIZE
	_design_root.scale = Vector2.ONE * scale_factor


func begin_loading() -> void:
	_restart_state()


func pause_loading() -> void:
	if _loading and not _completion_emitted:
		_paused = true


func resume_loading() -> void:
	if _loading and not _completion_emitted:
		_paused = false


func restart_loading() -> void:
	_restart_state()


func stop_animations() -> void:
	_loading = false
	_paused = false
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null
	modulate = Color.WHITE


func _restart_state() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null
	_elapsed = 0.0
	_loading = true
	_paused = false
	_completion_emitted = false
	visible = true
	modulate = Color.WHITE
	_update_progress(0.0)


func _progress_for_elapsed(seconds: float) -> float:
	if seconds <= 1.75:
		return lerpf(0.0, 85.0, seconds / 1.75)
	if seconds <= 2.25:
		return lerpf(85.0, 95.0, (seconds - 1.75) / 0.5)
	return lerpf(95.0, 100.0, (seconds - 2.25) / 0.25)


func _update_progress(percent: float) -> void:
	var clamped := clampf(percent, 0.0, 100.0)
	if _progress_clip:
		_progress_clip.size.x = 576.0 * clamped / 100.0
	if _percent_label:
		_percent_label.text = "%d%%" % int(round(clamped))


func _finish_loading() -> void:
	if _completion_emitted:
		return
	_completion_emitted = true
	_loading = false
	_update_progress(100.0)
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_fade_tween.tween_callback(func(): loading_completed.emit())


func _show_clear_confirmation() -> void:
	if _clear_confirm == null or _completion_emitted:
		return
	pause_loading()
	_clear_confirm.popup_centered()


func _on_clear_confirmed() -> void:
	clear_local_data_requested.emit()


func _on_clear_canceled() -> void:
	resume_loading()


func _exit_tree() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
