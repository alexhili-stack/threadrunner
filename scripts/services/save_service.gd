class_name SaveService
extends RefCounted

const SCHEMA: int = 2
const LAYOUT_REVISION: int = 3
const DEFAULTS: Dictionary = {
	"master": 0.8,
	"music": 0.35,
	"effects": 0.7,
	"mute": false,
	"fullscreen": false,
	"shake": true,
	"reduced_effects": false,
	"deadzone": 0.25,
	"bindings": {}
}
var directory: String = "user://"
var data: Dictionary = {}
var last_error: String = ""
var future_schema: bool = false


func _init(save_directory: String = "user://") -> void:
	directory = save_directory
	reset_data()


func reset_data() -> void:
	data = {
		"schema": SCHEMA,
		"layout_revision": LAYOUT_REVISION,
		"legacy_records": {},
		"completed": {},
		"unlocked": [LevelCatalog.id_for(0)],
		"fragments": [],
		"deaths": 0,
		"settings": DEFAULTS.duplicate(true)
	}


func load_save() -> void:
	reset_data()
	future_schema = false
	last_error = ""
	var path: String = directory.path_join("progress.json")
	if not FileAccess.file_exists(path):
		return
	var parser: JSON = JSON.new()
	var parse_error: Error = parser.parse(FileAccess.get_file_as_string(path))
	var parsed: Variant = parser.data if parse_error == OK else null
	if not parsed is Dictionary:
		last_error = "Save was unreadable; a fresh session is available. Original file kept."
		return
	if not parsed.get("schema", 1) is float and not parsed.get("schema", 1) is int:
		last_error = "Invalid save schema; original file kept."
		return
	if int(parsed.get("schema", 1)) > SCHEMA:
		future_schema = true
		last_error = "Save belongs to a newer version. It will not be overwritten."
		return
	var completed: Variant = parsed.get("completed", {})
	if completed is Dictionary:
		for key: Variant in completed:
			var time: Variant = completed[key]
			if LevelCatalog.index_for(str(key)) >= 0 and (time is float or time is int):
				if is_finite(float(time)) and float(time) >= 0:
					if int(parsed.get("layout_revision", 1)) < LAYOUT_REVISION:
						data.legacy_records[key] = float(time)
						data.completed[key] = 0.0
					else:
						data.completed[key] = float(time)
	var legacy: Variant = parsed.get("legacy_records", {})
	if legacy is Dictionary:
		for key: Variant in legacy:
			if (
				LevelCatalog.index_for(str(key)) >= 0
				and (legacy[key] is float or legacy[key] is int)
			):
				if (
					is_finite(float(legacy[key]))
					and float(legacy[key]) > 0
					and not data.legacy_records.has(key)
				):
					data.legacy_records[key] = float(legacy[key])
	for key: String in ["unlocked", "fragments"]:
		var values: Variant = parsed.get(key, [])
		if values is Array:
			for value: Variant in values:
				if (
					value is String
					and LevelCatalog.index_for(value) >= 0
					and not value in data[key]
				):
					data[key].append(value)
	# Derive unlocks from completions to recover partially written older saves.
	for key: String in data.completed:
		var next: int = LevelCatalog.index_for(key) + 1
		if next < LevelCatalog.COUNT and not LevelCatalog.id_for(next) in data.unlocked:
			data.unlocked.append(LevelCatalog.id_for(next))
	var deaths: Variant = parsed.get("deaths", 0)
	if deaths is float or deaths is int:
		data.deaths = maxi(0, int(deaths))
	var settings: Variant = parsed.get("settings", {})
	if settings is Dictionary:
		for key: String in ["master", "music", "effects"]:
			var value: Variant = settings.get(key, DEFAULTS[key])
			if (value is float or value is int) and is_finite(float(value)):
				data.settings[key] = clampf(float(value), 0, 1)
		for key: String in ["mute", "fullscreen", "shake", "reduced_effects"]:
			if settings.get(key) is bool:
				data.settings[key] = settings[key]
		if settings.get("bindings") is Dictionary:
			data.settings.bindings = settings.bindings.duplicate()
		var deadzone: Variant = settings.get("deadzone", 0.25)
		if (deadzone is float or deadzone is int) and is_finite(float(deadzone)):
			data.settings.deadzone = clampf(float(deadzone), 0.05, 0.55)


func write_save() -> bool:
	if future_schema:
		return false
	var ancestor: String = directory
	while ancestor.length() > 6:
		if FileAccess.file_exists(ancestor):
			last_error = "A file blocks the save directory; original data kept."
			return false
		var parent: String = ancestor.get_base_dir()
		if parent == ancestor:
			break
		ancestor = parent
	var error: Error = DirAccess.make_dir_recursive_absolute(directory)
	if error != OK:
		last_error = "Cannot create save directory (%s)." % error_string(error)
		return false
	var path: String = directory.path_join("progress.json")
	var temp: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		last_error = "Cannot write save (%s)." % error_string(FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(data, "\t", true, true))
	file.flush()
	file.close()
	# Godot rename replaces an existing file on supported desktop targets.
	error = DirAccess.rename_absolute(temp, path)
	if error != OK:
		last_error = "Could not replace save (%s); original file kept." % error_string(error)
		return false
	last_error = ""
	return true


func record_clear(level_id: String, seconds: float, fragment: bool) -> void:
	if LevelCatalog.index_for(level_id) < 0 or seconds <= 0.0 or not is_finite(seconds):
		return
	var previous: float = float(data.completed.get(level_id, INF))
	if previous <= 0:
		previous = INF
	data.completed[level_id] = minf(previous, seconds)
	if fragment and not level_id in data.fragments:
		data.fragments.append(level_id)
	var next: int = LevelCatalog.index_for(level_id) + 1
	if next < LevelCatalog.COUNT and not LevelCatalog.id_for(next) in data.unlocked:
		data.unlocked.append(LevelCatalog.id_for(next))


func reset_progress() -> void:
	var settings: Dictionary = data.settings.duplicate(true)
	reset_data()
	data.settings = settings
