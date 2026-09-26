class_name Hazard
extends Area2D

## Kills the player on contact. Used for bonfires and spike traps. An Area2D
## does not block the player, so jumping over the hazard avoids the hitbox.

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	var player: Player = body as Player
	if player != null:
		player.die()