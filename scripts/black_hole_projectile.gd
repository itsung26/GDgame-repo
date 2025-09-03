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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:

	# save current position as a vector3
	black_hole_position = position
	# pull bodies to said position
	pullBodies(black_hole_position)
	
	
# pulls bodies
func pullBodies(blackHolePos):
	bodies_in_pull_box = pull_box.get_overlapping_bodies()
	for body in bodies_in_pull_box:
		
		# add after enemy AI is added
		'''
		# handle pull for enemies
		if body.is_in_group("enemy"):
			enemy_pull_dir = (blackHolePos - body.position).normalized()
			body.velocity = (enemy_pull_dir * BH_pull_speed)
		'''
		
		# handle pull for players
		if body.is_in_group("players"):
			player_pull_dir = (blackHolePos - body.position).normalized()
			body.velocity = (player_pull_dir * BH_pull_speed)
			
# mimicks queue_free() but with extra steps before leaving scene
func blackHoleExit():
	print("black hole leaving scene and re-allowing inputs")
	queue_free()
