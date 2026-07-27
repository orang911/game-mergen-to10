extends SceneTree

var runner: BalanceSimulationRunner
var last_printed := -1


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var run_count := 1000
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--runs="):
			run_count = maxi(1, int(argument.trim_prefix("--runs=")))
	runner = BalanceSimulationRunner.new()
	root.add_child(runner)
	runner.progress_changed.connect(_on_progress)
	runner.simulation_completed.connect(_on_completed)
	runner.simulation_cancelled.connect(func(): print("ATTACK_SIMULATION_CANCELLED"); quit(2))
	runner.simulation_failed.connect(func(message: String): push_error(message); quit(1))
	var total := run_count * BalanceSimulationEngine.ATTACK_RULE_SCENARIOS.size() * BalanceSimulationEngine.STRATEGIES.size()
	print("ATTACK_SIMULATION_START runs_per_group=%d total=%d" % [run_count, total])
	if not runner.start_attack_rules(run_count):
		quit(1)


func _on_progress(completed: int, total: int) -> void:
	var percent := floori(float(completed) / float(maxi(1, total)) * 100.0)
	if percent >= last_printed + 10 or completed == total:
		last_printed = percent
		print("ATTACK_SIMULATION_PROGRESS %d/%d %d%%" % [completed, total, percent])


func _on_completed(result: Dictionary) -> void:
	print("ATTACK_SIMULATION_SUMMARY_PATH " + str(result.get("summary_path", "")))
	print("ATTACK_SIMULATION_RUNS_PATH " + str(result.get("runs_path", "")))
	for value in result.get("summary", []):
		var row := value as Dictionary
		if str(row.get("scenario", "")).begins_with("delta_"):
			continue
		print("ATTACK_SIMULATION_RESULT %s/%s win=%.2f%% wave_p50=%.1f theoretical=%.1f effective=%.1f overkill=%.1f kills=%.1f leaks=%.1f front_kill=%.3fs" % [
			str(row.get("scenario_name", "")),
			str(row.get("strategy_name", "")),
			float(row.get("win_rate", 0.0)) * 100.0,
			float(row.get("wave_p50", 0.0)),
			float(row.get("avg_theoretical_damage", 0.0)),
			float(row.get("avg_effective_damage", 0.0)),
			float(row.get("avg_overkill_damage", 0.0)),
			float(row.get("avg_killed", 0.0)),
			float(row.get("avg_leaked", 0.0)),
			float(row.get("avg_front_kill_time", 0.0)),
		])
	quit(0)
