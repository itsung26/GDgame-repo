extends RigidBody3D
@onready var pull_box: Area3D = $PullBox
@onready var pullbox: CollisionShape3D = $PullBox/pullbox
@onready var black_hole_projectile: RigidBody3D = $"."
@onready var player: CharacterBody3D = $"../Player"
@onready var black_hole_launcher: Node3D = $"../Player/Pivot/Camera3D/Guns/BlackHoleLauncher"
@onready var fire_direction: Node3D = $FireDirection


var black_hole_position : Vector3
var bodies_in_pull_box : Array
var player_pull_dir : Vector3
var enemy_pull_dir : Vector3
var fire_dir : Vector3

@export var BH_pull_speed = 10
@export var DAMAGE:float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

var is_colliding_with_player: bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	# print(is_colliding_with_player)

	# save current position as a vector3
	black_hole_position = position
	# pull bodies to said position
	pullBodies(black_hole_position)
	is_colliding_with_player = false
	for body in pull_box.get_overlapping_bodies():
		if body.is_in_group("players"):
			is_colliding_with_player = true
			break

	# Enable/disable player movement input based on collision
	if is_colliding_with_player:
		Global.player_move_input_enabled = false
	else:
		Global.player_move_input_enabled = true
	
# pulls bodies
func pullBodies(blackHolePos):
	bodies_in_pull_box = pull_box.get_overlapping_bodies()
	for body in bodies_in_pull_box:
		
		# handle pull for enemies
		if body.is_in_group("enemy"):
			body.HEALTH -= DAMAGE
			enemy_pull_dir = (global_position - body.global_position).normalized()
			body.velocity = (enemy_pull_dir * BH_pull_speed)
			body.being_pulled = true

		# handle pull for players
		if body.is_in_group("players"):
			body.cause_of_death = "Sucked into a black hole"
			body.HEALTH -= DAMAGE
			player_pull_dir = (global_position - body.global_position).normalized()
			body.velocity = (player_pull_dir * BH_pull_speed)
			
		
# mimicks queue_free() but with extra steps before leaving scene
func blackHoleExit():
	print("black hole leaving scene and re-allowing inputs")
	Global.player_move_input_enabled = true
	for body in pull_box.get_overlapping_bodies():
		if body.is_in_group("enemy"):
			body.being_pulled = false
	queue_free()
