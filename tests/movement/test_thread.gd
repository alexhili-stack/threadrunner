extends GdUnitTestSuite

var room: LevelRoot
var run: RunController


func before_test() -> void:
	InputService.new().configure()
	_load_room(40)
	await _steps(6)


func _load_room(index: int, wall: bool = false) -> void:
	if is_instance_valid(run):
		run.free()
	if is_instance_valid(room):
		room.free()
	room = LevelCatalog.entry(index).scene.instantiate()
	if wall:
		room.platforms.append(Rect2(240, 160, 16, 140))
	get_tree().root.add_child(room)
	room.player.synthetic = true
	run = RunController.new()
	get_tree().root.add_child(run)
	run.begin(room)


func after_test() -> void:
	run.free()
	room.free()


func _steps(count: int) -> void:
	for tick in count:
		await get_tree().physics_frame


func test_stitch_requires_a_nearby_terminal() -> void:
	room.player.drive_tools(true)
	await _steps(2)
	assert_bool(room.thread_tool.relay_powered()).is_false()
	assert_bool(room.thread_tool.has_stitched).is_false()


func test_bridge_carries_player_across_the_gap() -> void:
	var fixture: Array = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/fixtures/chapter_05_room_01.json")
	)
	for input: Array in fixture:
		room.player.drive_input(float(input[0]), bool(input[1]), bool(input[2]))
		room.player.drive_tools(bool(input[3]), bool(input[4]), bool(input[5]))
		await _steps(1)
	assert_int(run.state).is_equal(RunController.State.COMPLETED)
	assert_int(run.deaths).is_equal(0)
	assert_float(room.player.position.x).is_greater(580)


func test_grapple_rejects_an_anchor_behind_a_solid_wall() -> void:
	_load_room(41, true)
	room.player.reset_for_attempt(Vector2(200, 289))
	await _steps(3)
	room.player.drive_tools(false, true)
	await _steps(2)
	assert_int(room.thread_tool.grapple_index).is_equal(-1)
	assert_bool(room.thread_tool.has_grappled).is_false()


func test_tether_constrains_motion_and_jump_releases() -> void:
	_load_room(41)
	room.player.reset_for_attempt(Vector2(200, 289))
	await _steps(3)
	room.player.drive_tools(false, true)
	room.player.drive_input(1, false, false)
	await _steps(1)
	assert_int(room.thread_tool.grapple_index).is_equal(0)
	var length: float = room.thread_tool.rope_length
	for tick in 25:
		await _steps(1)
		assert_float(room.player.position.distance_to(room.thread_anchors[0])).is_less(length + 1)
	room.player.drive_input(1, true, true)
	await _steps(2)
	assert_int(room.thread_tool.grapple_index).is_equal(-1)
	assert_float(room.player.velocity.y).is_less(-200)


func test_rewind_retraces_history_while_time_advances() -> void:
	_load_room(43)
	room.player.drive_input(1, false, false)
	await _steps(50)
	var from: float = room.player.position.x
	var clock: float = run.attempt_time
	var phase: float = room.elapsed
	room.player.drive_tools(false, false, true)
	await _steps(10)
	assert_float(room.player.position.x).is_less(from - 80)
	assert_float(room.thread_tool.rewound_distance).is_greater(80)
	assert_float(run.attempt_time).is_greater(clock)
	assert_float(room.elapsed).is_greater(phase)


func test_rewind_cannot_pass_a_new_solid_wall() -> void:
	_load_room(43)
	room.player.drive_input(1, false, false)
	await _steps(55)
	var wall: StaticBody2D = StaticBody2D.new()
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(8, 58)
	collision.shape = shape
	wall.position = Vector2(184, 299)
	wall.add_child(collision)
	room.add_child(wall)
	await _steps(1)
	room.player.drive_tools(false, false, true)
	await _steps(18)
	assert_float(room.player.position.x).is_greater(193)
	assert_int(room.thread_tool.history.size()).is_equal(0)


func test_hazards_remain_lethal_during_rewind() -> void:
	_load_room(43)
	room.player.drive_input(1, false, false)
	await _steps(50)
	room.spikes.append(Rect2(150, 306, 20, 22))
	room.player.drive_tools(false, false, true)
	await _steps(10)
	assert_int(run.deaths).is_equal(1)
	assert_bool(room.player.dead).is_true()


func test_pause_freezes_the_tether_and_thread_history() -> void:
	_load_room(41)
	room.player.reset_for_attempt(Vector2(200, 289))
	await _steps(3)
	room.player.drive_tools(false, true)
	room.player.drive_input(1, false, false)
	await _steps(10)
	run.set_paused(true)
	var position: Vector2 = room.player.position
	var history: int = room.thread_tool.history.size()
	var length: float = room.thread_tool.rope_length
	await _steps(12)
	assert_vector(room.player.position).is_equal(position)
	assert_int(room.thread_tool.history.size()).is_equal(history)
	assert_float(room.thread_tool.rope_length).is_equal(length)


func test_restart_clears_bridges_and_rewind_history() -> void:
	room.player.drive_input(1, false, false)
	await _steps(31)
	room.player.drive_input(0, false, false)
	room.player.drive_tools(true)
	await _steps(3)
	assert_bool(room.thread_tool.relay_powered()).is_true()
	var nodes: int = room.get_child_count()
	run.restart()
	await _steps(2)
	assert_bool(room.thread_tool.relay_powered()).is_false()
	assert_bool(room.thread_tool.has_stitched).is_false()
	assert_float(room.thread_tool.rewound_distance).is_equal(0.0)
	assert_int(room.thread_tool.grapple_index).is_equal(-1)
	assert_int(room.thread_tool.history.size()).is_less(4)
	assert_bool(room.thread_tool.bridges[0].get_child(0).disabled).is_true()
	assert_int(room.get_child_count()).is_equal(nodes)


func test_history_is_bounded_to_six_seconds() -> void:
	_load_room(43)
	await _steps(380)
	assert_int(room.thread_tool.history.size()).is_equal(360)
	room.player.drive_tools(false, false, true)
	await _steps(130)
	assert_int(room.thread_tool.history.size()).is_equal(0)
	assert_int(run.state).is_equal(RunController.State.PLAYING)
