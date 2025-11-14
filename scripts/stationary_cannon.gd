class_name CannonStationary extends Enemy

@onready var bullet_fire_interval: Timer = $BulletFireInterval
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var bullet_spawn_marker:Marker3D
@export var bullet_travel_direction_marker:Marker3D
@export var bullet_scene:PackedScene
@export var automatic_fire:bool
@export var automatic_fire_interval:float = 2.0

func _ready() -> void:
	if automatic_fire_interval <= 0.25:
		assert(false, "ERROR: CannonStationary fire interval is too short, increase to at least 0.26 seconds")
	bullet_fire_interval.wait_time = automatic_fire_interval

func fire():
	var bullet:EnergyBall = bullet_scene.instantiate()
	bullet._setup(bullet_spawn_marker.global_position, bullet_travel_direction_marker.global_position - bullet_spawn_marker.global_position)
	get_tree().current_scene.add_child(bullet)

func _on_bullet_fire_interval_timeout() -> void:
	if automatic_fire:
		animation_player.play("fire")
