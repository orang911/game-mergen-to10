extends SceneTree

var runner: BalanceSimulationRunner
var last_printed := -1


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var run_count := 1000
	var merge_limit := 500
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--runs="):
			run_count = maxi(1, int(argument.trim_prefix("--runs=")))
		elif argument.begins_with("--merges="):
			merge_limit = maxi(1, int(argument.trim_prefix("--merges=")))
	runner = BalanceSimulationRunner.new()
	root.add_child(runner)
	runner.progress_changed.connect(_on_progress)
	runner.simulation_completed.connect(_on_completed)
	runner.simulation_cancelled.connect(func(): print("BOARD_SIMULATION_CANCELLED"); quit(2))
	runner.simulation_failed.connect(func(message: String): push_error(message); quit(1))
	var total := run_count * BalanceSimulationEngine.BOARD_SCENARIOS.size() * BalanceSimulationEngine.STRATEGIES.size()
	print("BOARD_SIMULATION_START runs_per_group=%d merges=%d total=%d" % [run_count, merge_limit, total])
	if not runner.start_board_progression(run_count, merge_limit):
		quit(1)


func _on_progress(completed: int, total: int) -> void:
	var percent := floori(float(completed) / float(maxi(1, total)) * 100.0)
	if percent >= last_printed + 5 or completed == total:
		last_printed = percent
		print("BOARD_SIMULATION_PROGRESS %d/%d %d%%" % [completed, total, percent])


func _on_completed(result: Dictionary) -> void:
	print("BOARD_SIMULATION_SUMMARY_PATH " + str(result.get("summary_path", "")))
	print("BOARD_SIMULATION_RUNS_PATH " + str(result.get("runs_path", "")))
	for value in result.get("summary", []):
		var row := value as Dictionary
		print("BOARD_SIMULATION_RESULT %s/%s complete=%.1f%% stall=%.1f%% merges=%.1f high_p50=%.1f reach_10=%.1f%% reach_A=%.1f%% reach_B=%.1f%% reach_E=%.1f%% reach_J=%.1f%% reach_P=%.1f%% reach_Z=%.1f%%" % [
			str(row.get("scenario_name", "")),
			str(row.get("strategy_name", "")),
			float(row.get("completion_rate", 0.0)) * 100.0,
			float(row.get("stall_rate", 0.0)) * 100.0,
			float(row.get("avg_merges", 0.0)),
			float(row.get("highest_p50", 0.0)),
			float(row.get("reach_10_rate", 0.0)) * 100.0,
			float(row.get("reach_11_rate", 0.0)) * 100.0,
			float(row.get("reach_12_rate", 0.0)) * 100.0,
			float(row.get("reach_15_rate", 0.0)) * 100.0,
			float(row.get("reach_20_rate", 0.0)) * 100.0,
			float(row.get("reach_26_rate", 0.0)) * 100.0,
			float(row.get("reach_36_rate", 0.0)) * 100.0,
		])
	quit(0)
