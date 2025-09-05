extends Skeleton3D

@onready var bullet_ray_cast: RayCast3D = $"../../BulletRayCast"
@onready var camera_3d: Camera3D = %Camera3D
@onready var animation_player: AnimationPlayer = $"../../../../AnimationPlayer"
@onready var pistol_sway_pivot: Node3D = $".."
@onready var player: CharacterBody3D = $"../../../.."


const DAMAGE_HITMARKER_SCENE = preload("res://scenes/damage_hitmarker.tscn")
const BULLET_DECAL_BLUE = preload("res://scenes/bullet_decal.tscn")
const BLUE_EMISSIVE_MATERIAL = preload("res://assets/materials/emissives/blue_emissive_material.tres")
const RED_EMISSIVE_MATERIAL = preload("res://assets/materials/emissives/red_emissive_material.tres")

# ammo is globally defined

# bar charge
var pistol_isCharged

# instantiate a body from the return of the get_collider() method
# this method is called every time the animation for firing runs and is essentially the bulk of the shoot code
# refer to the _process method for the animations, which are triggered by only input
func fire():
	var body = bullet_ray_cast.get_collider()
	var b = BULLET_DECAL_BLUE.instantiate()
	var b_mesh = b.get_node("MeshInstance3D")
	
	# duplicates the surface material and applies the duplicate to the new instance
	# conditional for if special is active
	if Global.pistol_special_state:
		b_mesh.set_surface_override_material(0, RED_EMISSIVE_MATERIAL.duplicate())
	else:
		b_mesh.set_surface_override_material(0, BLUE_EMISSIVE_MATERIAL.duplicate())
	
	# below occurs regardless of wether the bullets hit something or otherwise
	Global.blaster_ammo -= 1
	
	# signal the body that was just hit for debug
	Global.body_hit = body
	
	# pass if returns null to avoid null refrence errors
	# in other words, IF IT HITS SOMETHING DO THIS VVVVVV
	if body != null:
		body.add_child(b)
		b.global_transform.origin = bullet_ray_cast.get_collision_point()
		b.look_at(bullet_ray_cast.get_collision_point() + bullet_ray_cast.get_collision_normal(), Vector3.UP)
		
		if body.is_in_group("enemy"):
			body.HEALTH = body.HEALTH - Global.pistol_DAMAGE
			print("HEALTH of enemy: " + str(body.HEALTH))

			# --- Show hitmarker on HUD at hit position ---
			var hitmarker = DAMAGE_HITMARKER_SCENE.instantiate()
			# get the label node
			var hitmarker_label_node = hitmarker.get_node("DamageNumberLabel") # Use the correct node name
			# set the text
			if hitmarker_label_node:
				hitmarker_label_node.text = str(Global.pistol_DAMAGE)
			
			# Get the HUD node (adjust path as needed)
			var hud = get_tree().root.get_node("main/HUD")
			if hud:
				hud.add_child(hitmarker)
				# Set tracking references for the hitmarker
				hitmarker.tracked_enemy = body
				hitmarker.tracked_camera = camera_3d
				# Set initial position
				hitmarker.position = camera_3d.unproject_position(body.global_position) + hitmarker.randoffset
				# Add a process callback to update the hitmarker position every frame
				hitmarker.process_mode = Node.PROCESS_MODE_ALWAYS
		else:
			print("bullet hit something that is not an enemy, and thus does not have HEALTH")
	
	# bullet spread
	bullet_ray_cast.rotation_degrees = Vector3(randf_range(-4, 4), randf_range(-184, -176), 0)


func reload():
	Global.blaster_ammo = 50
	
# called on right click
func special(weapon):
	if weapon == "pistol":
		# if the pistol is charged and not busy, activate the special state
		if Global.is_pistol_charged:
			# special state is currently active
			Global.pistol_activate_special = true
			Global.pistol_special_state = true
			

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	if not player.pistol_damage_increase:
		Global.pistol_DAMAGE = randi_range(3,6)
	elif player.pistol_damage_increase:
		Global.pistol_DAMAGE = randi_range(8,15)
