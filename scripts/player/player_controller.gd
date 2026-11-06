class_name PlayerController
extends CharacterBody2D

signal feedback(event: String)

enum Motion { GROUNDED, AIRBORNE, WALL_SLIDING }

@export var config: MovementConfig = preload("res://data/movement/default.tres")
var motion: Motion = Motion.AIRBORNE
var active: bool = true
var coyote: float = 0.0
var buffer: float = 0.0
var lock_time: float = 0.0
var facing: float = 1.0
var synthetic: bool = false
var test_axis: float = 0.0
var test_jump: bool = false
var test_held: bool = false
var test_released: bool = false
var require_jump_release: bool = false
var contacts_fresh: bool = false
var dead: bool = false
var thread_tool: ThreadTool
var test_stitch: bool = false
var test_grapple: bool = false
var test_rewind: bool = false


func _physics_process(delta: float) -> void:
	if not active:
		return
	var axis: float = test_axis if synthetic else Input.get_axis("move_left", "move_right")
	var pressed: bool = test_jump if synthetic else Input.is_action_just_pressed("jump")
	var released: bool = test_released if synthetic else Input.is_action_just_released("jump")
	var held: bool = test_held if synthetic else Input.is_action_pressed("jump")
	if is_instance_valid(thread_tool):
		thread_tool.handle_input(
			test_stitch if synthetic else Input.is_action_just_pressed("thread_stitch"),
			test_grapple if synthetic else Input.is_action_just_pressed("thread_grapple"),
			test_rewind if synthetic else Input.is_action_pressed("thread_rewind"),
			delta
		)
		test_stitch = false
		test_grapple = false
		if thread_tool.rewinding:
			coyote = 0.0
			buffer = 0.0
			lock_time = 0.0
			var previous: Vector2 = position
			velocity = Vector2.ZERO
			var collision: KinematicCollision2D = move_and_collide(
				thread_tool.rewind_target() - position
			)
			thread_tool.finish_rewind_step(previous, collision != null)
			contacts_fresh = false
			motion = Motion.AIRBORNE
			test_jump = false
			test_released = false
			return
	if require_jump_release:
		pressed = false
		if not held:
			require_jump_release = false
	coyote = config.coyote_time if is_on_floor() and contacts_fresh else maxf(0.0, coyote - delta)
	buffer = config.jump_buffer if pressed else maxf(0.0, buffer - delta)
	lock_time = maxf(0.0, lock_time - delta)
	if absf(axis) > 0.1:
		facing = signf(axis)
	var tethered: bool = is_instance_valid(thread_tool) and thread_tool.grapple_index >= 0
	if tethered:
		velocity.x = clampf(
			velocity.x + axis * config.thread_swing_acceleration * delta,
			-config.thread_swing_speed,
			config.thread_swing_speed
		)
	elif lock_time <= 0.0:
		var acceleration: float = (
			config.ground_acceleration if is_on_floor() else config.air_acceleration
		)
		if is_on_floor() and is_zero_approx(axis):
			acceleration = config.ground_deceleration
		velocity.x = move_toward(velocity.x, axis * config.run_speed, acceleration * delta)
	velocity.y = minf(velocity.y + config.gravity * delta, config.fall_speed)
	var sliding: bool = is_on_wall() and not is_on_floor() and axis * get_wall_normal().x < -0.1
	if sliding and velocity.y > 0.0:
		velocity.y = minf(velocity.y, config.wall_slide_speed)
	if buffer > 0.0:
		if tethered:
			thread_tool.grapple_index = -1
			tethered = false
			velocity.y = minf(velocity.y, config.thread_release_jump)
			buffer = 0.0
			feedback.emit("jump")
		elif is_on_wall() and not is_on_floor() and contacts_fresh:
			velocity = Vector2(get_wall_normal().x * config.wall_jump_x, config.wall_jump_y)
			lock_time = config.steering_lock
			buffer = 0.0
			coyote = 0.0
			feedback.emit("wall_jump")
		elif coyote > 0.0:
			velocity.y = config.jump_velocity
			coyote = 0.0
			buffer = 0.0
			feedback.emit("jump")
	if released and velocity.y < 0.0:
		velocity.y *= 0.45
	if tethered:
		var next: Vector2 = position + velocity * delta
		var offset: Vector2 = next - thread_tool.anchor()
		if offset.length() > thread_tool.rope_length:
			var constrained: Vector2 = (
				thread_tool.anchor() + offset.normalized() * thread_tool.rope_length
			)
			velocity = (constrained - position) / delta
	var was_grounded: bool = is_on_floor()
	move_and_slide()
	contacts_fresh = true
	if is_on_floor() and not was_grounded:
		feedback.emit("land")
	motion = (
		Motion.GROUNDED if is_on_floor() else (Motion.WALL_SLIDING if sliding else Motion.AIRBORNE)
	)
	test_jump = false
	test_released = false
	if is_instance_valid(thread_tool):
		thread_tool.record_position()


func drive_tools(stitch: bool = false, grapple: bool = false, rewind: bool = false) -> void:
	test_stitch = stitch
	test_grapple = grapple
	test_rewind = rewind


func drive_input(axis: float, jump_pressed: bool, held: bool) -> void:
	synthetic = true
	test_axis = clampf(axis, -1, 1)
	test_jump = jump_pressed
	test_released = test_held and not held
	test_held = held


func reset_for_attempt(spawn: Vector2) -> void:
	dead = false
	if has_node("Visuals"):
		get_node("Visuals").reset_visuals()
	position = spawn
	velocity = Vector2.ZERO
	coyote = 0.0
	buffer = 0.0
	lock_time = 0.0
	contacts_fresh = false
	motion = Motion.AIRBORNE
	active = true
	test_jump = false
	test_held = false
	test_released = false
	test_stitch = false
	test_grapple = false
	test_rewind = false
	require_jump_release = (
		InputMap.has_action("jump") and Input.is_action_pressed("jump") if not synthetic else false
	)
	reset_physics_interpolation()
