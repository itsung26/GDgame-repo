class_name CombatArea
extends Area3D
## When the player enters this area, they are considered in combat. This area will keep track of child enemy spawners and spawn enemies in waves according to a preset order. The matrix holds the waves, and the waves hold enemy spawners.
## TODO: door control capability after a door logic rewrite

@onready var delay_before_combat: Timer = $DelayBeforeCombat

signal player_entered_combat
signal player_finished_combat(wave:int)
signal player_died_in_combat(wave:int)


## Represents the current set of enemies to spawn. -1 when no waves have yet been triggered.
@export var current_wave:int = -1
@export var delay_before_first_wave:float = 1.0
@export var enemy_wave_0:Array[EnemySpawnHandler] = []
@export var enemy_wave_1:Array[EnemySpawnHandler] = []
@export var enemy_wave_2:Array[EnemySpawnHandler] = []
@export var enemy_wave_3:Array[EnemySpawnHandler] = []
@export var enemy_wave_4:Array[EnemySpawnHandler] = []
@export var enemy_wave_5:Array[EnemySpawnHandler] = []

var enemy_waves_matrix:Array[Array] = []
## False when there are waves remaining. True when all waves have been completed.
var finished:bool = false

func _ready() -> void:
	enemy_waves_matrix.append_array(enemy_wave_0)
	enemy_waves_matrix.append_array(enemy_wave_1)
	enemy_waves_matrix.append_array(enemy_wave_2)
	enemy_waves_matrix.append_array(enemy_wave_3)
	enemy_waves_matrix.append_array(enemy_wave_4)
	enemy_waves_matrix.append_array(enemy_wave_5)
	# ensure the first wave has enemies in it
	assert(not enemy_wave_0.is_empty())


func advanceWave():
	current_wave += 1
	# iterate through waves in the matrix
	for enemy_wave:Array in enemy_waves_matrix:
		# if the wave has spawners in it
		if not enemy_wave.is_empty():
			# if the wave matches the current wave, spawn enemies for the current wave
			match current_wave:
				0:
					for enemy_spawner:EnemySpawnHandler in enemy_wave_0:
						enemy_spawner.spawnEnemies()
				1:
					for enemy_spawner:EnemySpawnHandler in enemy_wave_1:
						enemy_spawner.spawnEnemies()
				2:
					for enemy_spawner:EnemySpawnHandler in enemy_wave_2:
						enemy_spawner.spawnEnemies()
				3:
					for enemy_spawner:EnemySpawnHandler in enemy_wave_3:
						enemy_spawner.spawnEnemies()
				4:
					for enemy_spawner:EnemySpawnHandler in enemy_wave_4:
						enemy_spawner.spawnEnemies()
				5:
					for enemy_spawner:EnemySpawnHandler in enemy_wave_5:
						enemy_spawner.spawnEnemies()


func resetWaves():
	current_wave = -1


func _on_body_entered(player:Player) -> void:
	# if all waves are already cleared, dont do anything
	if finished:
		return
	player.in_combat = true
	delay_before_combat.start(delay_before_first_wave)

func _on_delay_before_combat_timeout() -> void:
	if current_wave == -1:
		advanceWave()
