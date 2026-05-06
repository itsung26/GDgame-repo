@tool
## Generates a procedural half-torus mesh with a closed bottom cap.
## The mesh is rebuilt whenever exported shaping parameters change.
class_name HalfTorus
extends MeshInstance3D


## Absolute outer radius of the torus profile (distance from center to outside edge).
@export var outer_radius:float = 2.5:
	set = set_outer_radius
## Thickness control where 0.0 maps to inner = 0.5 * outer and 1.0 maps to inner = outer.
@export_range(0.0, 1.0, 0.001) var inner_to_outer_ratio:float = 0.5:
	set = set_inner_to_outer_ratio
## Optional fixed tube radius override. Set to 0.0 to use ratio-based thickness.
@export_range(0.0, 10.0) var fixed_height:float = 0.0:
	set = set_fixed_height
## Number of segments around the major torus ring.
@export_range(3, 256, 1) var radial_segments:int = 64:
	set = set_radial_segments
## Number of segments along the half-circle tube profile.
@export_range(3, 128, 1) var tube_segments:int = 32:
	set = set_tube_segments


func _ready() -> void:
	_rebuild_mesh()


func set_outer_radius(new_value:float) -> void:
	outer_radius = max(new_value, 0.001)
	_rebuild_mesh()


func set_inner_to_outer_ratio(new_value:float) -> void:
	inner_to_outer_ratio = clamp(new_value, 0.0, 1.0)
	_rebuild_mesh()


func set_fixed_height(new_value:float) -> void:
	fixed_height = max(new_value, 0.0)
	_rebuild_mesh()


func set_radial_segments(new_value:int) -> void:
	radial_segments = max(new_value, 3)
	_rebuild_mesh()


func set_tube_segments(new_value:int) -> void:
	tube_segments = max(new_value, 3)
	_rebuild_mesh()


func _rebuild_mesh() -> void:
	var r:float = _current_computed_tube_radius()
	if fixed_height > 0.0:
		r = min(fixed_height, outer_radius)
	var R:float = outer_radius - r
	mesh = generate_half_torus(R, r)


func _current_inner_radius() -> float:
	var mapped_ratio:float = 0.5 + (0.5 * inner_to_outer_ratio)
	return outer_radius * mapped_ratio


func _current_computed_tube_radius() -> float:
	var inner_radius:float = _current_inner_radius()
	return (outer_radius - inner_radius) * 0.5


func generate_half_torus(R: float, r: float) -> ImmediateMesh:
	var immediate_mesh:ImmediateMesh
	if mesh is ImmediateMesh:
		immediate_mesh = mesh as ImmediateMesh
	else:
		immediate_mesh = ImmediateMesh.new()

	immediate_mesh.clear_surfaces()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for i:int in range(radial_segments):
		var u0:float = TAU * float(i) / float(radial_segments)
		var u1:float = TAU * float(i + 1) / float(radial_segments)

		for j:int in range(tube_segments):
			var v0:float = PI * float(j) / float(tube_segments)
			var v1:float = PI * float(j + 1) / float(tube_segments)

			var p00:Vector3 = torus_point(R, r, u0, v0)
			var p10:Vector3 = torus_point(R, r, u1, v0)
			var p01:Vector3 = torus_point(R, r, u0, v1)
			var p11:Vector3 = torus_point(R, r, u1, v1)
			var n00:Vector3 = torus_normal(u0, v0)
			var n10:Vector3 = torus_normal(u1, v0)
			var n01:Vector3 = torus_normal(u0, v1)
			var n11:Vector3 = torus_normal(u1, v1)

			_emit_triangle(immediate_mesh, p00, n00, p10, n10, p11, n11)

			_emit_triangle(immediate_mesh, p00, n00, p11, n11, p01, n01)

		var outer0:Vector3 = torus_point(R, r, u0, 0.0)
		var outer1:Vector3 = torus_point(R, r, u1, 0.0)
		var inner0:Vector3 = torus_point(R, r, u0, PI)
		var inner1:Vector3 = torus_point(R, r, u1, PI)
		_emit_bottom_cap(immediate_mesh, outer0, outer1, inner0, inner1)

	immediate_mesh.surface_end()
	return immediate_mesh


func torus_point(R: float, r: float, u: float, v: float) -> Vector3:
	return Vector3(
		(R + r * cos(v)) * cos(u),
		r * sin(v),
		(R + r * cos(v)) * sin(u)
	)


func torus_normal(u:float, v:float) -> Vector3:
	return Vector3(
		cos(v) * cos(u),
		sin(v),
		cos(v) * sin(u)
	).normalized()


func _emit_triangle(immediate_mesh:ImmediateMesh, a:Vector3, an:Vector3, b:Vector3, bn:Vector3, c:Vector3, cn:Vector3) -> void:
	immediate_mesh.surface_set_normal(an)
	immediate_mesh.surface_add_vertex(a)
	immediate_mesh.surface_set_normal(bn)
	immediate_mesh.surface_add_vertex(b)
	immediate_mesh.surface_set_normal(cn)
	immediate_mesh.surface_add_vertex(c)


func _emit_bottom_cap(immediate_mesh:ImmediateMesh, outer0:Vector3, outer1:Vector3, inner0:Vector3, inner1:Vector3) -> void:
	var cap_normal:Vector3 = Vector3.DOWN
	_emit_triangle(immediate_mesh, outer0, cap_normal, inner0, cap_normal, inner1, cap_normal)
	_emit_triangle(immediate_mesh, outer0, cap_normal, inner1, cap_normal, outer1, cap_normal)
