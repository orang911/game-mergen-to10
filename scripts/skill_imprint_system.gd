extends Node
class_name SkillImprintSystem

signal energy_changed(current: int, maximum: int)
signal energy_gain_requested(amount: int, source_global: Vector2, mote_count: int, bright: bool)
signal skill_choice_requested
signal pending_skill_changed(skill_id: String, quality: int)

var energy := 0
var pending_skills: Array[Dictionary] = []
var _pending_fx_batches := 0
var _choice_requested := false


func reset() -> void:
	energy = 0
	pending_skills.clear()
	_pending_fx_batches = 0
	_choice_requested = false
	energy_changed.emit(energy, GameConfig.SKILL_ENERGY_MAX)
	pending_skill_changed.emit("", 0)


func add_energy(amount: int, source_global: Vector2, mote_count: int = 1, bright: bool = false) -> void:
	if amount <= 0 or energy >= GameConfig.SKILL_ENERGY_MAX:
		return
	var previous := energy
	energy = mini(GameConfig.SKILL_ENERGY_MAX, energy + amount)
	var gained := energy - previous
	# 重叠的得能量表现由 HUD 在全部光点抵达后统一回报一次。
	_pending_fx_batches = 1
	# 先创建光点，再同步逻辑值，使 HUD 的显示数值只在光点抵达时追赶。
	energy_gain_requested.emit(gained, source_global, maxi(1, mote_count), bright)
	energy_changed.emit(energy, GameConfig.SKILL_ENERGY_MAX)
	if energy >= GameConfig.SKILL_ENERGY_MAX:
		_choice_requested = true


func notify_fx_batch_finished() -> void:
	_pending_fx_batches = 0
	_try_request_choice()


func force_finish_fx() -> void:
	_pending_fx_batches = 0
	_try_request_choice()


func choose_skill(skill_id: String, quality: int = 1) -> void:
	if not GameConfig.SKILL_CARD_IDS.has(skill_id):
		return
	pending_skills.append({"id": skill_id, "quality": clampi(quality, 1, GameConfig.MAX_CARD_LEVEL)})
	energy = 0
	_choice_requested = false
	energy_changed.emit(energy, GameConfig.SKILL_ENERGY_MAX)
	_emit_pending_changed()


func enqueue_skill(skill_id: String, quality: int = 1) -> void:
	if not GameConfig.SKILL_CARD_IDS.has(skill_id):
		return
	pending_skills.append({"id": skill_id, "quality": clampi(quality, 1, GameConfig.MAX_CARD_LEVEL)})
	_emit_pending_changed()


func resolve_energy_without_skill() -> void:
	energy = 0
	_choice_requested = false
	energy_changed.emit(energy, GameConfig.SKILL_ENERGY_MAX)


func consume_pending_skill() -> Dictionary:
	if pending_skills.is_empty():
		return {}
	var result: Dictionary = pending_skills.pop_front()
	_emit_pending_changed()
	return result


func has_pending_skill() -> bool:
	return not pending_skills.is_empty()


func is_full_waiting_for_choice() -> bool:
	return energy >= GameConfig.SKILL_ENERGY_MAX


func _try_request_choice() -> void:
	if _choice_requested and _pending_fx_batches <= 0:
		_choice_requested = false
		skill_choice_requested.emit()


func _emit_pending_changed() -> void:
	if pending_skills.is_empty():
		pending_skill_changed.emit("", 0)
		return
	var first: Dictionary = pending_skills[0]
	pending_skill_changed.emit(str(first.get("id", "")), int(first.get("quality", 1)))
