extends RigidBody3D
@onready var pull_box: Area3D = $PullBox
@onready var pullbox: CollisionShape3D = $PullBox/pullbox
@onready var black_hole_projectile: RigidBody3D = $"."
@onready var player: CharacterBody3D = $"../Player"

var black_hole_position : Vector3
var bodies_in_pull_box : Array
var player_pull_dir : Vector3

var BH_pull_speed = 10

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func pullBodies(blackHolePos):
	bodies_in_pull_box = pull_box.get_overlapping_bodies()
	for body in bodies_in_pull_box:
		if body.is_in_group("enemy"):
			print("enemy detected")
		if body.is_in_group("players"):
			print("player detected")
			


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	black_hole_position = black_hole_projectile.position
	print(black_hole_position)
	player_pull_dir = (black_hole_position - player.position).normalized()
	print(player.velocity)
	player.velocity = (player_pull_dir * BH_pull_speed)
	pullBodies(black_hole_position)

	
