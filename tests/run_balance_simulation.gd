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
	runner.simulation_cancelled.connect(func(): print("BALANCE_SIMULATION_CANCELLED"); quit(2))
	runner.simulation_failed.connect(func(message: String): push_error(message); quit(1))
	print("BALANCE_SIMULATION_START runs_per_group=%d total=%d" % [run_count, run_count * BalanceSimulationEngine.SCENARIOS.size() * BalanceSimulationEngine.STRATEGIES.size()])
	if not runner.start_standard(run_count):
		quit(1)

func _on_progress(completed: int, total: int) -> void:
	var percent := floori(float(completed) / float(maxi(1, total)) * 100.0)
	if percent >= last_printed + 5 or completed == total:
		last_printed = percent
		print("BALANCE_SIMULATION_PROGRESS %d/%d %d%%" % [completed, total, percent])

func _on_completed(result: Dictionary) -> void:
	print("BALANCE_SIMULATION_SUMMARY_PATH " + str(result.get("summary_path", "")))
	print("BALANCE_SIMULATION_RUNS_PATH " + str(result.get("runs_path", "")))
	for value in result.get("summary", []):
		var row := value as Dictionary
		if str(row.get("scenario", "")).begins_with("delta_"):
			continue
		print("BALANCE_SIMULATION_RESULT %s/%s win=%.2f%% stall=%.2f%% wave_p50=%.1f highest_p50=%.1f one=%.2f%% damage=%.1f" % [
			str(row.get("scenario_name", "")),
			str(row.get("strategy_name", "")),
			float(row.get("win_rate", 0.0)) * 100.0,
			float(row.get("stall_rate", 0.0)) * 100.0,
			float(row.get("wave_p50", 0.0)),
			float(row.get("highest_p50", 0.0)),
			float(row.get("generated_one_rate", 0.0)) * 100.0,
			float(row.get("avg_total_damage", 0.0)),
		])
	quit(0)
