extends SceneTree


func _initialize() -> void:
	call_deferred("validate")


func validate() -> void:
	var issues: Array[String] = []
	var ids: Array[String] = []
	for index in LevelCatalog.COUNT:
		var path: String = LevelCatalog.scene_path(index)
		if not ResourceLoader.exists(path):
			issues.append("Missing scene: " + path)
			continue
		var room: LevelRoot = load(path).instantiate()
		var definition: LevelDefinition = LevelCatalog.entry(index)
		var expected_next: String = (
			LevelCatalog.id_for(index + 1) if index < LevelCatalog.COUNT - 1 else ""
		)
		if definition.next_level_id != expected_next or definition.stable_id != room.level_id:
			issues.append("Broken metadata progression: " + room.level_id)
		if definition.scene.resource_path != path or not definition.has_fragment:
			issues.append("Invalid scene/fragment metadata: " + room.level_id)
		root.add_child(room)
		if room.level_id in ids or room.level_id != LevelCatalog.id_for(index):
			issues.append("Invalid/duplicate ID: " + room.level_id)
		ids.append(room.level_id)
		if room.lethal_at_player():
			issues.append("Lethal spawn: " + room.level_id)
		var bounds: Rect2 = Rect2(Vector2(16, 60), room.world_size - Vector2(32, 90))
		for point: Vector2 in [room.spawn, room.exit_position, room.fragment_position]:
			if not bounds.has_point(point):
				issues.append("Objective out of bounds: " + room.level_id)
		if room.platforms.is_empty() or room.route.is_empty() or room.purpose.is_empty():
			issues.append("Missing authored geometry/route/purpose: " + room.level_id)
		room.fragment_collected = true
		room.elapsed = 2.0
		room.reset_for_attempt()
		if room.fragment_collected or room.elapsed != 0.0 or room.player.position != room.spawn:
			issues.append("Reset contract failed: " + room.level_id)
		room.free()
	var report: Dictionary = {
		"rooms": ids.size(),
		"issues": issues,
		"pass": issues.is_empty() and ids.size() == LevelCatalog.COUNT
	}
	var file: FileAccess = FileAccess.open("res://artifacts/levels.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print(JSON.stringify(report))
	quit(0 if report.pass else 1)
