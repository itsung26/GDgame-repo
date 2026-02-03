class_name BulletTurret
extends Enemy

@onready var head_look_mod: LookAtModifier3D = $"bullet turret/Armature/Skeleton3D/HeadLookMod"
@onready var gun_l_look_mod: LookAtModifier3D = $"bullet turret/Armature/Skeleton3D/GunLLookMod"
@onready var gun_r_look_mod: LookAtModifier3D = $"bullet turret/Armature/Skeleton3D/GunRLookMod"
@onready var offline_look_target: Marker3D = $OfflineLookTarget
@onready var seeking_timer: Timer = $SeekingTimer
@onready var laser: MeshInstance3D = $"bullet turret/Armature/Skeleton3D/Laser/laser"

@export var turning_speed:float = 1.0
@export var time_before_stop_seeking:float = 5.0
var initial_rotation:float
var player_in_detection:bool = false
var last_known_player_pos:Vector3 = Vector3.ZERO
## The maximum angle that the turret can oscillate to when seeking.
@export var seeking_max_angle_range:float
var last_y_rotation:float = global_rotation.y

enum enemy_states {OFFLINE, SEEKING, FIRING, DESTROYED}
var enemy_state:enemy_states = enemy_states.OFFLINE:
	set = setEnemyState
	
func setEnemyState(new_enemy_state:enemy_states):
	var previous_enemy_state:enemy_states = enemy_state
	enemy_state = new_enemy_state
	
	# prevent same state switching
	if previous_enemy_state == new_enemy_state:
		return
	
	# OFFLINE state
	if new_enemy_state == enemy_states.OFFLINE:
		setBoneLookTargets(offline_look_target.get_path())
	if previous_enemy_state == enemy_states.OFFLINE:
		pass
	
	# FIRING state
	if new_enemy_state == enemy_states.FIRING:
		laser.visible = true
		setBoneLookTargets(player.camera_3d.get_path())
	if previous_enemy_state == enemy_states.FIRING:
		laser.visible = false

func getEnemyStateFormatted() -> String:
	return enemy_states.keys()[enemy_state]

func _ready() -> void:
	initial_rotation = global_rotation.y

func _process(delta: float) -> void:
	Debug.log(global_rotation.y)
	# update the last known player pos
	if player_in_detection:
		last_known_player_pos = player.global_position
	
	# main state behaviour
	if behavior_enabled:
		# update the last y rotation if turret is not actively seeking
		if enemy_state != enemy_states.SEEKING:
			last_y_rotation = global_rotation.y
		
		if enemy_state == enemy_states.FIRING:
			var rot_looking_at_player:Vector3 = getVec3LookingAtTarget(player.global_position)
			rotation.y = rotate_toward(rotation.y, rot_looking_at_player.y, turning_speed * delta)
		elif enemy_state == enemy_states.OFFLINE:
			rotation.y = rotate_toward(rotation.y, initial_rotation, turning_speed * delta)
		elif enemy_state == enemy_states.SEEKING:
			# rotate sinusodialy on y axis, where the midlevel is the last rotation.y
			rotation.y = rotate_toward(rotation.y, deg_to_rad(seeking_max_angle_range) * sin(delta) + last_y_rotation, turning_speed * delta)
	else:
		setEnemyState(enemy_states.OFFLINE)

func _killEnemy():
	if player.getHookedTarget() == self:
		# unhook grapple if the hooked enemy is self
		player.set_action_state(player.action_states.IDLE)
	
	setEnemyState(enemy_states.DESTROYED)

func setBoneLookTargets(target_node:NodePath) -> void:
	if target_node:
		head_look_mod.target_node = target_node
		gun_l_look_mod.target_node = target_node
		gun_r_look_mod.target_node = target_node

func getBoneLookTargets() -> Node3D:
	var a:NodePath = head_look_mod.target_node
	return get_node(a)

func clearBoneLookTargets() -> void:
		head_look_mod.target_node = ""
		gun_l_look_mod.target_node = ""
		gun_r_look_mod.target_node = ""

func _on_hurt(damage: float) -> void:
	if enemy_state == enemy_states.OFFLINE:
		seeking_timer.start(time_before_stop_seeking)
		setEnemyState(enemy_states.SEEKING)

func _on_player_detection_body_entered(player:Player) -> void:
	player_in_detection = true
	setEnemyState(enemy_states.FIRING)


func _on_player_detection_body_exited(player:Player) -> void:
	player_in_detection = false
	setEnemyState(enemy_states.SEEKING)

func _on_seeking_timer_timeout() -> void:
	if enemy_state == enemy_states.SEEKING:
		setEnemyState(enemy_states.OFFLINE)
