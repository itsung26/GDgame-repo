extends CharacterBody3D


@export var last_hit_damage_type:damage_types
@export var HEALTH:int = 100.0:
	set = onEnemyHurt
@export var gravity_enabled = true
@export var SPEED = 3
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var enemy_melee_cooldown: Timer = $EnemyMeleeCooldown
@onready var hurt_box_melee: Area3D = $HurtBoxMelee
const DAMAGE_HITMARKER_SCENE = preload("res://scenes/damage_hitmarker.tscn")
var player

enum damage_types{NORMAL, OVERCLOCK, DARK}
enum enemy_states {STUNNED}
@export var enemy_state:enemy_states = enemy_states.STUNNED

enum weight_class{LIGHT,MEDIUM,HEAVY,FATASS}
@export var weight:weight_class = weight_class.LIGHT

func _ready() -> void:
	player = get_tree().current_scene.find_child("Player")

func onEnemyHurt(new_enemy_health:int):
	# init vars
	var previous_enemy_health := HEALTH
	var enemy_damage_taken := previous_enemy_health - new_enemy_health
	HEALTH = new_enemy_health
	
	# spawn a hitmarker on own body
	var a = DAMAGE_HITMARKER_SCENE.instantiate()
	a.tracked_camera = player.camera_3d
	a.tracked_enemy = self
	add_child(a)
	a.damage_number_label.text = str(enemy_damage_taken)

func statePhysicsLogic(delta = get_process_delta_time()):
	match enemy_state:
		
		enemy_states.STUNNED:
			if is_on_floor():
				velocity = lerp(velocity, Vector3.ZERO, 5 * delta)

func _physics_process(delta: float) -> void:
	if not is_on_floor() and gravity_enabled:
		# handle gravity
		velocity += get_gravity() * delta
		
	# handle allowed physics
	statePhysicsLogic()
		
	move_and_slide()
