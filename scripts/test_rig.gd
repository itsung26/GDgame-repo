@tool
extends Node3D
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var a: Node3D = $A
@onready var a_2: Node3D = $A2
@onready var b: Node3D = $B
@onready var b_2: Node3D = $B2

var verticies = []

func _ready():
	print("called ready")
	

func _process(float) -> void:
	pass
	generate_mesh_plane()

func generate_mesh_plane():
	var array_mesh_new = ArrayMesh.new()
	
	# print(ArrayMesh.ARRAY_MAX)
	# verticies.resize(ArrayMesh.ARRAY_MAX)
	
	var p1 := a.global_position
	var p2 := a_2.global_position
	var p3 := b.global_position
	var p4 := b_2.global_position
	
	# Populate vertex data
	verticies.append(p1)
	verticies.append(p2)
	verticies.append(p3)
	verticies.append(p4)
	
	array_mesh_new.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, verticies)
	mesh_instance_3d.mesh = array_mesh_new
