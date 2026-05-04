@tool
class_name DoorSmall
extends Node3D

#region @onready vars
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var door_shape_3d: CollisionShape3D = $DoorStaticBody/DoorShape3D
@onready var shader_driver: ShaderDriver = $ShaderDriver
#endregion

#region @export vars
@export var open: bool = false:
	set = setOpen
@export var locked: bool = false:
	set = setLocked
@export var laser_grid_enabled: bool = false:
	set = setLaserGridEnabled
@export var laser_grid_dissolve_speed:float
#endregion

#region regular vars
var has_opened:bool = false
#endregion


func _process(delta: float) -> void:
	var laser_dissolve_fac:float = shader_driver.getShaderParameter(&"dissolve_fac")
	if laser_grid_enabled:
		shader_driver.setShaderParameter(
			&"dissolve_fac", 
			move_toward(laser_dissolve_fac, 0.0, laser_grid_dissolve_speed * delta)
			)
	elif not laser_grid_enabled:
		shader_driver.setShaderParameter(
			&"dissolve_fac",
			move_toward(laser_dissolve_fac, 1.0, laser_grid_dissolve_speed * delta)
		)


func setOpen(new_open: bool) -> void:
	if locked:
		return
	open = new_open
	
	if new_open == true:
		animation_player.play("door_open")
		door_shape_3d.disabled = true
		has_opened = true
	elif new_open == false:
		animation_player.play("door_close")
		door_shape_3d.disabled = false
	


func setLocked(new_locked: bool) -> void:
	locked = new_locked
	


func setLaserGridEnabled(new_laser_grid_enabled: bool) -> void:
	laser_grid_enabled = new_laser_grid_enabled


func _on_entry_area_body_entered(body: Node3D) -> void:
	if body is Player:
		if has_opened or locked:
			return
		else:
			open = true
