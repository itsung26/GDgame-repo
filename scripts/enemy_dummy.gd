extends CharacterBody3D


@export var last_hit_damage_type:damage_types
@export var HEALTH:int = 100.0:
	set = onEnemyHurt
@export var gravity_enabled = true
@export var SPEED = 3
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var enemy_melee_cooldown: Timer = $EnemyMeleeCooldown
@onready var hurt_box_melee: Area3D = $HurtBoxMelee
const DAMAGE_HITMARKER_SCENE = preload("res://scenes/damage_hitmarker.tscn")
@onready var player:CharacterBody3D = get_tree().current_scene.find_child("Player")
@onready var animation_player:AnimationPlayer = self.find_child("AnimationPlayer")
var pulldir:Vector3

enum damage_types{NORMAL, OVERCLOCK, DARK}
enum enemy_states {STUNNED, GROUNDED, FALLING}
@export var enemy_state:enemy_states = enemy_states.GROUNDED:
	set = set_enemy_state

enum weight_class{LIGHT,MEDIUM,HEAVY,FATASS}
@export var weight:weight_class = weight_class.LIGHT

@export var slowInAirFactor:float = 10.0

func set_enemy_state(new_enemy_state:enemy_states):
	var previous_enemy_state = enemy_state
	enemy_state = new_enemy_state
	
	# falling to and from
	if new_enemy_state == enemy_states.FALLING:
		animation_player.play("Falling_4")
	
	# Grounded to and from
	if new_enemy_state == enemy_states.GROUNDED:
		animation_player.play("Idle_8")
		
func _ready() -> void:
	pass

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
				velocity = lerp(velocity, Vector3.ZERO, 5 * delta) # prevent sliding on floor
				
		enemy_states.FALLING:
			# slow travel on xz plane in air to zero
			velocity.x = lerp(velocity.x, 0.0, slowInAirFactor * delta)
			velocity.z = lerp(velocity.z, 0.0, slowInAirFactor * delta)
		
		enemy_states.GROUNDED:
			velocity = lerp(velocity, Vector3.ZERO, 5 * delta)
			

func _physics_process(delta: float) -> void:
	if not is_on_floor() and gravity_enabled:
		# handle gravity
		velocity += get_gravity() * delta
		
	
	# handle allowed physics
	statePhysicsLogic()
	move_and_slide()

func _process(delta: float) -> void:
	if (is_on_floor() and
	enemy_state != enemy_states.STUNNED):
		enemy_state = enemy_states.GROUNDED
	elif not (is_on_floor() and
	enemy_state != enemy_states.STUNNED):
		enemy_state = enemy_states.FALLING
