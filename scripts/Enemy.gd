class_name Enemy extends CharacterBody3D

# states and constants
enum damage_types{NORMAL, LASER, DARK}
enum weight_class{LIGHT,MEDIUM,HEAVY,FATASS}

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

func damageEnemy(damage:float, damage_type:damage_types):
	var previous_enemy_health = HEALTH
	var new_enemy_health = HEALTH - damage
	last_hit_damage_type = damage_type
	HEALTH = new_enemy_health
	HEALTH = clampf(HEALTH, 0, 100)
	
	# spawn a hitmarker on own body
	var a = DAMAGE_HITMARKER_SCENE.instantiate()
	a.tracked_camera = player.camera_3d
	a.tracked_enemy = self
	add_child(a)
	a.damage_number_label.text = str(damage)

func healEnemy(health:float):
	HEALTH += health

func getHealth():
	return HEALTH
