class_name Checkpoint
extends Resource
## This object stores checkpoint data, such as where the player goes when they respawn
## and the direction they are set to look when they respawn.


@export var respawn_location:Vector3
@export var respawn_input_allowments:bool


func _init(respawn_location:Vector3 = Vector3.ZERO) -> void:
	self.respawn_location = respawn_location
