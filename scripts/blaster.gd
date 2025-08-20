extends Skeleton3D

@onready var animation_player: AnimationPlayer = $"../../../AnimationPlayer"
@onready var bullet_ray_cast: RayCast3D = $"../BulletRayCast"


const BULLET_DECAL_BLUE = preload("res://scenes/bullet_decal.tscn")

signal current_blaster_ammo(amount)
signal current_anim(anim)
signal body_hit(body)

# definitions for ammo
const MAGSIZE = 50
var ammo = 50
const DAMAGE = 5

# instantiate a body from the return of the get_collider() method
# this method is called every time the animation for firing runs and is essentially the bulk of the shoot code
# refer to the _process method for the animations, which are triggered by only input
func fire():
	var body = bullet_ray_cast.get_collider()
	var b = BULLET_DECAL_BLUE.instantiate()
	var b_mesh = b.get_node("MeshInstance3D")
	var b_surface_override = b_mesh.get_surface_override_material(0)
	
	# duplicates the surface material and applies the duplicate to the new instance
	b_mesh.set_surface_override_material(0, b_surface_override.duplicate())
	
	# below occurs regardless of wether the bullets hit something or otherwise
	ammo -= 1
	
	# signal the body that was just hit for debug
	body_hit.emit(body)
	
	# pass if returns null to avoid null refrence errors
	# in other words, IF IT HITS SOMETHING DO THIS VVVVVV
	if body != null:
		body.add_child(b)
		b.global_transform.origin = bullet_ray_cast.get_collision_point()
		b.look_at(bullet_ray_cast.get_collision_point() + bullet_ray_cast.get_collision_normal(), Vector3.UP)
		if body.is_in_group("enemy"):
			body.health = body.health - DAMAGE
			print("health of enemy: " + str(body.health))
		else:
			print("bullet hit something that is not an enemy")


func reload():
	ammo = 50
	
func special(weapon):
	if weapon == "pistol":
		print("pistolspecial")

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
				animation_player.play("fire")
			elif ammo == 0: animation_player.play("reload_pistol")
	
	if Input.is_action_pressed("inspect weapon"):
		if animation_player.current_animation == "reload_pistol":
			pass
		else:
			animation_player.play("inspect")
			
		
	if Input.is_action_pressed("reload"):
		if ammo != 50:
			animation_player.play("reload_pistol")
			
	# special action
	if Input.is_action_just_pressed("right click action"):
		special("pistol")
