@tool
class_name CombatArea
extends Area3D
## When the player enters this area, they are considered in combat. This area will keep track of child enemy spawners and spawn enemies in waves according to a preset order.
## TODO: door control capability after a door logic rewrite

@onready var delay_before_combat: Timer = $DelayBeforeCombat

signal player_entered_combat
signal player_finished_combat(wave:int)
signal player_died_in_combat(wave:int)


## Represents the current set of enemies to spawn. -1 when no waves have yet been triggered.
@export var current_wave:int = -1
@export var delay_before_first_wave:float = 1.0
var _enemy_wave_0: Array[EnemySpawnHandler] = []
@export var enemy_wave_0: Array[EnemySpawnHandler] = []
@export var enemy_wave_1:Array[EnemySpawnHandler] = []
@export var enemy_wave_2:Array[EnemySpawnHandler] = []
@export var enemy_wave_3:Array[EnemySpawnHandler] = []
@export var enemy_wave_4:Array[EnemySpawnHandler] = []
@export var enemy_wave_5:Array[EnemySpawnHandler] = []

## False when there are waves remaining. True when all waves have been completed.
var finished:bool = false
var active_enemies:Array[Enemy] = []
var tracked_player:Player


func _get_configuration_warnings() -> PackedStringArray:
	var warnings:PackedStringArray = []
	var all_null:bool = enemy_wave_0.all(func(i): return i == null)
	if enemy_wave_0.is_empty() or all_null:
		warnings.append("First wave is empty. Add at least one EnemySpawnHandler.")
	return warnings


func _ready() -> void:
	if not Engine.is_editor_hint():
		# ensure the first wave has enemies in it
		assert(not enemy_wave_0.is_empty())


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		update_configuration_warnings()

func _get_wave_handlers(wave_index:int) -> Array[EnemySpawnHandler]:
	match wave_index:
		0:
			return enemy_wave_0
		1:
			return enemy_wave_1
		2:
			return enemy_wave_2
		3:
			return enemy_wave_3
		4:
			return enemy_wave_4
		5:
			return enemy_wave_5
		_:
			return []


func advanceWave():
	current_wave += 1
	# clear any stale references from the previous wave
	active_enemies.clear()

	var wave_handlers:Array[EnemySpawnHandler] = _get_wave_handlers(current_wave)
	# If this wave has no handlers, treat the previous wave as the final one.
	if wave_handlers.is_empty():
		finished = true
		if tracked_player:
			tracked_player.setInCombat(false)
		var last_wave:int = max(current_wave - 1, 0)
		player_finished_combat.emit(last_wave)
		return

	# Spawn enemies for the current wave and begin tracking them.
	for enemy_spawner:EnemySpawnHandler in wave_handlers:
		# spawnEnemies() is a coroutine (uses await internally), so we must await it to
		# receive the Array[Enemy] it eventually returns.
		var spawned_enemies:Array[Enemy] = await enemy_spawner.spawnEnemies()
		for enemy:Enemy in spawned_enemies:
			if enemy and not active_enemies.has(enemy):
				active_enemies.append(enemy)
				# When the enemy leaves the tree (usually on death), update tracking.
				enemy.tree_exited.connect(_on_enemy_tree_exited.bind(enemy))


func resetWaves():
	current_wave = -1
	active_enemies.clear()
	finished = false


func _on_body_entered(player:Player) -> void:
	# if all waves are already cleared, dont do anything
	if finished:
		return
	tracked_player = player
	player.setInCombat(true)
	player_entered_combat.emit()
	# Track when the player dies while in this combat area.
	if not player.entered_player_state.is_connected(_on_player_entered_state):
		player.entered_player_state.connect(_on_player_entered_state)
	delay_before_combat.start(delay_before_first_wave)

func _on_delay_before_combat_timeout() -> void:
	if current_wave == -1:
		advanceWave()


func _on_enemy_tree_exited(enemy:Enemy) -> void:
	# Enemy from current wave has been removed from the scene (typically due to death).
	if active_enemies.has(enemy):
		active_enemies.erase(enemy)
	# When no enemies from this wave remain and we are not yet finished, advance.
	if active_enemies.is_empty() and not finished:
		advanceWave()


func _on_player_entered_state(new_player_state:Player.player_states, previous_player_state:Player.player_states) -> void:
	if new_player_state == Player.player_states.DEAD and tracked_player and tracked_player.in_combat:
		player_died_in_combat.emit(current_wave)
