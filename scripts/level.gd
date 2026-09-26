class_name Level
extends Node2D

## One playable level. Handles two things:
##   * respawning the player when they die (fall in a pit / touch a hazard)
##   * loading the next level when the player reaches the goal
## Level 1 points next_scene at Level 2; Level 2 points it back at Level 1 so
## the demo loops (an "endless runner" can always keep going).

@export var next_scene: PackedScene
## Alternative to next_scene, loaded at runtime (used to avoid a circular
## PackedScene reference between Level 2 and Level 1).
@export var next_level_path: String = ""
## Anything that falls below this world Y is treated as a pit death.
@export var kill_y: float = 420.0

@onready var _player: Player = $Player
@onready var _goal: Area2D = $Goal

func _ready() -> void:
	_player.died.connect(_on_player_died)
	_goal.body_entered.connect(_on_goal_body_entered)

func _process(_delta: float) -> void:
	if is_instance_valid(_player) and _player.global_position.y > kill_y:
		_player.die()

func _on_player_died() -> void:
	get_tree().call_deferred("reload_current_scene")

func _on_goal_body_entered(body: Node2D) -> void:
	if body != _player:
		return
	if next_scene != null:
		get_tree().call_deferred("change_scene_to_packed", next_scene)
		return
	if next_level_path != "":
		var packed := load(next_level_path) as PackedScene
		if packed != null:
			get_tree().call_deferred("change_scene_to_packed", packed)
			return
	get_tree().call_deferred("reload_current_scene")