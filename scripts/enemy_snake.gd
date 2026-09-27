class_name EnemySnake
extends Hazard

## A jungle snake. Behaviourally it is a hazard with a face: it slithers in place
## while its chunk slides past, and costs the hero one heart on contact. Jumping
## clears it just like a spike trap. Giving enemies their own class keeps them
## easy to extend later (patrols, lunges, dropping loot).

func _ready() -> void:
	super()
	var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite != null:
		sprite.play(&"slithering_along_the_ground_body_rippling_side_to_side_head_bobbing")