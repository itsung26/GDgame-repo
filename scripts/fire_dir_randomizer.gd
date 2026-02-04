@tool
extends Node

@onready var fire_dir_l: RayCast3D = $"../bullet turret/Armature/Skeleton3D/GunLAttatchment/FireDirL"
@onready var fire_dir_r: RayCast3D = $"../bullet turret/Armature/Skeleton3D/GunRAttatchment/FireDirR"
@onready var time_between_dir_shuffles: Timer = $TimeBetweenDirShuffles

@export var random_rot_min:float = -2 * PI # radians
@export var random_rot_max:float = 2 * PI # radians
@export var delay:float = 0.1 # seconds

func _ready() -> void:
	time_between_dir_shuffles.start(delay)

func _on_time_between_dir_shuffles_timeout() -> void:
	fire_dir_l.rotation.z = randf_range(random_rot_min, random_rot_max)
	time_between_dir_shuffles.start(delay)
