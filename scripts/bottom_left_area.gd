extends Control

@onready var player = get_tree().current_scene.find_child("Player")
@onready var ammo_panel: SubViewportContainer = $AmmoPanel

# left and right lerp parameters
@export var ammo_panel_position_lerp_speed:float = 5.0
@export var ammo_panel_lerp_left_target:float = 24.0
@export var ammo_panel_lerp_right_target:float = 64.0
var ammo_panel_lerp_center_target:float

# foward and back (scale) parameters
@export var ammo_panel_scale_lerp_speed:float = 5.0
@export var ammo_panel_back_target:float = 1.5
@export var ammo_panel_forward_target:float = 0.5

func _ready() -> void:
	ammo_panel_lerp_center_target = ammo_panel.position.x

func shiftMenuPos(delta=get_process_delta_time()): # void
	# move left and right based on player input accordingly
	if player.input_dir.x < 0:
		ammo_panel.position.x = lerp(ammo_panel.position.x, ammo_panel_lerp_left_target, ammo_panel_position_lerp_speed * delta)
	elif player.input_dir.x > 0:
		ammo_panel.position.x = lerp(ammo_panel.position.x, ammo_panel_lerp_right_target, ammo_panel_position_lerp_speed * delta)
	else:
		ammo_panel.position.x = lerp(ammo_panel.position.x, ammo_panel_lerp_center_target, ammo_panel_position_lerp_speed * delta)
	
	# scale in and out based on player fowards and back
	if player.input_dir.y < 0:
		ammo_panel.scale = lerp(ammo_panel.scale, Vector2(ammo_panel_back_target, ammo_panel_back_target), ammo_panel_scale_lerp_speed * delta)
	elif player.input_dir.y > 0:
		ammo_panel.scale = lerp(ammo_panel.scale, Vector2(ammo_panel_forward_target, ammo_panel_forward_target), ammo_panel_scale_lerp_speed * delta)
	else:
		ammo_panel.scale = lerp(ammo_panel.scale, Vector2(1.0, 1.0), ammo_panel_scale_lerp_speed * delta)

	
func _process(delta: float) -> void:
	print(ammo_panel_lerp_left_target)
	print(ammo_panel.position.x)
	shiftMenuPos()
