class_name Player
extends CharacterBody2D

## Auto-running side-scroller hero. The player is always moving right; the only
## input is "jump". Falling into a pit or touching a hazard calls die(), which
## the Level listens for so it can respawn the player.

signal died

@export var speed: float = 200.0
@export var gravity: float = 1200.0
@export var jump_velocity: float = -450.0
@export var coyote_time: float = 0.12

var coyote_timer: float = 0.0
var _is_dead: bool = false

func _physics_process(delta: float) -> void:
	velocity.x = speed
	velocity.y += gravity * delta

	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta

	if Input.is_action_just_pressed("jump") and coyote_timer > 0.0:
		velocity.y = jump_velocity
		coyote_timer = 0.0

	move_and_slide()

func die() -> void:
	if _is_dead:
		return
	_is_dead = true
	set_physics_process(false)
	died.emit()
