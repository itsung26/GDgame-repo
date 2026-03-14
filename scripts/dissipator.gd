class_name PlayerDissipator
extends PlayerWeapon

const bullet_trail_SCENE:PackedScene = preload("res://scenes/bullet_trail.tscn")
const BULLET_IMPACT_PARTICLE_SCENE_2:PackedScene = preload("res://scenes/bullet_impact_particles_2.tscn")
const bullet_light_SCENE:PackedScene = preload("res://scenes/dissipator_bullet_light.tscn")

@onready var animation_player: AnimationPlayer = $Dissipator2/AnimationPlayer
@onready var muzzle: Node3D = $Dissipator2/feedbacker/Skeleton3D/Hand/Dissipator/muzzle
@onready var dissipator_hitscan: RayCast3D = $DissipatorHitscan

@export var bullet_config:HitscanBulletConfig


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass


func _onEquip() -> void:
	super._onEquip()
	animation_player.play("Equip")


func _fire() -> void:
	super._fire()
	animation_player.play("Fire")


func _special() -> void:
	super._special()


func _specialRelease() -> void:
	super._specialRelease()


func _reload() -> void:
	super._reload()


func fireBullet() -> void:
	HitscanSystem.fire(
		bullet_config,
		muzzle.global_position,
		dissipator_hitscan,
		get_tree().current_scene
	)
