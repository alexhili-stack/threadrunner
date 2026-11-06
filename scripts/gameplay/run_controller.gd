class_name RunController
extends Node

signal player_died
signal exit_reached
signal collectible_touched
signal attempt_started
signal attempt_finished(seconds: float, fragment: bool)

enum State { READY, PLAYING, DYING, RESETTING, COMPLETED }
var state: State = State.READY
var level: LevelRoot
var deaths: int = 0
var attempt_time: float = 0.0
var death_remaining: float = 0.0
var paused: bool = false
var death_started_usec: int = 0
var reset_latencies: Array[float] = []


func begin(room: LevelRoot) -> void:
	level = room
	deaths = 0
	restart()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(level) or paused:
		return
	if state == State.DYING:
		death_remaining -= delta
		if death_remaining <= 0.0:
			restart()
		return
	if state != State.PLAYING:
		return
	attempt_time += delta
	level.advance(delta)
	# Lethal contact takes priority over the exit and fragment in the same tick.
	if level.lethal_at_player():
		die()
	elif level.at_exit():
		complete()
	elif level.touching_fragment():
		level.fragment_collected = true
		level.fragment_pulse = 0.4
		collectible_touched.emit()


func die() -> void:
	if state != State.PLAYING:
		return
	state = State.DYING
	deaths += 1
	death_remaining = 0.10
	death_started_usec = Time.get_ticks_usec()
	level.player.active = false
	level.player.dead = true
	player_died.emit()


func restart() -> void:
	if not is_instance_valid(level):
		return
	state = State.RESETTING
	level.reset_for_attempt()
	attempt_time = 0.0
	death_remaining = 0.0
	paused = false
	state = State.PLAYING
	if death_started_usec != 0:
		reset_latencies.append(float(Time.get_ticks_usec() - death_started_usec) / 1000.0)
		death_started_usec = 0
	attempt_started.emit()


func set_paused(value: bool) -> void:
	paused = value
	if is_instance_valid(level):
		level.player.active = not value and state == State.PLAYING


func complete() -> void:
	if state != State.PLAYING:
		return
	state = State.COMPLETED
	level.exit_pulse = 0.5
	level.player.active = false
	exit_reached.emit()
	attempt_finished.emit(attempt_time, level.fragment_collected)
