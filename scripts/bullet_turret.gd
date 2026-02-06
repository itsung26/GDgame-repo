class_name BulletTurret
extends Enemy

@onready var head_look_mod: LookAtModifier3D = $"bullet turret/Armature/Skeleton3D/HeadLookMod"
@onready var gun_l_look_mod: LookAtModifier3D = $"bullet turret/Armature/Skeleton3D/GunLLookMod"
@onready var gun_r_look_mod: LookAtModifier3D = $"bullet turret/Armature/Skeleton3D/GunRLookMod"
@onready var offline_look_target: Marker3D = $OfflineLookTarget
@onready var seeking_timer: Timer = $SeekingTimer
@onready var laser: Node3D = $"bullet turret/Armature/Skeleton3D/Laser/laser"
@onready var burst_fire_timer: Timer = $BurstFireTimer
@onready var fire_cool_down_timer: Timer = $FireCoolDownTimer
@onready var fire_origin_l: Marker3D = $"bullet turret/Armature/Skeleton3D/GunLAttatchment/FireOriginL"
@onready var fire_origin_r: Marker3D = $"bullet turret/Armature/Skeleton3D/GunRAttatchment/FireOriginR"
@onready var fire_dir_l: RayCast3D = $"bullet turret/Armature/Skeleton3D/GunLAttatchment/FireDirL"
@onready var fire_dir_r: RayCast3D = $"bullet turret/Armature/Skeleton3D/GunRAttatchment/FireDirR"
@onready var state_debug_text: StateDebugText = $StateDebugText
@onready var state_debug_text_2: StateDebugText = $StateDebugText2
@onready var player_detection: Area3D = $PlayerDetection
@onready var physical_bone_simulator_3d: PhysicalBoneSimulator3D = $"bullet turret/Armature/Skeleton3D/PhysicalBoneSimulator3D"
@onready var phys_collider: CollisionShape3D = $PhysCollider

# Load the actual bullet.
const bullet_scene:PackedScene = preload("res://scenes/energy_ball.tscn")

enum enemy_states {OFFLINE, SEEKING, TRACKING, DESTROYED}
var enemy_state:enemy_states:
	set = setEnemyState
	
enum enemy_attack_states {COOLDOWN, BURSTING, DISARMED}
var enemy_attack_state:enemy_attack_states:
	set = setEnemyAttackState
	
@export var turning_speed:float = 1.0
@export var time_before_stop_seeking:float = 5.0
var initial_rotation:float
var player_in_detection:bool = false
var last_known_player_pos:Vector3 = Vector3.ZERO
## The maximum angle that the turret can oscillate to when seeking.
@export var seeking_max_angle_range:float
## The speed of oscillation when seeking (oscillations per second)
@export var seeking_oscillation_speed:float = 1.0
var last_y_rotation:float = global_rotation.y
var seeking_oscillation_time:float = 0.0
@export var cooldown_between_bursts:float = 1.0
@export var burst_duration_time:float = 2.0
@export var bullet_delay:float = 0.5
var _elapsed_time:float = 0.0

func setEnemyState(new_enemy_state:enemy_states):
	var previous_enemy_state:enemy_states = enemy_state
	enemy_state = new_enemy_state
	
	# prevent same state switching
	if previous_enemy_state == new_enemy_state:
		return
	
	# SEEKING STATE
	# Reset oscillation time when entering SEEKING state
	# clear bones too
	if new_enemy_state == enemy_states.SEEKING:
		seeking_oscillation_time = 0.0
		clearBoneLookTargets()
	
	# OFFLINE state
	if new_enemy_state == enemy_states.OFFLINE:
		setBoneLookTargets(offline_look_target.get_path())
	if previous_enemy_state == enemy_states.OFFLINE:
		pass
	
	# TRACKING state
	if new_enemy_state == enemy_states.TRACKING:
		laser.visible = true
		setBoneLookTargets(player.camera_3d.get_path())
	if previous_enemy_state == enemy_states.TRACKING:
		laser.visible = false
	
	# DESTROYED state
	if new_enemy_state == enemy_states.DESTROYED:
		clearBoneLookTargets()
		setEnemyAttackState(enemy_attack_states.DISARMED)
		laser.visible = false
		player_detection.monitoring = false
		player_detection.monitorable = false
		phys_collider.disabled = true
		physical_bone_simulator_3d.active = true
	
func setEnemyAttackState(new_enemy_attack_state:enemy_attack_states):
	var previous_enemy_attack_state:enemy_attack_states = enemy_attack_state
	enemy_attack_state = new_enemy_attack_state
	
	if previous_enemy_attack_state == new_enemy_attack_state:
		return
		
	# COOLDOWN state
	if new_enemy_attack_state == enemy_attack_states.COOLDOWN:
		fire_cool_down_timer.start(cooldown_between_bursts)
	if previous_enemy_attack_state == enemy_attack_states.COOLDOWN:
		# stop the timer if the state is left early
		fire_cool_down_timer.stop()
		
	# BURSTING state
	if new_enemy_attack_state == enemy_attack_states.BURSTING:
		burst_fire_timer.start(burst_duration_time)
	if previous_enemy_attack_state == enemy_attack_states.BURSTING:
		# stop the timer if the state is left early
		burst_fire_timer.stop()
	
	

func getEnemyStateFormatted() -> String:
	return enemy_states.keys()[enemy_state]

func _ready() -> void:
	initial_rotation = global_rotation.y
	setEnemyState(enemy_states.OFFLINE)
	setEnemyAttackState(enemy_attack_states.DISARMED)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug func"):
		var g:Array[Node] = get_tree().get_nodes_in_group(&"physics bones")
		var phys_sim_bones:Array[PhysicalBone3D]
		phys_sim_bones.append_array(g)
		for bone:PhysicalBone3D in phys_sim_bones:
			bone.top_level = true
			bone.add_collision_exception_with(player)
		physical_bone_simulator_3d.physical_bones_start_simulation()
	
	# update the state ddebug text labels
	state_debug_text.updateStateReadout(enemy_state, enemy_states)
	state_debug_text_2.updateStateReadout(enemy_attack_state, enemy_attack_states)
	
	# update the last known player pos
	if player_in_detection:
		last_known_player_pos = player.global_position
	
#region Enemy state behavior
	# main state behaviour
	if behavior_enabled:
		# update the last y rotation if turret is not actively seeking
		if enemy_state != enemy_states.SEEKING:
			last_y_rotation = global_rotation.y
		
		if enemy_state == enemy_states.TRACKING:
			var rot_looking_at_player:Vector3 = getVec3LookingAtTarget(player.global_position)
			rotation.y = rotate_toward(rotation.y, rot_looking_at_player.y, turning_speed * delta)
		elif enemy_state == enemy_states.OFFLINE:
			rotation.y = rotate_toward(rotation.y, initial_rotation, turning_speed * delta)
		elif enemy_state == enemy_states.SEEKING:
			# Accumulate time for oscillation
			seeking_oscillation_time += delta
			# Rotate sinusoidally on y axis, oscillating around last_y_rotation
			var oscillation_offset: float = deg_to_rad(seeking_max_angle_range) * sin(seeking_oscillation_time * seeking_oscillation_speed * TAU)
			var target_rotation: float = last_y_rotation + oscillation_offset
			rotation.y = rotate_toward(rotation.y, target_rotation, turning_speed * delta)
	else:
		setEnemyState(enemy_states.OFFLINE)
#endregion
	
#region Enemy attack state behavior
	# main attack state behaviour
	if behavior_enabled:
		if enemy_attack_state == enemy_attack_states.BURSTING:
			_elapsed_time += delta
			if _elapsed_time >= bullet_delay:
				_elapsed_time = 0.0
				fireSingleBullet("GUNLEFT")
				fireSingleBullet("GUNRIGHT")
	else:
		setEnemyAttackState(enemy_attack_states.DISARMED)
#endregion

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

## Fires a single bullet in the direction the respective raycast is pointing.
## Expects a normalized vector.
## Bullet is spawned from the [code]gun[/code] passed. Valid values are
## [code]"GUNLEFT"[/code] and [code]"GUNRIGHT"[/code].
func fireSingleBullet(gun:String) -> void:
	# initialize vars to later be set depending on which gun was selected.
	var dir:Vector3 = Vector3.ZERO
	var bullet_spawn_pos:Vector3
	if gun == "GUNLEFT":
		bullet_spawn_pos = fire_origin_l.global_position
		dir = fire_dir_l.getDir()
	elif gun == "GUNRIGHT":
		bullet_spawn_pos = fire_origin_r.global_position
		dir = fire_dir_r.getDir()
	
	# instance and spawn the bullet
	var bullet:EnergyBall = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet._setup(bullet_spawn_pos, dir, self)

func _on_hurt(damage: float, damage_type: Enemy.damage_types) -> void:
	if enemy_state == enemy_states.OFFLINE:
		seeking_timer.start(time_before_stop_seeking)
		setEnemyState(enemy_states.SEEKING)

func _on_player_detection_body_entered(player:Player) -> void:
	player_in_detection = true
	if enemy_state != enemy_states.DESTROYED:
		setEnemyState(enemy_states.TRACKING)
		setEnemyAttackState(enemy_attack_states.COOLDOWN)


func _on_player_detection_body_exited(player:Player) -> void:
	player_in_detection = false
	if enemy_state != enemy_states.DESTROYED:
		seeking_timer.start(time_before_stop_seeking)
		setEnemyState(enemy_states.SEEKING)
		setEnemyAttackState(enemy_attack_states.DISARMED)

func _on_seeking_timer_timeout() -> void:
	if enemy_state == enemy_states.SEEKING:
		setEnemyState(enemy_states.OFFLINE)

## Called when the cooldown ends.
func _on_fire_cool_down_timer_timeout() -> void:
	if enemy_attack_state == enemy_attack_states.COOLDOWN:
		setEnemyAttackState(enemy_attack_states.BURSTING)
	else:
		assert(false, "ERROR: Illegal state transition!")

## Called when the burst sequence ends.
func _on_burst_fire_timer_timeout() -> void:
	if enemy_attack_state == enemy_attack_states.BURSTING:
		setEnemyAttackState(enemy_attack_states.COOLDOWN)
	else:
		assert(false, "ERROR: Illegal state transition!")
