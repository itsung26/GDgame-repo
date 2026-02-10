## Base class for all enemies, ranged and melee. Handles health, damage, and death behavior.
class_name Enemy extends CharacterBody3D

signal left_floor
signal hit_floor
signal on_grappled
## Called [color=green]AFTER[/color] damage is applied but [color=red]BEFORE[/color]
## the deatch check. Use with caution.
signal on_hurt(damage:float, damage_type:damage_types)

var _was_on_floor: bool = false

# states and constants
enum damage_types{NORMAL, LASER, DARK, EXPLOSIVE}
enum weight_class{LIGHT, HEAVY}

var last_hit_damage_type:damage_types

## The actual health of the enemy. This is the primary thing modified.
@export var HEALTH:float = 100.0
## If the enemy should expirience gravity or not
@export var gravity_enabled:bool = true
## The XZ speed of the enemy
@export var SPEED:float = 3
## The base weight class of the enemy. Heavy and up will result in the player being grappled to rather than from.
@export var weight:weight_class = weight_class.LIGHT
const DAMAGE_HITMARKER_SCENE:PackedScene = preload("res://scenes/damage_hitmarker.tscn")
@onready var player:Player = get_tree().current_scene.find_child("Player")
## How quickly the enemy is slowed when in the air on the xz plane
@export var slowInAirFactor:float = 10.0
## Whether the enemy recieves damage. Taking damage will still call [code]damageEnemy[/code], but interior logic will be skipped.
@export var damage_enabled:bool = true
## The point that the grapple hook will attatch to. This should be located somewhere near the center of the enemy.
@export var grapple_offset:Vector3 = Vector3.ZERO
## Wether the behavior is allowed to run for the entity. If set to false, the entity
## should run in a "loop idle" state.
@export var behavior_enabled:bool = true
## Whether the enemy can currently be parried.
@export var parriable:bool = false
## Set this to true if the enemy should not be moveable, excluding during death gibbing.
@export var stationary:bool = false

func damageEnemy(damage:float, damage_type:damage_types):
	if damage_enabled:
		var previous_enemy_health = HEALTH
		var new_enemy_health = HEALTH - damage
		last_hit_damage_type = damage_type
		HEALTH = new_enemy_health
		HEALTH = clampf(HEALTH, 0, 100)
		
		on_hurt.emit(damage, damage_type)
		
		
		if HEALTH == 0:
			_killEnemy()
	else:
		pass

## Called when health reaches zero. Override to provide the death behavior of the enemy.
## Note that the grapple should be unhooked if the current hooked enemy is the one
## that died.
func _killEnemy():
	print("no death behavior configured. defaulting to deletion on death.")
	if player.getHookedTarget() == self:
		# unhook grapple if the hooked enemy is self
		player.set_action_state(player.action_states.IDLE) 
	queue_free()

## heals the enemy
func healEnemy(health:float):
	HEALTH += health

## gets the health of the enemy
func getHealth() -> float:
	return HEALTH


## gets the vector rotation looking at the target (returns globally and in radians)
func getVec3LookingAtTarget(target_pos:Vector3) -> Vector3:
	# store the rotation
	var prev_rot = global_rotation
	look_at(target_pos, Vector3.UP)
	# get the rotation looking at the player
	var rot = global_rotation
	# set rotation back to previous
	global_rotation = prev_rot
	return rot

## Get's the enemy's predicted position at [code]time[/code] seconds, assuming velocity
## will remain constant. Cane be used for trajectory prediction. Returns in the global
## coordinate system.
func getPredictedPos(time:float) -> Vector3:
	var a:Vector3 = velocity * time
	var r:Vector3 = a + global_position
	return r

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
