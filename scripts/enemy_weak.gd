extends CharacterBody3D

@export var HEALTH:float = 100.0:
	set = enemyHurt
@export var gravity_enabled = true
@export var SPEED = 3
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var enemy_melee_cooldown: Timer = $EnemyMeleeCooldown
@onready var hurt_box_melee: Area3D = $HurtBoxMelee
const DAMAGE_HITMARKER_SCENE = preload("res://scenes/damage_hitmarker.tscn")

@export var AttackCooldown:float = 0.0
@export var AttackDamage:float = 0.0

var player: Node3D
var is_attacking:bool = false
var body_in_hurtbox
var player_in_hurtbox: bool = false

# state machine==============================================================
var enemy_state := enemy_states.FOLLOWING:
	set = set_enemy_state

enum enemy_states {FOLLOWING, STUNNED}

func set_enemy_state(new_enemy_state:int):
	# init vars
	var previous_enemy_state := enemy_state
	enemy_state = new_enemy_state
	
	if new_enemy_state == enemy_states.STUNNED:
		velocity = Vector3.ZERO
	
func enemyHurt(new_enemy_health:int):
	# init vars
	var previous_enemy_health := HEALTH
	var enemy_damage_taken := previous_enemy_health - new_enemy_health
	HEALTH = new_enemy_health
	
	print("enemy took " + str(enemy_damage_taken) + "damage")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Find the player node anywhere in the scene tree
	player = get_tree().get_root().find_child("Player")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	player = get_tree().current_scene.find_child("Player")
	enemy_melee_cooldown.wait_time = AttackCooldown
	if player:
		var look_at_player_pos: Vector3 = Vector3(player.global_position.x, global_position.y, player.global_position.z)
		look_at(look_at_player_pos, Vector3.UP)
	if HEALTH <= 0:
		animation_player.play("enemy_death")
	if player:
		nav_agent.target_position = player.global_position

func _physics_process(delta) -> void:
	# Only apply gravity if needed, then move
	if not is_on_floor() and gravity_enabled:
		velocity += get_gravity() * delta
	
	if enemy_state == enemy_states.FOLLOWING:
		# Navigation movement
		if nav_agent.is_navigation_finished() == false:
			var next_pos = nav_agent.get_next_path_position()
			var direction = (next_pos - global_position).normalized()
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = 0
			velocity.z = 0

	elif enemy_state == enemy_states.STUNNED:
		move_and_slide()
		
	move_and_slide()


func _on_hurt_box_melee_body_entered(body) -> void:
	if body.name == "Player":
		player_in_hurtbox = true
		body_in_hurtbox = body
		# Only attack if not already attacking
	if not is_attacking:
		attackRepeatedly()

func _on_hurt_box_melee_body_exited(body) -> void:
	if body.name == "Player":
		player_in_hurtbox = false
		# Optionally stop attacking if player leaves
		is_attacking = false

func attackRepeatedly():
	if player_in_hurtbox and body_in_hurtbox and not is_attacking:
		is_attacking = true
		animation_player.play("enemy_attack_melee")
		enemy_melee_cooldown.start()

func _on_enemy_melee_cooldown_timeout() -> void:
	is_attacking = false
	# If player is still in hurtbox, attack again
	if player_in_hurtbox:
		attackRepeatedly()

func hurtTouching():
	print(body_in_hurtbox)
	body_in_hurtbox.HEALTH -= AttackDamage
	if body_in_hurtbox.is_in_group("players"):
		body_in_hurtbox.cause_of_death = "Mauled to death by [prototype enemy]"
