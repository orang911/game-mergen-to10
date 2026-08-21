extends SceneTree

var _failed := false


func _init() -> void:
	var waves := ChapterOneConfig.get_waves()
	_check(waves.size() == ChapterOneConfig.CHAPTER_WAVE_COUNT + ChapterOneConfig.CONTINUATION_WAVE_COUNT, "chapter one should retain the 20-wave continuation after its twelve authored waves")
	_check(str((waves[0] as Dictionary).get("node_id", "")) == "1-1", "chapter should begin at 1-1")
	_check(bool((waves[10] as Dictionary).get("is_boss", false)), "wave 11 should be the small boss")
	_check(str((waves[10] as Dictionary).get("chapter_reward", "")) == "crystal_choice", "small boss should open the complete three-card crystal choice")
	_check(bool((waves[11] as Dictionary).get("is_boss", false)), "final wave should be the big boss")
	_check(bool((waves[11] as Dictionary).get("chapter_final", false)), "final boss should finish chapter one")
	for index in range(3):
		_check(bool((waves[index] as Dictionary).get("allow_random_energy_imprint", false)), "1-1 must enable random energy imprints after the forced tutorial releases control")
	for index in range(3, 6):
		_check(bool((waves[index] as Dictionary).get("allow_random_energy_imprint", false)), "all 1-2 waves must enable random energy imprints")
	for index in range(6, 9):
		_check(bool((waves[index] as Dictionary).get("allow_random_energy_imprint", false)), "every 1-3 wave must use the normal random three-card energy offer")
		_check(not (waves[index] as Dictionary).has("chapter_imprint_offer"), "1-3 must not retain fixed one-card or two-card offer branches")
	for index in range(9, 12):
		_check(bool((waves[index] as Dictionary).get("allow_random_energy_imprint", false)), "1-4 guards and both boss waves must enable random energy imprints")
	_check(bool((waves[12] as Dictionary).get("continuation", false)), "the first legacy wave should follow the chapter as continuation content")
	_check(str((waves[12] as Dictionary).get("display_label", "")) == "续战 01", "continuation waves should have their own HUD label")
	var mini_sequence := (waves[10] as Dictionary).get("spawn_sequence", []) as Array
	var final_sequence := (waves[11] as Dictionary).get("spawn_sequence", []) as Array
	_check(mini_sequence.size() == 3 and str((mini_sequence[0] as Dictionary).get("monster_type", "")) == "large", "small boss must spawn before its guards")
	_check(final_sequence.size() == 4 and str((final_sequence[0] as Dictionary).get("monster_type", "")) == "large", "big boss must spawn before its guards")
	quit(1 if _failed else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
