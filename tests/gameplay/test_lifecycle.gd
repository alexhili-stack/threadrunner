extends GdUnitTestSuite

var room: LevelRoot
var run: RunController


func before_test() -> void:
	room = load(LevelCatalog.scene_path(12)).instantiate()
	get_tree().root.add_child(room)
	room.player.synthetic = true
	run = RunController.new()
	get_tree().root.add_child(run)
	run.begin(room)


func after_test() -> void:
	run.free()
	room.free()


func steps(count: int) -> void:
	for frame in count:
		await get_tree().physics_frame


func test_death_is_counted_once_and_restart_safe() -> void:
	run.die()
	run.die()
	assert_int(run.deaths).is_equal(1)
	assert_bool(room.player.active).is_false()
	run.restart()
	await steps(12)
	assert_int(run.state).is_equal(RunController.State.PLAYING)
	assert_int(run.deaths).is_equal(1)


func test_completion_is_terminal_and_single() -> void:
	run.complete()
	var finished: float = run.attempt_time
	run.complete()
	run.die()
	await steps(8)
	assert_int(run.state).is_equal(RunController.State.COMPLETED)
	assert_int(run.deaths).is_equal(0)
	assert_float(run.attempt_time).is_equal(finished)


func test_pause_freezes_time_hazards_and_player() -> void:
	await steps(5)
	run.set_paused(true)
	var clock: float = run.attempt_time
	var point: Vector2 = room.player.position
	var phase: float = room.elapsed
	await steps(20)
	assert_float(run.attempt_time).is_equal(clock)
	assert_float(room.elapsed).is_equal(phase)
	assert_vector(room.player.position).is_equal(point)
	run.set_paused(false)
	await steps(2)
	assert_float(run.attempt_time - clock).is_less(0.06)


func test_full_attempt_reset_and_fragment_policy() -> void:
	room.fragment_collected = true
	room.elapsed = 1.7
	room.player.velocity = Vector2(200, -400)
	run.die()
	await steps(10)
	assert_bool(room.fragment_collected).is_false()
	assert_bool(room.gate_is_open()).is_true()
	assert_float(run.attempt_time).is_less(0.08)
	assert_float(room.player.position.distance_to(room.spawn)).is_less(2)


func test_lethal_contact_wins_over_exit() -> void:
	room.exit_position = room.spawn
	room.spikes = [Rect2(room.spawn - Vector2(10, 10), Vector2(20, 20))]
	await steps(2)
	assert_int(run.state).is_equal(RunController.State.DYING)


func test_reset_stress_500_cycles() -> void:
	await steps(5)
	var nodes: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var orphans: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	for cycle in 500:
		run.die()
		while run.state == RunController.State.DYING:
			await steps(1)
		assert_int(run.state).is_equal(RunController.State.PLAYING)
	assert_int(run.deaths).is_equal(500)
	assert_int(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))).is_less_equal(nodes)
	assert_int(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))).is_equal(orphans)
	assert_int(run.reset_latencies.size()).is_equal(500)
	var samples: Array[float] = run.reset_latencies.duplicate()
	samples.sort()
	assert_float(samples[-1]).is_less_equal(250)
	var output: FileAccess = FileAccess.open("res://artifacts/reset_metrics.json", FileAccess.WRITE)
	output.store_string(
		JSON.stringify(
			{
				"samples": 500,
				"median_ms": samples[250],
				"worst_ms": samples[-1],
				"nodes": nodes,
				"orphans": orphans
			}
		)
	)
	output.close()
