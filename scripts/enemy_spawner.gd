extends AnimatableBody3D
@onready var spawner_anims: AnimationPlayer = $SpawnerAnims
const ENEMY = preload("res://scenes/enemy.tscn")
@onready var spawn_point: Node3D = $SpawnPoint
@onready var enemies: Node3D = $"../../Enemies"

var e
var map_enviroment

@export_category("Spawner Settings")
@export var enabled := true
@export var spawn_interval := 15.0
@export var max_enemy_count := 25
@export var initial_spawn_delay := 5.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Timer.wait_time = spawn_interval
	map_enviroment = get_tree().root
	if enabled and not enemies.get_children().size() > max_enemy_count:
		spawner_anims.play("spawner_open")

func spawnEnemyWeak():
	e = ENEMY.instantiate()
	enemies.add_child(e)
	e.global_position = spawn_point.global_position

func _on_timer_timeout() -> void:
	if enabled and not enemies.get_children().size() > max_enemy_count:
		spawner_anims.play("spawner_open")
	
func playSpawnerClose():
	spawner_anims.play("spawner_close")
