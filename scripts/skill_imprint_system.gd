extends Node
class_name SkillImprintSystem

signal energy_changed(current: int, maximum: int)
signal energy_gain_requested(amount: int, source_global: Vector2, mote_count: int, bright: bool)
signal skill_choice_requested
signal pending_skill_changed(skill_id: String, quality: int)

var energy := 0
## A board imprint is prepared for one future valid merge only.  Keep one
## dictionary instead of a queue so the HUD and the rules always describe the
## same single "next merge" slot.
var pending_skill: Dictionary = {}
var _pending_fx_batches := 0
var _choice_requested := false

const IMPRINT_NAMES := {
	"ascension_hammer": "星阶铸锤",
	"unity_dial": "万象数盘",
	"twin_mold": "双生晶模",
	"fate_shuffler": "命运魔箱",
	"castle_cannon": "王城魔炮",
	"dragon_catapult": "龙焰投石",
}


func reset() -> void:
	energy = 0
	pending_skill.clear()
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
	if energy >= GameConfig.SKILL_ENERGY_MAX and not has_pending_skill():
		_choice_requested = true


func notify_fx_batch_finished() -> void:
	_pending_fx_batches = 0
	_try_request_choice()


func force_finish_fx() -> void:
	_pending_fx_batches = 0
	_try_request_choice()


func request_choice_if_full() -> void:
	# A chapter wave may unlock random offers while the meter is already full
	# from an earlier authored teaching wave. Preserve the single pending slot
	# rule and let any in-flight energy motes finish before raising the request.
	if energy < GameConfig.SKILL_ENERGY_MAX or has_pending_skill():
		return
	_choice_requested = true
	_try_request_choice()


func choose_skill(skill_id: String, quality: int = 1) -> void:
	if not GameConfig.SKILL_IMPRINT_IDS.has(skill_id) or has_pending_skill():
		return
	pending_skill = {
		"id": skill_id,
		"quality": clampi(quality, 1, GameConfig.MAX_CARD_LEVEL),
	}
	energy = 0
	_choice_requested = false
	energy_changed.emit(energy, GameConfig.SKILL_ENERGY_MAX)
	_emit_pending_changed()


func enqueue_skill(skill_id: String, quality: int = 1) -> void:
	if not GameConfig.SKILL_IMPRINT_IDS.has(skill_id) or has_pending_skill():
		return
	pending_skill = {
		"id": skill_id,
		"quality": clampi(quality, 1, GameConfig.MAX_CARD_LEVEL),
	}
	_emit_pending_changed()


func resolve_energy_without_skill() -> void:
	energy = 0
	_choice_requested = false
	energy_changed.emit(energy, GameConfig.SKILL_ENERGY_MAX)


func consume_pending_skill() -> Dictionary:
	if pending_skill.is_empty():
		return {}
	var result := pending_skill.duplicate(true)
	pending_skill.clear()
	_emit_pending_changed()
	# Energy can refill while an imprint is waiting.  Defer the next choice
	# until this imprint has actually triggered, so a second slot never opens.
	if energy >= GameConfig.SKILL_ENERGY_MAX:
		_choice_requested = true
		_try_request_choice()
	return result


func has_pending_skill() -> bool:
	return not pending_skill.is_empty()


func peek_pending_skill() -> Dictionary:
	return pending_skill.duplicate(true)


func export_state() -> Dictionary:
	return {
		"energy": energy,
		"pending_skill": pending_skill.duplicate(true),
	}


func restore_state(state: Dictionary) -> void:
	energy = clampi(int(state.get("energy", 0)), 0, GameConfig.SKILL_ENERGY_MAX)
	pending_skill = (state.get("pending_skill", {}) as Dictionary).duplicate(true)
	_pending_fx_batches = 0
	_choice_requested = false
	energy_changed.emit(energy, GameConfig.SKILL_ENERGY_MAX)
	_emit_pending_changed()


func get_imprint_name(skill_id: String) -> String:
	return str(IMPRINT_NAMES.get(skill_id, skill_id))


func is_full_waiting_for_choice() -> bool:
	return energy >= GameConfig.SKILL_ENERGY_MAX and not has_pending_skill()


func is_choice_ready() -> bool:
	# This is deliberately derived from durable gameplay state.  Callers may
	# query it again after tutorials, popups or save restoration without relying
	# on the one-shot notification that first observed a full meter.
	return is_full_waiting_for_choice() and _pending_fx_batches <= 0


func _try_request_choice() -> void:
	if _choice_requested and _pending_fx_batches <= 0:
		_choice_requested = false
		skill_choice_requested.emit()


func _emit_pending_changed() -> void:
	if pending_skill.is_empty():
		pending_skill_changed.emit("", 0)
		return
	pending_skill_changed.emit(str(pending_skill.get("id", "")), int(pending_skill.get("quality", 1)))
