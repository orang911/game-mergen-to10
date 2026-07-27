extends SceneTree

var _choice_count := 0
var _pending_id := ""
var _failed := false


func _init() -> void:
	var system := SkillImprintSystem.new()
	root.add_child(system)
	system.skill_choice_requested.connect(func(): _choice_count += 1)
	system.pending_skill_changed.connect(func(skill_id: String, _quality: int): _pending_id = skill_id)
	_check(GameConfig.SKILL_IMPRINT_IDS.size() == 6, "runtime imprint pool should contain the six active imprints")
	_check(not GameConfig.SKILL_IMPRINT_IDS.has("frost_bell"), "frost imprint must stay out of the runtime pool")
	_check(not GameConfig.SKILL_IMPRINT_IDS.has("thunder_ballista"), "lightning imprint must stay out of the runtime pool")

	system.add_energy(GameConfig.SKILL_ENERGY_MAX, Vector2.ZERO, 1, false)
	system.force_finish_fx()
	_check(_choice_count == 1, "full energy should request one imprint choice")
	_check(system.is_full_waiting_for_choice(), "full energy should wait for imprint choice")

	system.choose_skill("ascension_hammer", 1)
	_check(system.has_pending_skill(), "chosen imprint should occupy the next-merge slot")
	_check(_pending_id == "ascension_hammer", "HUD signal should expose the pending imprint")
	_check(system.energy == 0, "choosing an imprint should reset energy")

	system.add_energy(GameConfig.SKILL_ENERGY_MAX, Vector2.ZERO, 1, false)
	system.force_finish_fx()
	_check(_choice_count == 1, "a pending imprint must block a second choice modal")

	var consumed := system.consume_pending_skill()
	_check(str(consumed.get("id", "")) == "ascension_hammer", "valid merge should consume the prepared imprint")
	_check(not system.has_pending_skill(), "the next-merge slot should clear after consumption")
	_check(_choice_count == 2, "a full refilled meter may request the next choice after consumption")

	system.queue_free()
	if not _failed:
		print("SKILL_IMPRINT_FLOW_SMOKE_OK")
	quit(1 if _failed else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
