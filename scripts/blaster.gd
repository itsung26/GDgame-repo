extends Skeleton3D

@onready var animation_player: AnimationPlayer = $"../../../AnimationPlayer"
@onready var ray_cast_3d: RayCast3D = $"../RayCast3D"
const BULLET_DECAL = preload("res://scenes/bullet_decal.tscn")


# instantiate a body from the return of the get_collider() method
func fire():
	var body = ray_cast_3d.get_collider()
	var b = BULLET_DECAL.instantiate()
	
	# pass if returns null to avoid null refrence errors
	# in other words, IF IT HITS SOMETHING DO THIS VVVVVV
	if body != null:
		body.add_child(b)
		b.global_transform.origin = ray_cast_3d.get_collision_point()
		b.look_at(ray_cast_3d.get_collision_point() + ray_cast_3d.get_collision_normal(), Vector3.UP)
		body.health -= 10
		print("health of enemy:")
		print(body.health)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	# a random num to aid in randomizing animation variants
	var random = randi_range(0,1)
	
	if Input.is_action_pressed("fire"):
		if animation_player.current_animation == "inspect":
			animation_player.stop()
		animation_player.play("recoil")
	
	if Input.is_action_pressed("inspect weapon"):
		animation_player.play("inspect")
