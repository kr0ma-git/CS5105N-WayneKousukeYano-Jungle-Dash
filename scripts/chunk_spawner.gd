class_name ChunkSpawner
extends Node2D

## The endless world.
##
## It keeps a queue of ground "chunks" (see chunk.gd) all sliding right-to-left.
## New chunks are drawn at random and spawned just off the right edge, then
## freed once they have left the screen on the left. Because each chunk knows
## its own width, they line up flush, so the ground is continuous and the only
## gaps are the pits built into individual chunks.

## The pool of chunk scenes the spawner picks from at random.
@export var chunk_scenes: Array[PackedScene] = []
## A guaranteed-safe (hazard-free, gap-free) chunk used to fill the screen at
## the very start, so the player always begins on solid, flat ground and gets a
## moment to react before the first random obstacle arrives.
@export var opening_chunk: PackedScene
## World Y of the ground surface (where the top grass tiles sit).
@export var ground_y: float = 256.0
## Scroll speed at the very start, in pixels per second.
@export var start_speed: float = 230.0
## Scroll speed never climbs above this, so the run stays fair.
@export var max_speed: float = 360.0
## How much faster the world scrolls each second (the difficulty curve).
@export var speed_ramp: float = 2.0
## Spawn a new chunk once the spawning edge falls left of this X (off-screen).
@export var spawn_x: float = 1752.0
## Chunks fully left of this X are freed.
@export var despawn_x: float = -400.0

## Total pixels scrolled since the run began (used for the distance score).
var distance: float = 0.0
## Current scroll speed, in pixels per second.
var speed: float = 0.0

var _frontier: float = 0.0
var _last_index: int = -1
var _chunks: Array[Chunk] = []

func _ready() -> void:
	speed = start_speed
	# Pre-fill the screen with safe ground so there is always flat floor under
	# the player at the start of a run.
	_frontier = despawn_x
	while _frontier < spawn_x:
		_spawn_next(opening_chunk)

func _physics_process(delta: float) -> void:
	speed = minf(max_speed, speed + speed_ramp * delta)
	var step: float = speed * delta
	distance += step

	for chunk in _chunks:
		chunk.position.x -= step
	_frontier -= step

	while _frontier < spawn_x:
		_spawn_next()
	_despawn()

## Spawns one chunk at the right-hand frontier. Pass a scene to force a specific
## chunk (used for the safe opening); leave it null to pick a random one.
func _spawn_next(forced: PackedScene = null) -> void:
	var scene: PackedScene = forced
	if scene == null:
		if chunk_scenes.is_empty():
			return
		# Pick a random chunk, but never the same one twice in a row.
		var index: int = randi() % chunk_scenes.size()
		if chunk_scenes.size() > 1 and index == _last_index:
			index = (index + 1) % chunk_scenes.size()
		_last_index = index
		scene = chunk_scenes[index]

	var chunk: Chunk = scene.instantiate() as Chunk
	chunk.position = Vector2(_frontier, ground_y)
	add_child(chunk)
	_chunks.append(chunk)
	_frontier += chunk.width

func _despawn() -> void:
	for i in range(_chunks.size() - 1, -1, -1):
		var chunk: Chunk = _chunks[i]
		if chunk.position.x + chunk.width < despawn_x:
			chunk.queue_free()
			_chunks.remove_at(i)