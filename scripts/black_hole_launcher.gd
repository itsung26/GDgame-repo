extends Node3D
@onready var bll_animator: AnimationPlayer = $"../../../../BLLAnimator"
@onready var fire_ready_light_green: MeshInstance3D = $SightPart/FireReadyLightGREEN
@onready var fire_ready_light_red: MeshInstance3D = $SightPart/FireReadyLightRED
@onready var fire_marker: Node3D = $FireMarker
@onready var player: CharacterBody3D = $"../../../.."


const BLACK_HOLE_PROJECTILE = preload("res://scenes/black_hole_projectile.tscn")
var can_play_anims : bool = true
var is_launcher_raised = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if player.BLL_AMMO > 0:
		if not is_launcher_raised:
			bll_animator.play("Black Hole Launcher/BLL_equip")
			is_launcher_raised = true
		can_play_anims = true
		if not bll_animator.is_playing():
			fire_ready_light_green.visible = true
			fire_ready_light_red.visible = false
	
	elif player.BLL_AMMO == 0:
		fire_ready_light_red.visible = true
		fire_ready_light_green.visible = false
		if not bll_animator.is_playing() and can_play_anims:
			bll_animator.play("Black Hole Launcher/BLL_put_down")
			is_launcher_raised = false

func denyAnims():
	can_play_anims =false

func BLLFire():
	player.BLL_AMMO -= 1
	var black_h_projectile = BLACK_HOLE_PROJECTILE.instantiate()
	get_tree().current_scene.add_child(black_h_projectile)
	black_h_projectile.global_position = fire_marker.global_position
	black_h_projectile.global_rotation = fire_marker.global_rotation
	# move in the direction of the FireDirection node
	var direction = -fire_marker.global_transform.basis.z.normalized()
	black_h_projectile.linear_velocity = direction * player.BLL_projectile_travel_speed * get_physics_process_delta_time()
