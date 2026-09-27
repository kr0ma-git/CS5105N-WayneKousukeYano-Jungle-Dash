class_name Hazard
extends Area2D

## Costs the player one heart on contact. Used for bonfires, spike traps and
## enemies. An Area2D does not block the player, so jumping over the hazard
## avoids the hitbox. The player has brief invulnerability after a hit, so
## resting against a hazard only drains one heart, not the whole bar.

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	var player: Player = body as Player
	if player != null:
		player.hurt()