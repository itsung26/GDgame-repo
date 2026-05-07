@abstract
## Base class for all enemies, ranged and melee. Handles health, damage, and death behavior.
class_name Enemy extends CharacterBody3D


#region @onready vars
@onready var player:Player = QuickRef.player
#endregion

#region @export vars
## The actual health of the enemy. This is the primary thing modified.
@export var health:float = 100.0
## If the enemy should expirience gravity or not
@export var gravity_enabled:bool = true
## The XZ speed of the enemy
@export var SPEED:float = 3
## The base weight class of the enemy. Heavy and up will result in the player being grappled to rather than from.
@export var weight:weight_class = weight_class.LIGHT
## How quickly the enemy is slowed when in the air on the xz plane
@export var slowInAirFactor:float = 10.0
## Whether the enemy recieves damage. Taking damage will still call [code]setHealth[/code], but interior logic will be skipped.
@export var damage_enabled:bool = true
## The point that the grapple hook will attatch to. This should be located somewhere near the center of the enemy.
@export var chest_offset:Vector3 = Vector3.ZERO
## Wether the behavior is allowed to run for the entity. If set to false, the entity
## should run in a "loop idle" state.
@export var behavior_enabled:bool = true
## Whether the enemy can currently be parried.
@export var parriable:bool = false
## Set this to true if the enemy should not be moveable, excluding during death gibbing.
@export var stationary:bool = false
## If true, hitscan bullets will reflect off this enemy's surface.
@export var reflective:bool = false
#endregion

#region regular vars
var last_hit_damage_type:damage_types
#endregion

#region enums
# states and constants
## The types of damage that an enemy can recieve. These types are used in deciding
## which death vfx occurs, as well as what kind of death behavior the enemy uses.
enum damage_types{
	## Normal type of damage. Commonly used as the type for the player's weapons.
	NORMAL,
	## Damage type implying a heavier weapon being used. For example, the piercing
	## shot from a revolver or a sniper rifle.
	HEAVY,
	## A type that can often be caused by enviroment hazards, causes an effect similar
	## to burning.
	LASER,
	## A type related exclusively to demonic type attacks.
	DARK,
	## A type related exlusively to angelic type attacks.
	LIGHT,
	## Self explanatory. Causes instant, full dismemberment and/or desintegration.
	EXPLOSIVE,
	## Burning attack. Does not cause gibbing. Causes burning.
	INCENDIARY
}
enum weight_class{LIGHT, HEAVY}
#endregion

#region signals
## Called [color=green]AFTER[/color] health is applied but [color=red]BEFORE[/color]
## the death check. Use with caution.
signal on_health_changed(previous_health:float, new_health:float, damage_type:damage_types)
#endregion

#region constants
const DAMAGE_HITMARKER_SCENE:PackedScene = preload("res://scenes/damage_hitmarker.tscn")
#endregion


#region setters and getters
func setHealth(new_health:float, damage_type:damage_types):
	if damage_enabled:
		var previous_enemy_health:float = health
		last_hit_damage_type = damage_type
		health = new_health
		health = clampf(health, 0, 100)
		
		on_health_changed.emit(previous_enemy_health, health, damage_type)
		
		
		if health == 0:
			_killEnemy()
	else:
		pass


## gets the health of the enemy
func getHealth() -> float:
	return health
#endregion


#region abstract methods
## Called when health reaches zero. Override to provide the death behavior of the enemy.
@abstract func _killEnemy()


@abstract func _ready() -> void


@abstract func _process(delta: float) -> void


@abstract func _physics_process(delta: float) -> void


@abstract func _on_parried_impl() -> void
#endregion


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

## Returns true when gravity should be applied for this enemy.
func canApplyGravity() -> bool:
	return gravity_enabled and not is_on_floor()


## Applies gravity to [code]velocity[/code] when [method canApplyGravity] is true.
func applyGravity(delta:float) -> void:
	if canApplyGravity():
		velocity += get_gravity() * delta


## Wrapper for abstract behavior reaction method. Do not override.
func on_parried() -> void:
	_on_parried_impl()
