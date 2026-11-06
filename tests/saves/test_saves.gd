extends GdUnitTestSuite

var saves: SaveService
var path: String


func before_test() -> void:
	path = "res://artifacts/save-tests/%s" % Time.get_ticks_usec()
	saves = SaveService.new(path)


func put(text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path)
	var file: FileAccess = FileAccess.open(path.path_join("progress.json"), FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_first_launch_and_round_trip() -> void:
	saves.load_save()
	assert_int(saves.data.unlocked.size()).is_equal(1)
	saves.record_clear(LevelCatalog.id_for(0), 4.251234567890123, true)
	assert_bool(saves.write_save()).is_true()
	var other: SaveService = SaveService.new(path)
	other.load_save()
	assert_float(other.data.completed[LevelCatalog.id_for(0)]).is_equal(4.251234567890123)
	assert_int(other.data.fragments.size()).is_equal(1)
	assert_int(other.data.unlocked.size()).is_equal(2)


func test_malformed_truncated_save() -> void:
	put('{"schema":1, "completed":')
	saves.load_save()
	assert_int(saves.data.completed.size()).is_equal(0)
	assert_str(saves.last_error).is_not_empty()


func test_future_schema_is_preserved() -> void:
	var text: String = '{"schema":200, "precious":"keep"}'
	put(text)
	saves.load_save()
	assert_bool(saves.write_save()).is_false()
	assert_str(FileAccess.get_file_as_string(path.path_join("progress.json"))).is_equal(text)


func test_invalid_fields_and_unknown_ids() -> void:
	put(
		(
			'{"schema":1,"completed":{"fake":4},"unlocked":["fake"],"deaths":-2'
			+ ',"settings":{"master":9,"music":"loud","shake":"yes"}}'
		)
	)
	saves.load_save()
	assert_int(saves.data.completed.size()).is_equal(0)
	assert_int(saves.data.unlocked.size()).is_equal(1)
	assert_int(saves.data.deaths).is_equal(0)
	assert_float(saves.data.settings.master).is_equal(1.0)
	assert_float(saves.data.settings.music).is_equal(0.35)
	assert_bool(saves.data.settings.shake).is_true()


func test_best_time_and_settings_reset() -> void:
	saves.record_clear(LevelCatalog.id_for(0), 5, true)
	saves.record_clear(LevelCatalog.id_for(0), 9, false)
	assert_float(saves.data.completed[LevelCatalog.id_for(0)]).is_equal(5.0)
	saves.data.settings.master = 0.2
	saves.reset_progress()
	assert_float(saves.data.settings.master).is_equal(0.2)
	assert_int(saves.data.fragments.size()).is_equal(0)
	assert_int(saves.data.completed.size()).is_equal(0)


func test_replacement_and_failed_write() -> void:
	assert_bool(saves.write_save()).is_true()
	saves.data.settings.mute = true
	assert_bool(saves.write_save()).is_true()
	saves.load_save()
	assert_bool(saves.data.settings.mute).is_true()
	var invalid: SaveService = SaveService.new("res://project.godot/cannot-create")
	assert_bool(invalid.write_save()).is_false()


func test_binding_conflict_and_recovery() -> void:
	var input: InputService = InputService.new()
	input.configure()
	assert_bool(input.rebind("jump", KEY_A)).is_false()
	assert_bool(input.rebind("jump", KEY_J)).is_true()
	assert_str(input.label_for("jump")).is_equal("J")
	saves.data.settings.bindings = input.bindings
	assert_bool(saves.write_save()).is_true()
	saves.load_save()
	input.configure(saves.data.settings.bindings)
	assert_str(input.label_for("jump")).is_equal("J")
	input.configure()
	assert_str(input.label_for("jump")).is_equal("Space")


func test_layout_migration_preserves_progress_and_archives_old_times() -> void:
	put(
		JSON.stringify(
			{
				"schema": 1,
				"completed": {"chapter_01_room_01": 2.5},
				"fragments": ["chapter_01_room_01"],
				"settings": {"master": 0.2}
			}
		)
	)
	saves.load_save()
	assert_float(saves.data.completed[LevelCatalog.id_for(0)]).is_equal(0.0)
	assert_float(saves.data.legacy_records[LevelCatalog.id_for(0)]).is_equal(2.5)
	assert_int(saves.data.fragments.size()).is_equal(1)
	assert_int(saves.data.unlocked.size()).is_equal(2)
	saves.record_clear(LevelCatalog.id_for(0), 12.5, false)
	assert_float(saves.data.completed[LevelCatalog.id_for(0)]).is_equal(12.5)
	assert_bool(saves.write_save()).is_true()
	saves.load_save()
	assert_float(saves.data.completed[LevelCatalog.id_for(0)]).is_equal(12.5)
	assert_float(saves.data.legacy_records[LevelCatalog.id_for(0)]).is_equal(2.5)


func test_deadzone_persists_and_survives_rebinding() -> void:
	saves.data.settings.deadzone = 0.4
	assert_bool(saves.write_save()).is_true()
	saves.load_save()
	var input: InputService = InputService.new()
	input.configure({}, saves.data.settings.deadzone)
	assert_float(InputMap.action_get_deadzone("move_left")).is_equal_approx(0.4, 0.001)
	assert_bool(input.rebind("jump", KEY_J)).is_true()
	assert_float(InputMap.action_get_deadzone("move_left")).is_equal_approx(0.4, 0.001)


func test_fortieth_room_unlocks_after_thirty_nine() -> void:
	saves.record_clear(LevelCatalog.id_for(38), 25.0, false)
	assert_bool(LevelCatalog.id_for(39) in saves.data.unlocked).is_true()


func test_fractional_physics_time_round_trip() -> void:
	var seconds: float = 0.0
	for tick in 1304:
		seconds += 1.0 / 60.0
	saves.record_clear(LevelCatalog.id_for(39), seconds, true)
	assert_bool(saves.write_save()).is_true()
	saves.load_save()
	assert_float(saves.data.completed[LevelCatalog.id_for(39)]).is_equal_approx(seconds, 0.000001)


func test_legacy_binding_survives_new_thread_actions() -> void:
	var input: InputService = InputService.new()
	input.configure({"jump": KEY_E})
	assert_str(input.label_for("jump")).is_equal("E")
	assert_bool(input.bindings.thread_stitch == KEY_E).is_false()
	assert_bool(input.rebind("thread_grapple", KEY_G)).is_true()
	assert_str(input.label_for("thread_grapple")).is_equal("G")


func test_latest_layout_record_wins_over_an_older_archive() -> void:
	put(
		JSON.stringify(
			{
				"schema": 2,
				"layout_revision": 2,
				"completed": {"chapter_01_room_01": 8.5},
				"legacy_records": {"chapter_01_room_01": 2.5}
			}
		)
	)
	saves.load_save()
	assert_float(saves.data.completed[LevelCatalog.id_for(0)]).is_equal(0.0)
	assert_float(saves.data.legacy_records[LevelCatalog.id_for(0)]).is_equal(8.5)
