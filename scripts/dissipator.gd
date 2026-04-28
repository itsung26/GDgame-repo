class_name PlayerDissipator
extends PlayerWeapon

## Charge-based player weapon with a primary hitscan shot and a reflection special.
## While special is held, the weapon spins and builds charge. Releasing at max charge
## fires a first piercing hitscan, then reflects toward the nearest PistolBomb when
## available, otherwise toward the nearest visible enemy, or a random direction.

#region constants
const bullet_trail_SCENE:PackedScene = preload("res://scenes/bullet_trail.tscn")
const BULLET_IMPACT_PARTICLE_SCENE_2:PackedScene = preload("res://scenes/bullet_impact_particles_2.tscn")
const bullet_light_SCENE:PackedScene = preload("res://scenes/dissipator_bullet_light.tscn")
#endregion

#region @onready vars
@onready var animation_player: AnimationPlayer = $Dissipator2/AnimationPlayer
@onready var muzzle: Node3D = $Dissipator2/feedbacker/Skeleton3D/Hand/Dissipator/muzzle
@onready var flash_animator: AnimationPlayer = $Dissipator2/feedbacker/Skeleton3D/Hand/Dissipator/FlashAnimator
@onready var dissipator_piercing_hitscan: DissipatorPiercingHitscan = $DissipatorPiercingHitscan
@onready var dissipator_MESH: MeshInstance3D = $Dissipator2/feedbacker/Skeleton3D/Hand/Dissipator
@onready var hand_attatchment: BoneAttachment3D = $Dissipator2/feedbacker/Skeleton3D/Hand
@onready var delay_before_idle_timer: Timer = $DelayBeforeIdleTimer
#endregion

#region @export vars
## Primary-fire hitscan settings used by [method fireBullet].
@export var bullet_config:HitscanBulletConfig

@export_category("Behavior")
## Base visual spin speed multiplier while charging.
@export var spin_speed:float = 1.0
## Delay before returning to Idle after equip/fire animations complete.
@export var delay_before_idle_anim:float = 1.0
## Enables debug logs for animation/idle timing flow.
@export var logging_debug:bool = true

@export_category("Reflection Special")
## Hitscan settings for both initial and reflected special shots.
@export var reflection_bullet_config:HitscanBulletConfig
## Charge required to trigger the special on release.
@export var reflection_max_charge:float = 100.0
## Charge gain per second while [member charging] is true.
@export var reflection_charge_speed:float = 1.0
## Camera shake intensity applied when special is fired.
@export var camera_shake_strength:float
## Camera shake duration applied when special is fired.
@export var camera_shake_duration:float
## Short time-flow interruption duration applied when allowed.
@export var firing_hitstop_duration:float = 0.15
#endregion

#region regular vars
## Current accumulated special charge.
var reflection_charge:float = 0.0: set = setReflectionCharge
## True while special input is held and the weapon is charging.
var charging:bool = false: set = setCharging
#endregion


## Sets current reflection charge and triggers a one-shot flash at max charge.
func setReflectionCharge(value:float) -> void:
	if reflection_charge == value:
		return
	reflection_charge = value
	
	if value == reflection_max_charge:
		flash_animator.play("flashonce")


## Toggles special charging state and updates spin/idle transition animations.
func setCharging(value:bool) -> void:
	if charging == value:
		return
	charging = value
	
	if value == true:
		animation_player.play("ReadySpin")
	elif value == false:
		delay_before_idle_timer.start(delay_before_idle_anim)


## Updates reflection charge and spin rotation every frame.
func _process(delta: float) -> void:
	if charging:
		reflection_charge = move_toward(reflection_charge, reflection_max_charge, reflection_charge_speed * delta)
	else:
		reflection_charge  = 0.0
	
	if reflection_max_charge > 0.0 and reflection_charge > 0.0:
		var charge_t:float = reflection_charge / reflection_max_charge
		dissipator_MESH.rotation.x += charge_t * spin_speed * delta


#region PlayerWeapon overrides
## Runs equip behavior and starts the equip animation.
func _onEquipImpl() -> void:
	if animation_player.current_animation == "Idle":
		animation_player.stop()
		animation_player.play("Equip")
	else:
		animation_player.play("Equip")


## Runs base fire behavior and starts the primary fire animation.
func _fireImpl() -> void:
	animation_player.play("Fire")


## Starts charging the reflection special.
func _specialImpl() -> void:
	#_cached_mesh_rotation = dissipator_MESH.rotation
	setCharging(true)


## Stops charging and fires the reflection special when fully charged.
func _specialReleaseImpl() -> void:
	charging = false
	#dissipator_MESH.rotation = _cached_mesh_rotation
	if reflection_charge == reflection_max_charge:
		animation_player.play("FireSpecial")
		fireSpecial()


## Calls base reload behavior for this weapon.
func _reloadImpl() -> void:
	pass
#endregion


## Fires the reflection special:
## 1) fires an initial piercing hitscan from the muzzle,
## 2) reflects toward nearest PistolBomb from first hit point if one exists,
## 3) otherwise reflects toward nearest visible enemy, or a random direction.
## Also applies camera shake and optional short hitstop.
func fireSpecial() -> void:
	var first_firing_point:Vector3 = Vector3.ZERO
	var player:Player = get_tree().get_first_node_in_group("players")
	var playercam:PlayerCamera = player.camera_3d
	
	# If there is a pistolbomb in the scene, hitting it will cause the time interruption to
	# fail due to overlap, so don't do the small timestopping if there is a pistolbomb in
	# the scene as a temporary workaround.
	if get_tree().get_nodes_in_group(&"pistol bombs").is_empty():
		TimeFlowSystem.interruptTimeflow(firing_hitstop_duration)
	playercam.shakeCamera(camera_shake_duration, camera_shake_strength)
	
	# First the hitscan hits the place the weapon is aimed as usual.
	first_firing_point = HitscanSystem.fire(
		reflection_bullet_config,
		muzzle.global_position,
		dissipator_piercing_hitscan
	)
	
	
#region Reflection towards an object===================================================
	# First, attempt to reflect towards the nearest PistolBomb if there is one.
	var pistol_bombs:Array[Node] = get_tree().get_nodes_in_group(&"pistol bombs")
	var nearest_pistol_bomb: PistolBomb
	var nearest_distance: float = INF
	if not pistol_bombs.is_empty():
		for bomb: PistolBomb in pistol_bombs:
			var distance: float = bomb.global_position.distance_to(first_firing_point)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_pistol_bomb = bomb
	if nearest_pistol_bomb:
		var direction:Vector3 = (nearest_pistol_bomb.global_position - first_firing_point).normalized()
		HitscanSystem.fireManual(
			reflection_bullet_config,
			first_firing_point,
			dissipator_piercing_hitscan,
			direction
		)
		return
	# Otherwise, try to reflect to the nearest enemy
	
	# get the location of the nearest enemy's center from the first hit point
	var nearest_enemy:Enemy = EnemyPopulationHandler.getClosestVisibleEnemy(first_firing_point)
	var nearest_enemy_pos:Vector3
	var dir:Vector3
	
	# if valid enemy, reflect towards them.
	# else, reflect in a random direction
	if nearest_enemy:
		nearest_enemy_pos = nearest_enemy.global_position + nearest_enemy.chest_offset
		dir = nearest_enemy_pos - first_firing_point
		dir = dir.normalized()
	else:
		dir = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	
	# Then, the hitscan should reflect to the nearest enemy.
	HitscanSystem.fireManual(
		reflection_bullet_config,
		first_firing_point,
		dissipator_piercing_hitscan,
		dir
	)
	return
#endregion=======================================================================


## Fires the primary dissipator shot through the piercing hitscan component.
## Also clears charging to prevent spin state from persisting after firing.
func fireBullet() -> void:
	charging = false
	HitscanSystem.fire(
		bullet_config,
		muzzle.global_position,
		dissipator_piercing_hitscan
	)


## Returns true when the weapon is currently in a non-zero charge spin state.
func is_spinning() -> bool:
	return reflection_max_charge > 0.0 and reflection_charge > 0.0


## Handles animator finish events and schedules the delayed idle transition.
func _onAnimationPlayerAnimationFinished(_anim_name:StringName) -> void:
	# If equip/fire finished, schedule delayed transition back to idle.
	if _anim_name == "Equip":
		if logging_debug:
			Debug.log("started timer")
		delay_before_idle_timer.start(delay_before_idle_anim)
	elif _anim_name == "Fire":
		if logging_debug:
			Debug.log("started timer")
		delay_before_idle_timer.start(delay_before_idle_anim)


## Plays idle when delay expires and no blocking animation/charge state is active.
func _on_delay_before_idle_timer_timeout() -> void:
	if not animation_player.is_playing() and not is_spinning():
		if logging_debug:
			Debug.log("Delay timeout. Playing Idle anim.")
		animation_player.play("Idle")
	elif animation_player.is_playing():
		if logging_debug:
			Debug.log("Delay timeout. Animation already playing.")
	elif is_spinning():
		if logging_debug:
			Debug.log("Delay timeout. Anim could not be played due to charging state.")
