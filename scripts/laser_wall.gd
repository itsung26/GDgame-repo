class_name LaserWall
extends MeshInstance3D

@onready var refresh_timer: Timer = $RefreshTimer
@onready var collision_shape_3d: CollisionShape3D = $LaserWallHazardArea/CollisionShape3D

@export var refresh_interval:float = 0.046
@export var active:bool = true:
	set = setActive

func _process(delta: float) -> void:
	refresh_timer.wait_time = refresh_interval


func setOffset(new:Vector2) -> void:
	var shader:ShaderMaterial = material_override
	shader.set_shader_parameter(&"offset", new)


func setActive(new:bool) -> void:
	active = new
	visible = active
	collision_shape_3d.disabled = !active


func _on_refresh_timer_timeout() -> void:
	setOffset(Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0)))
