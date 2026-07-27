extends Node
class_name FirstWaveTutorialController

signal awakening_committed
signal instant_items_locked(locked: bool)
signal finished(skipped: bool)

const TutorialViewScript := preload("res://scripts/first_wave_tutorial_view.gd")
const FIRST_GROUP: Array[Vector2i] = [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)]

enum State {
	IDLE,
	FIRST_MERGE,
	BASIC_MONSTERS,
	BREAKTHROUGH,
	CORE_REWARD,
	AWAKENING,
	FIRST_STRIKE,
	COMPLETED,
}

var state := State.IDLE
var _combat_system: CombatSystem
var _view: FirstWaveTutorialView
var _host: Control
var _board_rect := Rect2()
var _highlight_rect := Rect2()
var _crystal_anchor := Vector2.ZERO
var _generation := 0
var _finishing := false


func setup(combat_system: CombatSystem, host: Control, board_rect: Rect2, highlight_rect: Rect2, crystal_anchor: Vector2) -> void:
	_combat_system = combat_system
	_host = host
	_board_rect = board_rect
	_highlight_rect = highlight_rect
	_crystal_anchor = crystal_anchor
	_combat_system.tutorial_basic_progress.connect(_on_basic_progress)
	_combat_system.tutorial_breakthrough_reached.connect(_on_breakthrough_reached)
	_combat_system.tutorial_first_strike_finished.connect(_on_first_strike_finished)


func start() -> void:
	_generation += 1
	_finishing = false
	state = State.FIRST_MERGE
	_view = TutorialViewScript.new() as FirstWaveTutorialView
	_host.add_child(_view)
	_view.setup(_board_rect, _highlight_rect, _crystal_anchor)
	_view.skip_pressed.connect(_on_skip_pressed)
	_view.awakening_core_pressed.connect(_on_awakening_core_pressed)
	_view.show_first_merge_guide()
	instant_items_locked.emit(true)


func stop() -> void:
	_generation += 1
	_finishing = true
	state = State.IDLE
	if _view and is_instance_valid(_view):
		_view.cleanup()
	_view = null
	instant_items_locked.emit(false)


func is_active() -> bool:
	return state != State.IDLE and state != State.COMPLETED and not _finishing


func can_interact_with_site(site: Vector2i) -> bool:
	match state:
		State.FIRST_MERGE:
			return FIRST_GROUP.has(site)
		State.BASIC_MONSTERS:
			return true
		_:
			return false


func notify_merge_completed() -> void:
	if state != State.FIRST_MERGE:
		return
	state = State.BASIC_MONSTERS
	if _view:
		_view.show_basic_progress(0, CombatSystem.TUTORIAL_BASIC_COUNT)


func _on_basic_progress(killed: int, total: int) -> void:
	if not is_active() or state > State.BASIC_MONSTERS:
		return
	if _view:
		_view.show_basic_progress(killed, total)


func _on_breakthrough_reached(_monster: Monster) -> void:
	if not is_active() or state == State.BREAKTHROUGH:
		return
	state = State.BREAKTHROUGH
	var sequence_generation := _generation
	if _view:
		_view.show_breakthrough_primary()
	await get_tree().create_timer(1.05).timeout
	if sequence_generation != _generation or state != State.BREAKTHROUGH:
		return
	if _view:
		_view.show_breakthrough_secondary()
	await get_tree().create_timer(1.05).timeout
	if sequence_generation != _generation or state != State.BREAKTHROUGH:
		return
	state = State.CORE_REWARD
	if _view:
		_view.show_core_reward()


func _on_awakening_core_pressed() -> void:
	if state != State.CORE_REWARD or _finishing:
		return
	state = State.AWAKENING
	var sequence_generation := _generation
	if _view:
		await _view.play_core_fly()
	if sequence_generation != _generation or state != State.AWAKENING:
		return
	_combat_system.awaken_tutorial_crystal()
	awakening_committed.emit()
	if _view:
		_view.show_awakened()
	await get_tree().create_timer(0.62).timeout
	if sequence_generation != _generation or state != State.AWAKENING:
		return
	state = State.FIRST_STRIKE
	_combat_system.play_tutorial_first_strike()


func _on_first_strike_finished() -> void:
	if state != State.FIRST_STRIKE or _finishing:
		return
	state = State.COMPLETED
	var sequence_generation := _generation
	if _view:
		_view.show_final_message()
	await get_tree().create_timer(2.2).timeout
	if sequence_generation != _generation or _finishing:
		return
	_finishing = true
	instant_items_locked.emit(false)
	if _view and is_instance_valid(_view):
		_view.cleanup()
	_view = null
	_combat_system.complete_tutorial_first_wave()
	finished.emit(false)


func _on_skip_pressed() -> void:
	if not is_active() or _finishing:
		return
	_generation += 1
	_finishing = true
	state = State.COMPLETED
	awakening_committed.emit()
	instant_items_locked.emit(false)
	if _view and is_instance_valid(_view):
		_view.cleanup()
	_view = null
	_combat_system.skip_tutorial_first_wave()
	finished.emit(true)
