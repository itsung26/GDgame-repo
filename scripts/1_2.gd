extends Node3D

@export var delay_before_lights_enable:float = 1.0

@onready var delay_before_lights: Timer = $"delay before lights"

func _on_entering_room_5_body_entered(body: Player) -> void:
	delay_before_lights.start(delay_before_lights_enable)


func _on_delay_before_lights_timeout() -> void:
	var room_5: MeshInstance3D = $"1-2/room 5"
	var room_5_shader_material:ShaderMaterial = room_5.get_surface_override_material(3)
	
	room_5_shader_material.set_shader_parameter(&"Blackout", false)
