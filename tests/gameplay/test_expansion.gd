extends GdUnitTestSuite


func test_vent_telegraph_and_lethal_window_reset() -> void:
	var room: LevelRoot = LevelRoot.new()
	room.platforms = [Rect2(16, 328, 608, 16)]
	room.vents = [Rect2(176, 292, 32, 36)]
	get_tree().root.add_child(room)
	room.player.synthetic = true
	room.player.position = Vector2(192, 317)
	room.elapsed = 1.9
	assert_bool(room.lethal_at_player()).is_false()
	room.elapsed = 2.2
	assert_bool(room.vent_is_warning()).is_true()
	assert_bool(room.lethal_at_player()).is_false()
	room.elapsed = 2.8
	assert_bool(room.vent_is_active()).is_true()
	assert_bool(room.lethal_at_player()).is_true()
	room.reset_for_attempt()
	assert_bool(room.vent_is_active()).is_false()
	assert_bool(room.vent_is_warning()).is_false()
	room.free()


func test_pause_and_completion_do_not_mark_player_dead() -> void:
	var room: LevelRoot = LevelRoot.new()
	get_tree().root.add_child(room)
	var run: RunController = RunController.new()
	get_tree().root.add_child(run)
	run.begin(room)
	run.set_paused(true)
	assert_bool(room.player.dead).is_false()
	run.set_paused(false)
	run.complete()
	assert_bool(room.player.dead).is_false()
	run.restart()
	run.die()
	assert_bool(room.player.dead).is_true()
	run.restart()
	assert_bool(room.player.dead).is_false()
	run.free()
	room.free()


func test_replay_release_is_one_input_edge() -> void:
	var player: PlayerController = preload("res://scenes/player/player.tscn").instantiate()
	player.drive_input(1, true, true)
	assert_bool(player.test_released).is_false()
	player.drive_input(1, false, false)
	assert_bool(player.test_released).is_true()
	player.drive_input(1, false, false)
	assert_bool(player.test_released).is_false()
	player.free()


func test_large_room_bounds_and_camera_reset() -> void:
	var room: LevelRoot = LevelCatalog.entry(39).scene.instantiate()
	get_tree().root.add_child(room)
	room.player.synthetic = true
	room.player.position = Vector2(920, 317)
	assert_bool(room.lethal_at_player()).is_false()
	room.player.position.x = 1282
	assert_bool(room.lethal_at_player()).is_true()
	room.reset_for_attempt()
	assert_vector(room.player.position).is_equal(room.spawn)
	assert_int(room.camera.limit_right).is_equal(1280)
	room.free()
