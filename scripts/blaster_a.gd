extends Skeleton3D

@onready var animation_player: AnimationPlayer = $"../../../AnimationPlayer"
@onready var ray_cast_3d: RayCast3D = $"../RayCast3D"

func fire():
	print(ray_cast_3d.is_colliding())

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
