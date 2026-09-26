class_name Level
extends Node2D

## One playable level. Handles two things:
##   * respawning the player when they die (fall in a pit / touch a hazard)
##   * loading the next level when the player reaches the goal
## next_level_path is loaded at runtime so Level 2 can point back at Level 1
## without a circular PackedScene reference.

@export var next_level_path: String = ""
## Anything that falls below this world Y is treated as a pit death.
@export var kill_y: float = 700.0

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
	if next_level_path != "":
		var scene := load(next_level_path) as PackedScene
		if scene != null:
			get_tree().call_deferred("change_scene_to_packed", scene)
			return
	get_tree().call_deferred("reload_current_scene")