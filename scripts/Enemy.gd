## Base class for all enemies, ranged and melee. Handles health, damage, and death behavior.
class_name Enemy extends CharacterBody3D

signal left_floor
signal hit_floor

var _was_on_floor: bool = false

# states and constants
enum damage_types{NORMAL, LASER, DARK}
enum weight_class{LIGHT, HEAVY}

var last_hit_damage_type:damage_types

## The actual health of the enemy. This is the primary thing modified.
@export var HEALTH:float = 100.0
## If the enemy should expirience gravity or not
@export var gravity_enabled = true
## The XZ speed of the enemy
@export var SPEED = 3
## The base weight class of the enemy. Heavy and up will result in the player being grappled to rather than from.
@export var weight:weight_class = weight_class.LIGHT
const DAMAGE_HITMARKER_SCENE:PackedScene = preload("res://scenes/damage_hitmarker.tscn")
@onready var player:CharacterBody3D = get_tree().current_scene.find_child("Player")
## How quickly the enemy is slowed when in the air on the xz plane
@export var slowInAirFactor:float = 10.0
## Whether the enemy recieves damage. Taking damage will still call [code]damageEnemy[/code], but interior logic will be skipped.
@export var damage_enabled:bool = true
## The position of this node will be the point that the grapple hook "snaps" to when it hits the enemy.
@export var grapple_origin:Marker3D
## Whether the enemy is parriable. Shared with [code]EnemyProjectile[/code].
@export var parriable:bool = true
## Whether the enemy has been parried in it's lifetime.
@export var has_been_parried:bool = false
## If true, the enemy will remain in stunned state untill this is set false again.
@export var stunned:bool = false

#func setIgnorePlayer(b:bool) -> void:
	#var previous_ignore_player:bool = _ignore_player
	#var new_ignore_player:bool = b
	#
	#if previous_ignore_player == new_ignore_player:
		#return
	#
	#_ignore_player = new_ignore_player

func _set(property: StringName, value: Variant) -> bool:
	return false

func damageEnemy(damage:float, damage_type:damage_types):
	if damage_enabled:
		var previous_enemy_health = HEALTH
		var new_enemy_health = HEALTH - damage
		last_hit_damage_type = damage_type
		HEALTH = new_enemy_health
		HEALTH = clampf(HEALTH, 0, 100)
		
		if damage != 0.0:
			# spawn a hitmarker on own body
			var a = DAMAGE_HITMARKER_SCENE.instantiate()
			a.tracked_camera = player.camera_3d
			a.tracked_enemy = self
			add_child(a)
			a.damage_number_label.text = str(damage)
		
		if HEALTH == 0:
			_killEnemy()
	else:
		pass

## Called when health reaches zero.
func _killEnemy():
	print("no death behavior configured. defaulting to deletion on death.")
	queue_free()

## heals the enemy
func healEnemy(health:float):
	HEALTH += health

## gets the health of the enemy
func getHealth():
	return HEALTH


## gets the vector rotation looking at the target (returns in radians)
func getVec3LookingAtTarget(target_pos:Vector3) -> Vector3:
	# store the rotation
	var prev_rot = rotation
	look_at(target_pos, Vector3.UP)
	# get the rotation looking at the player
	var rot = rotation
	# set rotation back to previous
	rotation = prev_rot
	return rot

func _ready() -> void:
	_was_on_floor = is_on_floor()
	if get_tree():
		get_tree().connect("physics_frame", Callable(self, "_on_physics_frame"))

func _exit_tree() -> void:
	if get_tree():
		var cb := Callable(self, "_on_physics_frame")
		if get_tree().is_connected("physics_frame", cb):
			get_tree().disconnect("physics_frame", cb)

func _on_physics_frame() -> void:
	var now := is_on_floor()
	if _was_on_floor and not now:
		emit_signal("left_floor")
	elif (not _was_on_floor) and now:
		emit_signal("hit_floor")
	_was_on_floor = now
