class_name EnemyProjectile extends RigidBody3D

@export var damage_to_player:float
@export var damage_to_enemies:float
@export var travel_speed:float = 16
@export var initial_direction:Vector3
@export var initial_spawn_position:Vector3
@export var parriable:bool = true
@export var can_despawn:bool = true
@export var despawn_time:float = 10.0
@export var has_been_parried:bool = false
