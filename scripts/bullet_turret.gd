## A stationary enemy turret that tracks the player and fires burst-based bullet attacks.
## Uses bone look modifiers for aiming and supports ragdoll/death smoke effects when destroyed.
class_name BulletTurret
extends Enemy

## Look-at modifier that controls the turret head aiming.
@onready var head_look_mod: LookAtModifier3D = $"bullet turret/Armature/Skeleton3D/HeadLookMod"
## Look-at modifier that controls the left gun aiming.
@onready var gun_l_look_mod: LookAtModifier3D = $"bullet turret/Armature/Skeleton3D/GunLLookMod"
## Look-at modifier that controls the right gun aiming.
@onready var gun_r_look_mod: LookAtModifier3D = $"bullet turret/Armature/Skeleton3D/GunRLookMod"
## World-space marker the turret looks at while offline/idling.
@onready var offline_look_target: Marker3D = $OfflineLookTarget
## Timer that limits how long the turret will keep seeking before going offline.
@onready var seeking_timer: Timer = $SeekingTimer
## Laser mesh/beam shown while tracking the player.
@onready var laser: Node3D = $"bullet turret/Armature/Skeleton3D/Laser/laser"
## Timer controlling the duration of a burst sequence.
@onready var burst_fire_timer: Timer = $BurstFireTimer
## Timer controlling the cooldown period between burst sequences.
@onready var fire_cool_down_timer: Timer = $FireCoolDownTimer
## World-space bullet spawn origin for the left gun.
@onready var fire_origin_l: Marker3D = $"bullet turret/Armature/Skeleton3D/GunLAttatchment/FireOriginL"
## World-space bullet spawn origin for the right gun.
@onready var fire_origin_r: Marker3D = $"bullet turret/Armature/Skeleton3D/GunRAttatchment/FireOriginR"
## Raycast used to determine the firing direction for the left gun.
@onready var fire_dir_l: RayCast3D = $"bullet turret/Armature/Skeleton3D/GunLAttatchment/FireDirL"
## Raycast used to determine the firing direction for the right gun.
@onready var fire_dir_r: RayCast3D = $"bullet turret/Armature/Skeleton3D/GunRAttatchment/FireDirR"
## Debug label that displays the current enemy state.
@onready var state_debug_text: StateDebugText = $StateDebugText
## Debug label that displays the current attack state.
@onready var state_debug_text_2: StateDebugText = $StateDebugText2
## Area used to detect when the player enters or exits the turret's engagement range.
@onready var player_detection: Area3D = $PlayerDetection
## Simulator that enables physics-based ragdoll behaviour on the skeleton.
@onready var physical_bone_simulator_3d: PhysicalBoneSimulator3D = $"bullet turret/Armature/Skeleton3D/PhysicalBoneSimulator3D"
## Main collision shape used while the turret is alive.
@onready var phys_collider: CollisionShape3D = $PhysCollider
@onready var phys_sim_bones:Array[PhysicalBone3D] = []
## Timer that turns off the death smoke after a delay.
@onready var death_smoke_timer: Timer = $DeathSmokeTimer
## The armature.
@onready var skeleton_3d: Skeleton3D = $"bullet turret/Armature/Skeleton3D"
@onready var gun_l_attatchment: BoneAttachment3D = $"bullet turret/Armature/Skeleton3D/GunLAttatchment"
@onready var gun_r_attatchment: BoneAttachment3D = $"bullet turret/Armature/Skeleton3D/GunRAttatchment"
@onready var blood_emitter: PhysicalParticleEmitter = $"bullet turret/Armature/Skeleton3D/BloodEmitter"

## Packed scene for the projectile this turret fires.
const bullet_scene:PackedScene = preload("res://scenes/energy_ball.tscn")

## High-level behaviour states for the turret.
enum enemy_states {OFFLINE, SEEKING, TRACKING, DESTROYED}
## Current high-level behaviour state.
var enemy_state:enemy_states:
	set = setEnemyState
	
## Attack sub-state for handling cooldown / bursting / disabled behaviour.
enum enemy_attack_states {COOLDOWN, BURSTING, DISARMED}
## Current attack state.
var enemy_attack_state:enemy_attack_states:
	set = setEnemyAttackState
	
## Rotation speed (rad/s) when turning toward the player or idle direction.
@export var turning_speed:float = 3.0
## Time in seconds the turret will continue seeking after losing the player.
@export var time_before_stop_seeking:float = 7.5
## The maximum angle that the turret can oscillate to when seeking.
@export var seeking_max_angle_range:float = 25.0
## The speed of oscillation when seeking (oscillations per second)
@export var seeking_oscillation_speed:float = 0.25
## Time in seconds between burst sequences.
@export var cooldown_between_bursts:float = 1.5
## Length of time in seconds that a single burst lasts.
@export var burst_duration_time:float = 1.0
## Delay between individual bullets while bursting.
@export var bullet_delay:float = 0.21
## Scalar force applied to ragdoll bones on death.
@export var ragdoll_force_applied:float = 6.667
## Duration in seconds for which death smoke particles remain active.
@export var death_smoke_duration:float = 3.0
@export var death_smoke_particles:Array[GPUParticles3D]

## Initial yaw rotation used as the offline/idle facing direction.
var initial_rotation:float
## True while the player is inside the detection area.
var player_in_detection:bool = false
## Last known player position (updated while the player is detected).
var last_known_player_pos:Vector3 = Vector3.ZERO
## Last stored yaw used as a centre point for seeking oscillation.
var last_y_rotation:float = global_rotation.y
## Accumulated time for computing the seeking oscillation phase.
var seeking_oscillation_time:float = 0.0
## Accumulated time used to schedule bullet firing during a burst.
var _elapsed_time:float = 0.0

## Sets the current enemy state and performs any necessary enter/exit side effects.
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
		blood_emitter.emitting = true
		ragdoll(ragdoll_force_applied)
		death_smoke_timer.start(death_smoke_duration)
		for smoke_particle:GPUParticles3D in death_smoke_particles:
			smoke_particle.emitting = true
		# Hand off ragdoll to the world and free this enemy after starting death effects.
		finalize_death()
	
## Sets the current enemy attack state and performs enter/exit side effects.
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
	
	

## Returns the current enemy state as its enum name string.
func getEnemyStateFormatted() -> String:
	return enemy_states.keys()[enemy_state]

## Initializes cached node references, default states, and particle visibility.
func _ready() -> void:
	phys_sim_bones.append_array(physical_bone_simulator_3d.get_children())
	initial_rotation = global_rotation.y
	setEnemyState(enemy_states.OFFLINE)
	setEnemyAttackState(enemy_attack_states.DISARMED)
	for smoke_particle:GPUParticles3D in death_smoke_particles:
		smoke_particle.emitting = false

## Per-frame update for driving state/attack behaviour and debug UI.
## Handles rotation, seeking oscillation, and death smoke billboard behaviour.
func _process(delta: float) -> void:
	# update the state debug text labels
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
		elif enemy_state == enemy_states.DESTROYED:
			for smoke_particle:GPUParticles3D in death_smoke_particles:
				if smoke_particle:
					smoke_particle.look_at(smoke_particle.global_position + Vector3(0.0, 1.0, 0.0) + Vector3(0.0001, 0.0, 0.0))
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

## Kills this enemy and triggers the DESTROYED state.
func _killEnemy():
	setEnemyState(enemy_states.DESTROYED)

## Assigns a look target for the head and gun look modifiers.
func setBoneLookTargets(target_node:NodePath) -> void:
	if target_node:
		head_look_mod.target_node = target_node
		gun_l_look_mod.target_node = target_node
		gun_r_look_mod.target_node = target_node

## Returns the current node used as the bone look target.
## Assumes the target node path is valid in the scene tree.
func getBoneLookTargets() -> Node3D:
	var a:NodePath = head_look_mod.target_node
	return get_node(a)

## Clears any bone look targets so that the modifiers stop aiming at a specific node.
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
	bullet.setup(bullet_spawn_pos, dir, self)

## Enables ragdoll simulation, re-parents the simulator to the world, and applies an outward force
## to all physics bones.
func ragdoll(force_applied:float) -> void:
	# Free all unnecessary nodes in this turret's rig only.
	var nodes_to_free:Array[Node] = []
	nodes_to_free.append(head_look_mod)
	nodes_to_free.append(gun_l_look_mod)
	nodes_to_free.append(gun_r_look_mod)
	nodes_to_free.append(laser)
	nodes_to_free.append(gun_l_attatchment)
	nodes_to_free.append(gun_r_attatchment)
	
	for node:Node in nodes_to_free:
		node.queue_free()
	
	# Move the cleaned rig to the main scene so it is not freed with the enemy and
	# the ragdoll sim will stil work. Preserve the global transform so the pose
	# doesn't pop when changing parents.
	var world_root:Node = get_tree().current_scene
	if world_root and skeleton_3d.get_parent():
		var old_global:Transform3D = skeleton_3d.global_transform
		skeleton_3d.get_parent().remove_child(skeleton_3d)
		world_root.add_child(skeleton_3d)
		skeleton_3d.global_transform = old_global
		skeleton_3d.name = "BulletTurretRagdollRig"

	# After reparenting, make bones no-collide with the player and start physics
	for bone:PhysicalBone3D in phys_sim_bones:
		bone.add_collision_exception_with(player)
	physical_bone_simulator_3d.physical_bones_start_simulation()
	# apply a random force to each bone
	for bone:PhysicalBone3D in phys_sim_bones:
		var random_direction:Vector3 = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		bone.linear_velocity += random_direction * force_applied
	

## Frees the enemy node after ragdoll has been set up and re-parented.
func finalize_death() -> void:
	call_deferred("queue_free")

## Hurt callback: wakes the turret and begins seeking if hit while offline.
func _on_hurt(damage: float, damage_type: Enemy.damage_types) -> void:
	if enemy_state == enemy_states.OFFLINE:
		seeking_timer.start(time_before_stop_seeking)
		setEnemyState(enemy_states.SEEKING)

## Called when the player enters the detection area; starts tracking and attack cooldown.
func _on_player_detection_body_entered(player:Player) -> void:
	player_in_detection = true
	if enemy_state != enemy_states.DESTROYED:
		setEnemyState(enemy_states.TRACKING)
		setEnemyAttackState(enemy_attack_states.COOLDOWN)


## Called when the player leaves the detection area; switches to seeking and disarms the turret.
func _on_player_detection_body_exited(player:Player) -> void:
	player_in_detection = false
	if enemy_state != enemy_states.DESTROYED:
		seeking_timer.start(time_before_stop_seeking)
		setEnemyState(enemy_states.SEEKING)
		setEnemyAttackState(enemy_attack_states.DISARMED)

## Called when the seeking timer finishes; returns the turret to the OFFLINE state if still seeking.
func _on_seeking_timer_timeout() -> void:
	if enemy_state == enemy_states.SEEKING:
		setEnemyState(enemy_states.OFFLINE)

## Called when the cooldown ends; transitions COOLDOWN → BURSTING.
func _on_fire_cool_down_timer_timeout() -> void:
	if enemy_attack_state == enemy_attack_states.COOLDOWN:
		setEnemyAttackState(enemy_attack_states.BURSTING)
	else:
		assert(false, "ERROR: Illegal state transition!")

## Called when the burst sequence ends; transitions BURSTING → COOLDOWN.
func _on_burst_fire_timer_timeout() -> void:
	if enemy_attack_state == enemy_attack_states.BURSTING:
		setEnemyAttackState(enemy_attack_states.COOLDOWN)
	else:
		assert(false, "ERROR: Illegal state transition!")


## Called when the death smoke timer ends; disables all death smoke particle emission.
func _on_death_smoke_timer_timeout() -> void:
	for smoke_particle:GPUParticles3D in death_smoke_particles:
		smoke_particle.emitting = false
