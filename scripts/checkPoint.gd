class_name checkPoint
extends Node3D
## Check point for player respawning. Only rough player position is retained upon respawn. Everything else,
## including health is reset to full.

@onready var player:Player = get_tree().get_first_node_in_group("players")
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var checkpoint_collider: Area3D = $"Checkpoint collider"
@onready var part_left: MeshInstance3D = $partLeft
@onready var part_right: MeshInstance3D = $partRight
@onready var get_floor_pos_ray_cast: RayCast3D = $getFloorPosRayCast

@export var active:bool = true
@export var respawn_player_position:Vector3

func _process(delta: float) -> void:
	if active:
		checkpoint_collider.monitoring = true
	else:
		checkpoint_collider.monitoring = false

func _on_checkpoint_collider_body_entered(player:Player) -> void:
	if get_floor_pos_ray_cast.get_collider() == null:
		assert(false, "Checkpoint is not on floor.")
		return
	respawn_player_position = get_floor_pos_ray_cast.get_collision_point()
	
	active = false
	animation_player.play("check point touch")
	player.setCheckPoint(self)
