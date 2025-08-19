extends Skeleton3D

@onready var animation_player: AnimationPlayer = $"../../../AnimationPlayer"
@onready var ray_cast_3d: RayCast3D = $"../RayCast3D"

const BULLET_DECAL = preload("res://scenes/bullet_decal.tscn")

signal current_blaster_ammo(amount)
signal current_anim(anim)

# definitions for ammo
const MAGSIZE = 50
var ammo = 50
const DAMAGE = 5

# instantiate a body from the return of the get_collider() method
# this method is called every time the animation for firing runs and is essentially the bulk of the shoot code
# refer to the _process method for the animations, which are triggered by only input
func fire():
	var body = ray_cast_3d.get_collider()
	var b = BULLET_DECAL.instantiate()
	
	# below occurs regardless of wether the bullets hit something or otherwise
	ammo -= 1 # I somehow have to send this variable to hud.gd every time it's updated
	
	# pass if returns null to avoid null refrence errors
	# in other words, IF IT HITS SOMETHING DO THIS VVVVVV
	if body != null:
		body.add_child(b)
		b.global_transform.origin = ray_cast_3d.get_collision_point()
		b.look_at(ray_cast_3d.get_collision_point() + ray_cast_3d.get_collision_normal(), Vector3.UP)
		body.health = body.health - DAMAGE
		print("health of enemy: " + str(body.health))


func reload():
	ammo = 50

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	current_blaster_ammo.emit(ammo)
	
	current_anim.emit(animation_player.current_animation)
	# a random num to aid in randomizing animation variants
	# var random = randi_range(0,1)
	
	if Input.is_action_pressed("fire"):
		if animation_player.current_animation == "inspect" or animation_player.current_animation == "inspect 2":
			animation_player.stop()
		elif animation_player.current_animation == "reload_pistol":
			pass
		else:
			if ammo > 0:
				animation_player.play("recoil")
			elif ammo == 0: animation_player.play("reload_pistol")
	
	if Input.is_action_pressed("inspect weapon"):
		if animation_player.current_animation == "reload_pistol":
			pass
		else:
			animation_player.play("inspect")
			
		
	if Input.is_action_pressed("reload"):
		if ammo != 50:
			animation_player.play("reload_pistol")
