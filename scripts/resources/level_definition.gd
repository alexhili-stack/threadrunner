class_name LevelDefinition
extends Resource

@export var stable_id: String = ""
@export var display_name: String = ""
@export var chapter: int = 1
@export var scene: PackedScene
@export var next_level_id: String = ""
@export var target_seconds: float = 10.0
@export var has_fragment: bool = true
