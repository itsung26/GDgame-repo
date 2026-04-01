class_name Checkpoint
extends Resource
## This object stores checkpoint data, such as where the player goes when they respawn
## and the direction they are set to look when they respawn.


@export var respawn_position:Vector3
@export var pivot_rotation_x:float
@export var player_rotation_y:float


func _init(
	respawn_position:Vector3 = Vector3.ZERO,
	pivot_rotation_x:float = 0.0,
	player_rotation_y:float = 0.0
	) -> void:
	self.respawn_position = respawn_position
	self.pivot_rotation_x = pivot_rotation_x
	self.player_rotation_y = player_rotation_y
