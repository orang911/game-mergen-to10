extends SceneTree

var failures: Array[String] = []
var _save_path := ""
var _save_existed := false
var _save_backup := PackedByteArray()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_backup_live_save()
	var packed := load("res://scenes/main.tscn") as PackedScene
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.loading_view.stop_animations()
	game.loading_view.visible = false
	game.muted = true
	game._chapter_active = true
	game._campaign_mode = "chapter"
	game._first_wave_tutorial_completed = true
	game.game_status = game.GameStatus.START
	var waves := ChapterOneConfig.get_waves()

	# Every 1-1 through 1-3 wave uses the same normal random three-card offer
	# after its energy motes have completed.
	for wave_index in range(9):
		game.skill_imprint_system.reset()
		game.combat_system.start_run(false, 0.0, waves, wave_index)
		game.skill_imprint_system.add_energy(GameConfig.SKILL_ENERGY_MAX, Vector2.ZERO, 1, false)
		if wave_index == 0:
			await process_frame
			_check(not game.skill_imprint_system.is_choice_ready(), "energy choice must wait for its visual mote batch")
			_check(game.active_card_modal == null, "energy modal must not open before energy motes finish")
		game.skill_imprint_system.force_finish_fx()
		await process_frame
		_check(game.active_card_modal is ImprintChoiceModalV2, "eligible chapter wave %d must open a random imprint at full energy" % wave_index)
		if game.active_card_modal is ImprintChoiceModalV2:
			_check(game.active_card_modal._ids.size() == 3, "chapter wave %d must always offer exactly three imprints" % wave_index)
		await _discard_modal(game)

	# The forced opening tutorial is a temporary blocker, not a consumer of the
	# full-meter request. Its completion callback must immediately reconcile it.
	game.combat_system.start_run(false, 0.0, waves, 0)
	game.skill_imprint_system.reset()
	game._create_first_wave_tutorial()
	game._first_wave_tutorial.state = FirstWaveTutorialController.State.FIRST_MERGE
	game.skill_imprint_system.add_energy(GameConfig.SKILL_ENERGY_MAX, Vector2.ZERO, 1, false)
	game.skill_imprint_system.force_finish_fx()
	await process_frame
	_check(game.active_card_modal == null, "active first-wave teaching must defer the energy modal")
	game._on_first_wave_tutorial_finished(false)
	await process_frame
	await process_frame
	_check(game.active_card_modal is ImprintChoiceModalV2, "finishing first-wave teaching must recover the deferred energy modal")
	await _discard_modal(game)

	# A durable full meter survives every UI blocker and opens exactly once when
	# the final blocker clears.
	game.combat_system.start_run(false, 0.0, waves, 3)
	game.skill_imprint_system.reset()
	game._board_settlement_active = true
	game.skill_imprint_system.add_energy(GameConfig.SKILL_ENERGY_MAX, Vector2.ZERO, 1, false)
	game.skill_imprint_system.force_finish_fx()
	await process_frame
	_check(game.active_card_modal == null, "board settlement must defer the energy modal")
	_check(game._skill_choice_pending, "a blocked full-meter request must remain pending")
	game._success_popup_active = true
	game._chapter_transition_active = true
	game._manual_paused = true
	game._board_settlement_active = false
	game._reconcile_energy_imprint_choice()
	_check(game.active_card_modal == null, "remaining popup and pause blockers must keep the request deferred")
	game._success_popup_active = false
	game._chapter_transition_active = false
	game._manual_paused = false
	game._reconcile_energy_imprint_choice()
	game._reconcile_energy_imprint_choice()
	await process_frame
	_check(game.active_card_modal is ImprintChoiceModalV2, "clearing all blockers must recover the deferred energy modal")
	_check(game.modal_layer.get_child_count() == 1, "repeated reconciliation must not open duplicate energy modals")
	await _discard_modal(game)

	# A different card modal owns the screen first; closing it must hand the
	# durable request back to the energy route without requiring another gain.
	game.skill_imprint_system.reset()
	var blocking_modal := Control.new()
	game.modal_layer.add_child(blocking_modal)
	game.active_card_modal = blocking_modal
	game.skill_imprint_system.add_energy(GameConfig.SKILL_ENERGY_MAX, Vector2.ZERO, 1, false)
	game.skill_imprint_system.force_finish_fx()
	await process_frame
	_check(game.active_card_modal == blocking_modal and game._skill_choice_pending, "another card modal must defer but preserve the energy request")
	blocking_modal.queue_free()
	game._on_card_modal_closed("milestone")
	await process_frame
	await process_frame
	_check(game.active_card_modal is ImprintChoiceModalV2, "closing another card modal must recover the energy choice")
	await _discard_modal(game)

	# Save restoration intentionally drops transient request flags; reconciliation
	# must derive the request again from the restored full meter.
	game.skill_imprint_system.restore_state({"energy": GameConfig.SKILL_ENERGY_MAX, "pending_skill": {}})
	game._skill_choice_pending = false
	game._reconcile_energy_imprint_choice()
	await process_frame
	_check(game.active_card_modal is ImprintChoiceModalV2, "restoring full energy in an eligible wave must recreate the choice request")
	await _discard_modal(game)

	# A full meter carried out of 1-3 becomes eligible as soon as 1-4 starts.
	game.combat_system.start_run(false, 0.0, waves, 9)
	await process_frame
	_check(game.active_card_modal is ImprintChoiceModalV2, "entering 1-4 with full energy must open the deferred random imprint")
	await _commit_and_close_modal(game)

	# Exercise guards, mini-boss and final boss with the same full-energy route.
	for wave_index in [9, 10, 11]:
		game.combat_system.start_run(false, 0.0, waves, wave_index)
		game.skill_imprint_system.reset()
		game.game_status = game.GameStatus.START
		await _wait_seconds(0.12)
		var boss: Monster = null
		for monster in game.combat_system.monster_system.get_alive_monsters():
			if monster.is_boss:
				boss = monster
				break
		var boss_hp := boss.hp if boss else 0.0
		var boss_position := boss.position if boss else Vector2.ZERO
		var boss_progress := boss.path_progress if boss else 0.0

		game.skill_imprint_system.add_energy(GameConfig.SKILL_ENERGY_MAX, Vector2.ZERO, 1, false)
		game.skill_imprint_system.force_finish_fx()
		await process_frame
		_check(game.active_card_modal is ImprintChoiceModalV2, "enabled chapter wave %d must open a random imprint" % wave_index)
		_check(paused, "energy imprint modal must pause guards and boss combat")
		var frozen_wave_state: Dictionary = game.combat_system.wave_system.export_state()
		await _wait_seconds(0.20)
		_check(JSON.stringify(game.combat_system.wave_system.export_state()) == JSON.stringify(frozen_wave_state), "wave spawning must remain frozen while the imprint modal is open")
		if boss:
			_check(is_equal_approx(boss.hp, boss_hp), "boss HP must remain unchanged while choosing an imprint")
			_check(boss.position.is_equal_approx(boss_position) and is_equal_approx(boss.path_progress, boss_progress), "boss position must remain unchanged while choosing an imprint")

		await _commit_and_close_modal(game)
		_check(game.skill_imprint_system.energy == 0, "choosing an energy imprint must reset energy")
		_check(game.skill_imprint_system.has_pending_skill(), "chosen imprint must enter the next-merge pending slot")
		_check(not paused, "closing the imprint modal must resume the boss battle")
		if boss and is_instance_valid(boss):
			_check(is_equal_approx(boss.hp, boss_hp), "resuming must preserve the boss HP from before the modal")

	# A pending imprint blocks another modal. Consuming it rechecks a still-full
	# meter against the current enabled wave and opens exactly one new choice.
	game.combat_system.start_run(false, 0.0, waves, 10)
	game.skill_imprint_system.reset()
	game.skill_imprint_system.choose_skill("ascension_hammer", 1)
	game.skill_imprint_system.add_energy(GameConfig.SKILL_ENERGY_MAX, Vector2.ZERO, 1, false)
	game.skill_imprint_system.force_finish_fx()
	await process_frame
	_check(game.active_card_modal == null, "a pending imprint must block a second random choice")
	game.skill_imprint_system.consume_pending_skill()
	await process_frame
	_check(game.active_card_modal is ImprintChoiceModalV2, "consuming the pending imprint at full energy must request the next allowed choice")
	await _discard_modal(game)

	game.queue_free()
	await process_frame
	_restore_live_save()
	if failures.is_empty():
		print("CHAPTER_ENERGY_IMPRINT_SMOKE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _commit_and_close_modal(game) -> void:
	if game.active_card_modal == null:
		return
	game._on_card_choice_committed("energy", "ascension_hammer", "", 1)
	await _discard_modal(game)


func _discard_modal(game) -> void:
	var modal: Node = game.active_card_modal as Node
	paused = false
	game.active_card_modal = null
	if modal and is_instance_valid(modal):
		modal.queue_free()
	await process_frame


func _backup_live_save() -> void:
	_save_path = ProjectSettings.globalize_path(GameConfig.SAVE_PATH)
	_save_existed = FileAccess.file_exists(_save_path)
	if _save_existed:
		_save_backup = FileAccess.get_file_as_bytes(_save_path)


func _restore_live_save() -> void:
	if _save_existed:
		var file := FileAccess.open(_save_path, FileAccess.WRITE)
		if file:
			file.store_buffer(_save_backup)
	elif FileAccess.file_exists(_save_path):
		DirAccess.remove_absolute(_save_path)


func _wait_seconds(seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
