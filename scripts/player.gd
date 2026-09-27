class_name Player
extends CharacterBody2D

## Auto-running side-scroller hero. The hero always moves right; the only input
## is "jump". Falling into a pit or touching a hazard calls die(), which the
## Level listens for so it can respawn the player.
##
## Animation is split in two and driven from a small state machine
## (idle / run / jump / fall / land):
##   * AnimatedSprite2D holds the pixel-art frames.
##   * AnimationPlayer plays transform "juice" (squash & stretch, bob).

signal died

@export var speed: float = 220.0
@export var gravity: float = 1400.0
@export var jump_velocity: float = -520.0
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12
## Short "get ready" beat before the hero starts running, so the idle animation
## is actually seen at the start of a level.
@export var start_delay: float = 0.7

var coyote_timer: float = 0.0
var _jump_buffer: float = 0.0
var _jump_held: bool = false
var _is_dead: bool = false
var _elapsed: float = 0.0
var _was_airborne: bool = false
var _state: StringName = &"idle"

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _anim: AnimationPlayer = $AnimationPlayer
@onready var _dust: CPUParticles2D = $LandDust

func _ready() -> void:
	_sprite.play(&"idle")
	_anim.play(&"idle")

func _physics_process(delta: float) -> void:
	_elapsed += delta
	var running: bool = _elapsed >= start_delay

	velocity.x = speed if running else 0.0
	velocity.y += gravity * delta

	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta

	if running:
		# Edge-detect the jump press ourselves instead of is_action_just_pressed
		# and buffer it briefly, so a press that lands on a frame with no physics
		# step, or a split second before touching down, is never lost.
		var held: bool = Input.is_action_pressed("jump")
		if held and not _jump_held:
			_jump_buffer = jump_buffer_time
		_jump_held = held
		_jump_buffer -= delta

		if _jump_buffer > 0.0 and coyote_timer > 0.0:
			velocity.y = jump_velocity
			_jump_buffer = 0.0
			coyote_timer = 0.0

	move_and_slide()
	_update_state()

func _update_state() -> void:
	var on_floor: bool = is_on_floor()

	# Just touched down after being in the air -> squash + a puff of dust.
	if on_floor and _was_airborne:
		_was_airborne = false
		_state = &"land"
		_sprite.play(&"running")
		_anim.play(&"land")
		_dust.restart()
		return
	_was_airborne = not on_floor

	if not on_floor:
		var air_state: StringName = &"jump" if velocity.y < 0.0 else &"fall"
		if _state != air_state:
			_state = air_state
			_sprite.play(air_state)
			if air_state == &"jump":
				_anim.play(&"jump")
		return

	# On the ground. Let a landing squash finish before resuming the run.
	if _state == &"land" and _anim.is_playing():
		return
	var ground_state: StringName = &"run" if _elapsed >= start_delay else &"idle"
	if _state != ground_state:
		_state = ground_state
		if ground_state == &"run":
			_sprite.play(&"running")
			_anim.play(&"run")
		else:
			_sprite.play(&"idle")
			_anim.play(&"idle")

func die() -> void:
	if _is_dead:
		return
	_is_dead = true
	set_physics_process(false)
	died.emit()