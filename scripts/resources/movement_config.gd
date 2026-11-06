class_name MovementConfig
extends Resource

@export var run_speed: float = 240.0
@export var ground_acceleration: float = 2400.0
@export var ground_deceleration: float = 3000.0
@export var air_acceleration: float = 1500.0
@export var jump_velocity: float = -430.0
@export var gravity: float = 1400.0
@export var fall_speed: float = 700.0
@export var wall_slide_speed: float = 90.0
@export var wall_jump_x: float = 250.0
@export var wall_jump_y: float = -410.0
@export var coyote_time: float = 0.10
@export var jump_buffer: float = 0.12
@export var steering_lock: float = 0.08
@export var thread_grapple_reach: float = 240.0
@export var thread_stitch_reach: float = 42.0
@export var thread_swing_acceleration: float = 700.0
@export var thread_swing_speed: float = 380.0
@export var thread_release_jump: float = -300.0
@export var thread_history_seconds: float = 6.0
@export var thread_rewind_steps: int = 3
