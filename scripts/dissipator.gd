class_name PlayerDissipator
extends PlayerWeapon

const bullet_trail_SCENE:PackedScene = preload("res://scenes/bullet_trail.tscn")
const BULLET_IMPACT_PARTICLE_SCENE_2:PackedScene = preload("res://scenes/bullet_impact_particles_2.tscn")
const bullet_light_SCENE:PackedScene = preload("res://scenes/dissipator_bullet_light.tscn")

@onready var animation_player: AnimationPlayer = $Dissipator2/AnimationPlayer
@onready var muzzle: Node3D = $Dissipator2/feedbacker/Skeleton3D/Hand/Dissipator/muzzle
@onready var dissipator_hitscan: RayCast3D = $DissipatorHitscan
@onready var flash_animator: AnimationPlayer = $Dissipator2/feedbacker/Skeleton3D/Hand/Dissipator/FlashAnimator
@onready var dissipator_piercing_hitscan: DissipatorPiercingHitscan = $DissipatorPiercingHitscan
@onready var dissipator_MESH: MeshInstance3D = $Dissipator2/feedbacker/Skeleton3D/Hand/Dissipator

@export var bullet_config:HitscanBulletConfig
@export_category("Behavior")
@export var spin_speed:float = 1.0
@export_category("Reflection Special")
@export var reflection_bullet_config:HitscanBulletConfig
@export var reflection_max_charge:float = 100.0
@export var reflection_charge_speed:float = 1.0
@export var camera_shake_strength:float
@export var camera_shake_duration:float
@export var firing_hitstop_duration:float = 0.15

var reflection_charge:float = 0.0: set = setReflectionCharge
var charging:bool = false: set = setCharging


func setReflectionCharge(value:float) -> void:
	if reflection_charge == value:
		return
	reflection_charge = value
	
	if value == reflection_max_charge:
		flash_animator.play("flashonce")


func setCharging(value:bool) -> void:
	if charging == value:
		return
	charging = value
	
	if value == true:
		animation_player.play("ReadySpin")
	elif value == false:
		animation_player.stop()


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if charging:
		reflection_charge = move_toward(reflection_charge, reflection_max_charge, reflection_charge_speed * delta)
	else:
		reflection_charge  = 0.0
	
	if reflection_max_charge > 0.0 and reflection_charge > 0.0:
		var charge_t:float = reflection_charge / reflection_max_charge
		dissipator_MESH.rotation.x += charge_t * spin_speed * delta


func _onEquip() -> void:
	super._onEquip()
	animation_player.play("Equip")


func _fire() -> void:
	super._fire()
	animation_player.play("Fire")


func _special() -> void:
	super._special()
	setCharging(true)


func _specialRelease() -> void:
	super._specialRelease()
	if reflection_charge == reflection_max_charge:
		fireSpecial()
	charging = false


func _reload() -> void:
	super._reload()


func fireSpecial() -> void:
	var first_firing_point:Vector3 = Vector3.ZERO
	var player:Player = get_tree().get_first_node_in_group("players")
	var playercam:PlayerCamera = player.camera_3d
	
	# Approximate the hit body. If the body is a pistolbomb, a timeScaleInterruption
	# will be requested, so only request one if the hit body is not a pistolbomb
	# so that the request does not fail due to overlap.
	if not dissipator_piercing_hitscan.get_collider_of_type(PistolBombShotCollsionReciever):
		TimeFlowSystem.interruptTimeflow(firing_hitstop_duration)
	playercam.shakeCamera(camera_shake_duration, camera_shake_strength)
	
	# First the hitscan hits the place the weapon is aimed as usual.
	first_firing_point = HitscanSystem.fire(
		reflection_bullet_config,
		muzzle.global_position,
		dissipator_piercing_hitscan
	)
	
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
	
	# Then, the hitscan should reflect to the nearest enemy. (ideally piercing them)
	HitscanSystem.fireManual(
		reflection_bullet_config,
		first_firing_point,
		dissipator_piercing_hitscan,
		dir
	)


func fireBullet() -> void:
	charging = false
	HitscanSystem.fire(
		bullet_config,
		muzzle.global_position,
		dissipator_piercing_hitscan
	)
