class_name PistolBomb
extends RigidBody3D

signal parried

const explosion_scene:PackedScene = preload("res://scenes/explosion_3d.tscn")
@onready var pistol_bomb_player: AnimationPlayer = $"pistol bomb player"
@onready var detonation_timer: Timer = $"detonation timer"
@onready var detonation_animator: AnimationPlayer = $"detonation animator"
## Timer that controls the grace period before the bomb can collide with the player.
@onready var time_before_can_hit_player: Timer = $"time before can hit player"
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

## Duration (seconds) the bomb ignores the player after being shot. Prevents instant self-damage.
@export var time_before_player_collide: float = 0.1
@export var spin_speed:float = 50.0
@export var projectile_speed:float = 10.0
@export var time_before_detonation:float = 1.0
@export var hitstop_duration_on_being_shot:float = 0.30
@export var can_hit_player:bool = false

var attatched_to_surface:bool = false
var attatched_to_enemy:bool = false
var attatched_to_world:bool = false
var parriable:bool = true
var has_been_parried:bool = false

func _ready() -> void:
	add_collision_exception_with(get_tree().get_first_node_in_group("players"))
	visible = false
	freeze = true
	contact_monitor = false

func setup(spawn_pos:Vector3) -> void:
	global_position = spawn_pos
	visible = true
	freeze = false
	contact_monitor = true
	var player:Player = get_tree().get_first_node_in_group("players")
	global_rotation = player.getFacingRot()
	# Start grace-period timer so the bomb can hit the player after time_before_player_collide.
	if can_hit_player:
		time_before_can_hit_player.start(time_before_player_collide)
	linear_velocity = -global_transform.basis.z.normalized() * projectile_speed
	linear_velocity += player.velocity
	angular_velocity.z = -spin_speed
	pistol_bomb_player.play("red flash")

func explode() -> void:
	$CollisionShape3D.disabled = true # disable collision to prevent double explosions
	var explosion_shockwave:Explosion3D = explosion_scene.instantiate()
	get_tree().current_scene.add_child(explosion_shockwave)
	explosion_shockwave.setup_preset(global_position, explosion_shockwave.explosion_presets.SHOCKWAVE_SMALL)

	var explosion_damage:Explosion3D = explosion_scene.instantiate()
	get_tree().current_scene.add_child(explosion_damage)
	explosion_damage.setup_preset(global_position, explosion_damage.explosion_presets.YELLOW_SMALL)

	queue_free()

func disconnectAllSignals() -> void:
	# Disconnect body_entered signals on this RigidBody3D
	if body_entered.is_connected(Callable(self, "_on_world_entered")):
		body_entered.disconnect(Callable(self, "_on_world_entered"))
	if body_entered.is_connected(Callable(self, "_on_player_entered")):
		body_entered.disconnect(Callable(self, "_on_player_entered"))
	if body_entered.is_connected(Callable(self, "_on_enemy_entered")):
		body_entered.disconnect(Callable(self, "_on_enemy_entered"))

	# Disconnect custom parried signal from self
	if parried.is_connected(Callable(self, "_on_parried")):
		parried.disconnect(Callable(self, "_on_parried"))

	# Disconnect timer timeout signals
	if time_before_can_hit_player and time_before_can_hit_player.timeout.is_connected(Callable(self, "_on_time_before_can_hit_player_timeout")):
		time_before_can_hit_player.timeout.disconnect(Callable(self, "_on_time_before_can_hit_player_timeout"))
	if detonation_timer and detonation_timer.timeout.is_connected(Callable(self, "_on_detonation_timer_timeout")):
		detonation_timer.timeout.disconnect(Callable(self, "_on_detonation_timer_timeout"))

func stickTo(target_body:Node3D, target_position:Vector3):
	if target_body is Enemy:
		attatched_to_surface = true
		attatched_to_enemy = true
	else:
		attatched_to_surface = true
		attatched_to_world = false
	# disable all collisions for saftey
	collision_shape_3d.disabled = true
	freeze = true
	reparent(target_body)
	global_position = target_position # pistol bomb teleport to raycast point
	has_been_parried = true
	parriable = false
	detonation_timer.start(time_before_detonation)

## On collide with world.
func _on_world_entered(body: Node) -> void:
	if not body.is_in_group("enemy") or body.is_in_group("players"):
		explode()

## On collide with player.
func _on_player_entered(player:Player) -> void:
	explode()

## On collide with enemy.
func _on_enemy_entered(enemy:Enemy) -> void:
	explode()

## Grace period ended: bomb can now collide with and damage the player.
func _on_time_before_can_hit_player_timeout() -> void:
	remove_collision_exception_with(get_tree().get_first_node_in_group("players"))
	
func _on_detonation_timer_timeout() -> void:
	detonation_animator.play("detonate")
