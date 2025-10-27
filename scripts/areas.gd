## Handler for area signals
extends Node3D
@onready var pedestal_animation: AnimationPlayer = $"../PistolPedestal/PedestalAnimation"
@export var blaster_c_ih: MeshInstance3D
@export var fight_start_timer:Timer
@export var fight_start_delay:float
@onready var player:Player = Helper.getFirstInScene("Player")
var enemies_in_LastRoom = []
var can_check_for_no_enemies:bool = false

func _ready() -> void:
	blaster_c_ih.visible = false

func _on_pistol_obtain_body_entered(plr: Player) -> void:
	print(str(plr) + " obtained pistol, conferring weapon authority")
	plr.pistol_switch_enabled = true
	plr.weapon_state = plr.weapon_states.PISTOL
	pedestal_animation.play("lower")
	fight_start_timer.start(fight_start_delay)
	


func _on_pistol_hull_glow_body_entered(body: Player) -> void:
	blaster_c_ih.visible = true


func _on_pistol_hull_glow_body_exited(body: Player) -> void:
	blaster_c_ih.visible = false


func _on_fight_start_timer_timeout() -> void:
	# spawn in the enemies and send the player to combat
	player.IN_COMBAT = true


func _on_enemy_counter_body_entered(enemy: Enemy) -> void:
	enemies_in_LastRoom.append(enemy)

func _process(delta: float) -> void:
	if enemies_in_LastRoom.is_empty() and can_check_for_no_enemies:
		print("no enemies detected in area. deactivating combat state")
		player.IN_COMBAT = false
