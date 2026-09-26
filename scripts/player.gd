class_name Player
extends CharacterBody2D

## Auto-running side-scroller hero. The player always moves right; the only
## input is "jump". Falling into a pit or touching a hazard calls die(), which
## the Level listens for so it can respawn the player.

signal died

@export var speed: float = 220.0
@export var gravity: float = 1400.0
@export var jump_velocity: float = -520.0
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12

var coyote_timer: float = 0.0
var _jump_buffer: float = 0.0
var _jump_held: bool = false
var _is_dead: bool = false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	velocity.x = speed
	velocity.y += gravity * delta

	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta

	# Edge-detect the jump press ourselves instead of is_action_just_pressed and
	# buffer it briefly, so a press that lands on a frame with no physics step,
	# or a split second before touching down, is never lost.
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
	_update_animation()

func _update_animation() -> void:
	var want: StringName = &"running"
	if not is_on_floor():
		want = &"jump" if velocity.y < 0.0 else &"fall"
	if _sprite.animation != want:
		_sprite.play(want)

func die() -> void:
	if _is_dead:
		return
	_is_dead = true
	set_physics_process(false)
	died.emit()