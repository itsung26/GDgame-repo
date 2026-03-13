class_name BottomLeftMenu extends Control
## A HUD element that sways and scales based on player velocity.
##
## The ammo panel shifts left/right when the player strafes, and scales
## up/down when the player moves forward/backward, creating a subtle
## inertia-like feedback effect based on actual movement.

@onready var player: Player = get_tree().get_first_node_in_group("players")
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


## Shifts the panel left/right based on player strafe velocity.
## The panel sways opposite to movement direction, creating an inertia effect.
func _update_sway(delta: float) -> void:
	# Convert world velocity to local velocity relative to player facing direction.
	var local_velocity: Vector3 = player.global_transform.basis.inverse() * player.velocity
	var strafe_velocity: float = local_velocity.x  # positive = moving right, negative = moving left
	
	# Sway opposite to strafe direction, scaled by velocity magnitude.
	var normalized_strafe: float = clamp(strafe_velocity / player.SPEED, -1.0, 1.0)
	var target_x: float = _center_x - (normalized_strafe * sway_amount)
	
	ammo_panel.position.x = lerp(ammo_panel.position.x, target_x, sway_speed * delta)


## Scales the panel based on player forward/backward velocity.
func _update_scale(delta: float) -> void:
	# Convert world velocity to local velocity relative to player facing direction.
	var local_velocity: Vector3 = player.global_transform.basis.inverse() * player.velocity
	var forward_velocity: float = -local_velocity.z  # negative z = forward in Godot, so invert
	
	# Determine scale based on forward/backward movement.
	var normalized_forward: float = clamp(forward_velocity / player.SPEED, -1.0, 1.0)
	var target_scale: float = 1.0
	
	if normalized_forward > 0.1:
		target_scale = lerpf(1.0, forward_scale, normalized_forward)
	elif normalized_forward < -0.1:
		target_scale = lerpf(1.0, back_scale, -normalized_forward)
	
	var target_vec := Vector2(target_scale, target_scale)
	ammo_panel.scale = lerp(ammo_panel.scale, target_vec, scale_speed * delta)
