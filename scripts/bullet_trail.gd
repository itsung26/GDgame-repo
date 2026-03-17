@tool
class_name BulletTrail
extends MeshInstance3D

var shrinking_y:bool = false
@export var shrink_curve:Curve
@export var shrink_duration: float = 0.25 # seconds to go from 0..1 along the curve

var _elapsed: float = 0.0
var _base_height: float = 0.25

func _ready() -> void:
	# Cache the starting mesh height
	var q: QuadMesh = mesh as QuadMesh
	if q:
		_base_height = q.size.y

# Called every frame.
func _process(delta: float) -> void:
	if not shrinking_y:
		return
	if shrink_curve == null:
		return
	_elapsed += delta
	var t = clamp(_elapsed / max(shrink_duration, 0.0001), 0.0, 1.0)
	var factor := shrink_curve.sample_baked(t) # 0..1 from the curve
	
	var q: QuadMesh = mesh as QuadMesh
	if q:
		var sz := q.size
		sz.y = _base_height * factor
		q.size = sz
	
	if t >= 1.0:
		shrinking_y = false
	
	# When the quad shrinks to nothing (y size of 0), free
	if q.size.y == 0.0:
		queue_free()

# Serves as a constructor, called after being added as a child to scene.
func setup(origin_pos:Vector3, target_pos:Vector3, color:Color = Color.GOLD):
	global_position = (origin_pos + target_pos) / 2.0
	look_at(target_pos, Vector3.UP)
	shrinking_y = true
	_elapsed = 0.0
	var q: QuadMesh = mesh as QuadMesh
	if q:
		var sz := q.size
		_base_height = sz.y
		sz.x = origin_pos.distance_to(target_pos)
		q.size = sz

	# Apply color into the ShaderMaterial driving this trail, if present.
	# Prefer material_override; fall back to the mesh surface material.
	var mat: Material = mesh.surface_get_material(0)
	if mat is ShaderMaterial:
		var sm := mat as ShaderMaterial
		if sm.get_shader_parameter("albedo") is Color:
			sm.set_shader_parameter("albedo", color)
		if sm.get_shader_parameter("emission") is Color:
			sm.set_shader_parameter("emission", color)
