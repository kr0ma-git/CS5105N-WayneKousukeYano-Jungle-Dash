extends CharacterBody2D

@export var speed := 200.0
@export var gravity := 1200.0
@export var jump_velocity := -450.0
@export var coyote_time := 0.1
var coyote_timer := 0.0

func _physics_process(delta):
	velocity.x = speed

	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and coyote_timer > 0:
		velocity.y = jump_velocity
		coyote_timer = 0

	move_and_slide()
