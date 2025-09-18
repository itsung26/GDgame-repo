# @tool
extends Node3D
@onready var grapple_start: RayCast3D = $GrappleStart
@onready var mesh_instance_3d: MeshInstance3D = $GrappleStart/MeshInstance3D
@onready var a: Marker3D = $GrappleStart/A
@onready var b: Marker3D = $GrappleStart/B
@onready var player: CharacterBody3D = $"../Player"

var current_mesh

# generates two parallel quads using 2 points with ops to get 10 points total
#func generate_mesh_planes(origin:Vector3 , target:Vector3):
	#if target:
		#grapple_start.look_at(target)
	#
	#var shape_width := Vector3(width, 0, 0)
	#var shape_height := Vector3(0, height, 0)
	#
	#var array_mesh_new = ArrayMesh.new()
	#
	#var vertices = PackedVector3Array()
	## beginning end
	#var p1 := origin
	#var p1_right := origin + shape_width
	#var p1_left := origin - shape_width
	#var p1_up := origin + shape_height
	#var p1_down := origin - shape_height
	#
	## ending end
	#var p2 := target
	#var p2_right := target + shape_width
	#var p2_left := target - shape_width
	#var p2_up := target + shape_height
	#var p2_down := target - shape_height
	#
	## Populate vertex data
	#vertices.append(p1) # index 0
	#vertices.append(p1_right) # index 1
	#vertices.append(p1_left) # index 2
	#vertices.append(p1_up) # index 3
	#vertices.append(p1_down) # index 4
	#
	#vertices.append(p2) # index 5
	#vertices.append(p2_right) # index 6
	#vertices.append(p2_left) # index 7
	#vertices.append(p2_down) # index 8
	#vertices.append(p2_up) # index 9
	#
	#var indices = PackedInt32Array()
	## order quad is drawn on the left and right axis
	#indices.append_array([1, 2, 6, 6, 2, 7])
	#
	## order quad is drawn on the up and down axis
	#indices.append_array([3, 4, 9, 9, 8, 4])
	#
	## Build the array-of-arrays
	#var arrays = []
	#arrays.resize(Mesh.ARRAY_MAX)
	#arrays[Mesh.ARRAY_VERTEX] = vertices
	#arrays[Mesh.ARRAY_INDEX] = indices
	#
	## Add surface
	#array_mesh_new.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	#mesh_instance_3d.mesh = array_mesh_new
	#
	## modify color
	#mesh_instance_3d.get_surface_override_material(0).albedo_color = color
