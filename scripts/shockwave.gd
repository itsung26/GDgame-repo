@tool
class_name Shockwave
extends Node3D

#region @onready vars
@onready var half_torus: HalfTorus = $HalfTorus
@onready var shader_driver: ShaderDriver = $ShaderDriver
@onready var shockwave_collider: CollisionShape3D = $ShockwaveHurtbox/ShockwaveCollider
#endregion

#region @export vars
@export var shockwave_config:ShockwaveConfig
@export_tool_button("test activate") var a:Callable = setup
#endregion

#region regular vars
## Drives the size and alpha properties of the shockwave ring.
@export var size:float:
	set = setSize
var expanding:bool = false:
	set = setExpanding
var _initial_size:float
#endregion


func _process(delta: float) -> void:
	if expanding:
		shockwave_collider.shape = getConvexShape()
		size = move_toward(size, shockwave_config.ending_size, shockwave_config.expand_speed * delta)
		if size == shockwave_config.ending_size:
			expanding = false


func setSize(size_new:float) -> void:
	size = size_new
	
	# update the mesh visual radius
	half_torus.outer_radius = size_new
	# update the mesh shader alpha
	shader_driver.setShaderParameter(&"alpha", shockwave_config.alpha_curve.sample_baked(getNormalizedSize()))
	


func setExpanding(expanding_new:bool) -> void:
	expanding = expanding_new


## Returns how close size is to shockwave_config.ending_size in terms of 0 to 1.
## When size = shockwave_config.ending_size, 1 is returned.
## When size = shockwave_config.beginning_size, 0 is returned.
func getNormalizedSize() -> float:
	return remap(size, shockwave_config.beginning_size, shockwave_config.ending_size, 0.0, 1.0)


## Returns a convex shape matching the mesh shape.
func getConvexShape() -> ConvexPolygonShape3D:
	if half_torus == null:
		return ConvexPolygonShape3D.new()

	if half_torus.mesh == null:
		return ConvexPolygonShape3D.new()

	var convex_shape:ConvexPolygonShape3D = half_torus.mesh.create_convex_shape()
	if convex_shape == null:
		return ConvexPolygonShape3D.new()

	return convex_shape


func setup() -> void:
	shader_driver.setShaderParameter(&"primary_color", shockwave_config.ring_color)
	size = shockwave_config.beginning_size
	_initial_size = size
	expanding = true
