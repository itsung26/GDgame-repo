## Handler for area signals
extends Node3D
@onready var pedestal_light: SpotLight3D = $"../pedestalLight"
@onready var last_room_light: OmniLight3D = $"../lastRoomLight"
@onready var pedestal_animation: AnimationPlayer = $"../PistolPedestal/PedestalAnimation"
@export var blaster_c_ih: MeshInstance3D
@export var fight_start_timer:Timer
@export var fight_start_delay:float
@onready var player:Player = Helper.getFirstInScene("Player")
var enemies_in_LastRoom = []
@export var can_check_for_no_enemies:bool = false
@onready var slight_pedestal_delay_light: Timer = $"../../../slightPedestalDelayLight"
@onready var enemy_spawn_handler: EnemySpawnHandler = $"../../../EnemySpawnHandler"
@onready var door_small_3: DoorSmall = $"../../../Doors/DoorSmall3"
@onready var game_name: Control = $"../../../gameName"
@onready var enemy_spawn_handler_2: EnemySpawnHandler = $"../../../EnemySpawnHandler2"
@onready var enemy_spawn_handler_3: EnemySpawnHandler = $"../../../EnemySpawnHandler3"


enum combatPhases {NONE, PHASE_ONE, PHASE_TWO, PHASE_THREE, DONE}
var combat_phase:combatPhases = combatPhases.NONE


func _ready() -> void:
	blaster_c_ih.visible = false

func _on_pistol_obtain_body_entered(plr: Player) -> void:
	print(str(plr) + " obtained pistol, conferring weapon authority")
	plr.pistol_switch_enabled = true
	plr.weapon_state = plr.weapon_states.PISTOL
	pedestal_animation.play("lower")
	slight_pedestal_delay_light.start()
	fight_start_timer.start(fight_start_delay)
	


func _on_pistol_hull_glow_body_entered(body: Player) -> void:
	blaster_c_ih.visible = true


func _on_pistol_hull_glow_body_exited(body: Player) -> void:
	blaster_c_ih.visible = false


func _on_fight_start_timer_timeout() -> void:
	var door_small_3: DoorSmall = $"../../../Doors/DoorSmall3"
	door_small_3.close()
	print("timer timeout, beginning combat phase")
	game_name.visible = false
	# spawn in the enemies and send the player to combat
	enemy_spawn_handler.spawnEnemies()
	can_check_for_no_enemies = true


func _on_enemy_counter_body_entered(enemy: Enemy) -> void:
	enemies_in_LastRoom.append(enemy)
	if combat_phase == combatPhases.NONE:
		combat_phase = combatPhases.PHASE_ONE

func _on_enemy_counter_body_exited(enemy: Enemy) -> void:
	enemies_in_LastRoom.erase(enemy)
	if enemies_in_LastRoom.is_empty():
		print("detected no more enemies in room")
		if combat_phase == combatPhases.PHASE_ONE:
			combat_phase = combatPhases.PHASE_TWO
			enemy_spawn_handler_2.spawnEnemies()
		elif combat_phase == combatPhases.PHASE_TWO:
			combat_phase = combatPhases.PHASE_THREE
			enemy_spawn_handler_3.spawnEnemies()
		elif combat_phase == combatPhases.PHASE_THREE:
			combat_phase = combatPhases.DONE
			var door_small_6: DoorSmall = $"../../../Doors/DoorSmall6"
			door_small_6.door_modes = 0 # STAYOPEN



func _on_slight_pedestal_delay_light_timeout() -> void:
	pedestal_light.visible = false
	last_room_light.visible = true
	game_name.visible = true


			


func _on_door_close_body_entered(player: Player) -> void:
	var checkpoint:Marker3D = Helper.getCheckPoint()
	checkpoint.global_position = Helper.getFirstInScene("checkpointPos3").global_position
	door_small_3.close()
	door_small_3.door_modes = 2 # LOCKED
	door_small_3.can_show_red_x = true
	$"../../../Doors/DoorSmall6".can_show_red_x = true
