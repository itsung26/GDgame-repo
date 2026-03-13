class_name BottomLeftMenu extends Control
## A HUD element that sways and scales based on player movement input.
##
## The ammo panel shifts left/right when the player strafes, and scales
## up/down when the player moves forward/backward, creating a subtle
## motion-linked feedback effect.

@onready var player: Player = get_tree().current_scene.find_child("Player")
@onready var ammo_panel: SubViewportContainer = $AmmoPanel

@export_group("Horizontal Sway")
## Speed at which the panel lerps to target positions.
@export var sway_speed: float = 5.0
## How far the panel sways from center position.
@export var sway_amount: float = 10.0

@export_group("Depth Scale")
## Speed at which the panel lerps to target scale.
@export var scale_speed: float = 2.5
## Scale when moving forward (panel "comes toward" the player).
@export var forward_scale: float = 1.1
## Scale when moving backward (panel "recedes" from the player).
@export var back_scale: float = 0.95

## The panel's resting X position, captured on ready.
var _center_x: float


func _ready() -> void:
	_center_x = ammo_panel.position.x


func _process(delta: float) -> void:
	Debug.log(ammo_panel.position)
	_update_sway(delta)
	_update_scale(delta)


## Shifts the panel left/right based on player horizontal input.
## The panel sways opposite to movement direction, creating an inertia effect.
func _update_sway(delta: float) -> void:
	var input_x: float = player.input_dir.x
	var target_x: float = _center_x
	
	if input_x < 0.0:
		target_x = _center_x + sway_amount  # moving left → panel sways right (+x)
	elif input_x > 0.0:
		target_x = _center_x - sway_amount  # moving right → panel sways left (-x)
	
	ammo_panel.position.x = lerp(ammo_panel.position.x, target_x, sway_speed * delta)


## Scales the panel based on player forward/backward input.
func _update_scale(delta: float) -> void:
	var input_y: float = player.input_dir.y
	var target_scale: float = 1.0
	
	# input_dir.y < 0 means forward, > 0 means backward
	if input_y < 0.0:
		target_scale = forward_scale
	elif input_y > 0.0:
		target_scale = back_scale
	
	var target_vec := Vector2(target_scale, target_scale)
	ammo_panel.scale = lerp(ammo_panel.scale, target_vec, scale_speed * delta)
