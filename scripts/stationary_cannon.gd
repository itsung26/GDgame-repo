class_name CannonStationary extends Enemy

@onready var bullet_fire_interval: Timer = $BulletFireInterval
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var bullet_spawn_marker:Marker3D
@export var bullet_travel_direction_marker:Marker3D
@onready var bullet_spawn_pos:Vector3 = Vector3(bullet_spawn_marker.global_position)
@export var bullet_scene:PackedScene
@export var automatic_fire:bool
@export var automatic_fire_interval:float = 2.0

func _ready() -> void:
	if automatic_fire_interval <= 0.25:
		assert(false, "ERROR: CannonStationary fire interval is too short, increase to at least 0.26 seconds")
	bullet_fire_interval.wait_time = automatic_fire_interval

func fire():
	var bullet:EnergyBall = bullet_scene.instantiate()
	# fresh positions (in case markers moved)
	var spawn_pos := bullet_spawn_marker.global_position
	var target_pos := bullet_travel_direction_marker.global_position
	var dir := (target_pos - spawn_pos).normalized()
	bullet.initial_spawn_position = spawn_pos
	bullet.initial_direction = dir
	get_tree().current_scene.add_child(bullet)

func _on_bullet_fire_interval_timeout() -> void:
	if automatic_fire:
		animation_player.play("fire")
