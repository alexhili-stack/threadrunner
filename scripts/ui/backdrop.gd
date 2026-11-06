extends Node2D

const FOUNDRY: Texture2D = preload("res://assets/art/foundry/background.png")
var chapter: int = 0
var menu_mode: bool = true
var reduced_effects: bool = false
var pan: float = 0.0


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), ThreadStyle.INK)
	draw_texture_rect(FOUNDRY, Rect2(-24 - pan * 24, -10, 704, 396), false)
	if menu_mode:
		draw_rect(Rect2(0, 0, 640, 360), Color(0.02, 0.025, 0.03, 0.7))
