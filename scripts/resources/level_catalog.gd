class_name LevelCatalog
extends RefCounted

const BASE_COUNT: int = 40
const COUNT: int = 45
const CHAPTERS: Array[String] = [
	"BOOT SEQUENCE", "CLOCKWORK", "THE LAST THREAD", "AFTERLIGHT", "THREADWORK"
]


static func id_for(index: int) -> String:
	return "chapter_%02d_room_%02d" % [index / 10 + 1, index % 10 + 1]


static func scene_path(index: int) -> String:
	return "res://scenes/levels/chapter_%02d/room_%02d.tscn" % [index / 10 + 1, index % 10 + 1]


static func index_for(level_id: String) -> int:
	for index in COUNT:
		if id_for(index) == level_id:
			return index
	return -1


static func entry(index: int) -> LevelDefinition:
	return load("res://data/campaign/%s.tres" % id_for(index))
