class_name BulletTurret
extends Enemy

@onready var head_look_mod: LookAtModifier3D = $"bullet turret/Armature/Skeleton3D/HeadLookMod"
@onready var gun_look_mod_l: LookAtModifier3D = $"bullet turret/Armature/Skeleton3D/GunLookMod_L"
@onready var gun_look_mod_r: LookAtModifier3D = $"bullet turret/Armature/Skeleton3D/GunLookMod_R"

@export var turning_speed:float = 1.0
var player_in_detection:bool = false

enum enemy_states {OFFLINE, SEEKING, FIRING}
var enemy_state:enemy_states = enemy_states.OFFLINE:
	set = setEnemyState
	
func setEnemyState(new_enemy_state:enemy_states):
	var previous_enemy_state:enemy_states = enemy_state
	enemy_state = new_enemy_state
	
	# prevent same state switching
	if previous_enemy_state == new_enemy_state:
		return
	
func _process(delta: float) -> void:
	if behavior_enabled:
		var rot_looking_at_player:Vector3 = getVec3LookingAtTarget(player.global_position)
		rotation.y = move_toward(rotation.y, rot_looking_at_player.y, turning_speed * delta)

func setBoneLookTargets(target_node:NodePath):
	head_look_mod.target_node = target_node
	gun_look_mod_l.target_node = target_node
	gun_look_mod_r.target_node = target_node


func _on_player_detection_body_entered(player:Player) -> void:
	player_in_detection = true


func _on_player_detection_body_exited(player:Player) -> void:
	player_in_detection = false
