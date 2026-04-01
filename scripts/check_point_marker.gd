class_name CheckPointMarker
extends Node3D
## Check point for player respawning. Only rough player position is retained upon respawn. Everything else,
## including health is reset to full.

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var part_left: MeshInstance3D = $partLeft
@onready var part_right: MeshInstance3D = $partRight
@onready var get_floor_pos_ray_cast: RayCast3D = $getFloorPosRayCast
@onready var collision_shape_3d: CollisionShape3D = $"Checkpoint collider/CollisionShape3D"

@export var active:bool = true:
	set = set_active
@export var respawn_player_position:Vector3

signal checkpoint_set


func set_active(new_active:bool) -> void:
	active = new_active
	if active:
		collision_shape_3d.disabled = false
		animation_player.play("RESET")
	else:
		collision_shape_3d.disabled = true
		animation_player.stop()


func _on_checkpoint_collider_body_entered(node:Node3D) -> void:
	if get_floor_pos_ray_cast.get_collider() == null:
		assert(false, "Cannot find a position to respawn at")
	respawn_player_position = get_floor_pos_ray_cast.get_collision_point()
	active = false
	animation_player.play("check point touch")
	var checkpoint:Checkpoint = Checkpoint.new(respawn_player_position)
	# push this checkpoint to the respawn system
	RespawnSystem.set_current_checkpoint(checkpoint)
	checkpoint_set.emit()
