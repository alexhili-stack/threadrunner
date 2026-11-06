extends GdUnitTestSuite

var room: LevelRoot
var player: PlayerController


func before_test() -> void:
	room = LevelRoot.new()
	room.platforms = [Rect2(0, 328, 420, 16), Rect2(350, 80, 16, 248), Rect2(0, 245, 90, 16)]
	get_tree().root.add_child(room)
	player = room.player
	player.synthetic = true
	player.reset_for_attempt(Vector2(160, 317))
	await steps(5)


func after_test() -> void:
	room.free()


func steps(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func test_acceleration_reaches_maximum() -> void:
	player.test_axis = 1
	await steps(9)
	assert_float(player.velocity.x).is_equal_approx(240, 0.1)
	assert_float(player.position.x).is_greater(170)


func test_deceleration_stops() -> void:
	player.test_axis = 1
	await steps(8)
	player.test_axis = 0
	await steps(7)
	assert_float(player.velocity.x).is_equal_approx(0, 0.1)


func apex(release: bool) -> float:
	player.reset_for_attempt(Vector2(160, 317))
	await steps(5)
	player.test_jump = true
	player.test_held = true
	await steps(3)
	if release:
		player.test_released = true
		player.test_held = false
	var top: float = player.position.y
	for frame in 45:
		await steps(1)
		top = minf(top, player.position.y)
	return top


func test_tap_has_lower_apex() -> void:
	var held: float = await apex(false)
	var tap: float = await apex(true)
	assert_float(tap - held).is_greater(25)


func test_coyote_inside_window() -> void:
	player.reset_for_attempt(Vector2(410, 317))
	player.test_axis = 1
	await steps(9)
	assert_bool(player.is_on_floor()).is_false()
	player.test_jump = true
	await steps(2)
	assert_float(player.velocity.y).is_less(-300)


func test_coyote_outside_window() -> void:
	player.reset_for_attempt(Vector2(410, 317))
	player.test_axis = 1
	await steps(19)
	player.test_jump = true
	await steps(2)
	assert_float(player.velocity.y).is_greater(0)


func test_buffer_triggers_on_landing() -> void:
	player.reset_for_attempt(Vector2(160, 295))
	player.velocity.y = 260
	await steps(2)
	player.test_jump = true
	await steps(7)
	assert_float(player.velocity.y).is_less(-200)


func test_expired_buffer_does_not_jump() -> void:
	player.reset_for_attempt(Vector2(160, 165))
	player.test_jump = true
	await steps(39)
	assert_bool(player.is_on_floor()).is_true()
	assert_float(player.velocity.y).is_equal_approx(0, 0.1)


func test_wall_slide_cap() -> void:
	player.reset_for_attempt(Vector2(343, 150))
	player.test_axis = 1
	player.velocity.y = 400
	await steps(10)
	assert_bool(player.is_on_wall()).is_true()
	assert_float(player.velocity.y).is_less_equal(90.1)


func test_wall_jump_pushes_away() -> void:
	player.reset_for_attempt(Vector2(343, 190))
	player.test_axis = 1
	await steps(4)
	player.test_jump = true
	await steps(2)
	assert_float(player.velocity.x).is_less(-200)
	assert_float(player.velocity.y).is_less(-300)


func test_repeated_air_input_gives_no_extra_jump() -> void:
	player.test_jump = true
	await steps(14)
	var before: float = player.velocity.y
	player.test_jump = true
	await steps(2)
	assert_float(player.velocity.y).is_greater(before)


func test_ceiling_does_not_stick() -> void:
	player.reset_for_attempt(Vector2(45, 317))
	await steps(5)
	player.test_jump = true
	player.test_held = true
	await steps(35)
	assert_bool(player.is_on_floor()).is_true()
	assert_float(player.position.y).is_equal_approx(317, 1)


func test_reset_clears_motion_and_timers() -> void:
	player.test_jump = true
	player.test_axis = 1
	await steps(5)
	player.reset_for_attempt(Vector2(160, 317))
	assert_vector(player.velocity).is_equal(Vector2.ZERO)
	assert_float(player.buffer).is_equal(0.0)
	assert_float(player.coyote).is_equal(0.0)
	assert_float(player.lock_time).is_equal(0.0)
