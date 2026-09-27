class_name Chunk
extends Node2D

## One slice of ground in the endless runner.
##
## The ChunkSpawner slides slices from the right edge of the screen to the left.
## Each slice carries its own ground tiles plus any hazards built into it.
## `width` (in pixels) tells the spawner how far along X the next slice starts,
## so slices sit flush against each other and the only gaps are the ones that
## were built on purpose.

@export var width: float = 320.0