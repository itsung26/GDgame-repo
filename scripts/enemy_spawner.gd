extends AnimatableBody3D
@onready var timer: Timer = $Timer
@onready var spawner_anims: AnimationPlayer = $SpawnerAnims
const ENEMY = preload("res://scenes/enemy.tscn")
@onready var spawn_point: Node3D = $SpawnPoint

var e
var map_enviroment
var enabled = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	map_enviroment = get_tree().root
	spawner_anims.play("spawner_open")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	pass

func spawnEnemyWeak():
	if enabled:
		e = ENEMY.instantiate()
		e.global_position = spawn_point.global_position
		map_enviroment.add_child(e)

func _on_timer_timeout() -> void:
	spawner_anims.play("spawner_open")
	
func playSpawnerClose():
	spawner_anims.play("spawner_close")
