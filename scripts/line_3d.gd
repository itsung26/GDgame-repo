@tool
class_name Line3D
extends Node3D
## Renders a line between two points via configuring a [QuadMesh].

## Thickness of the rendered line (quad height in local space).
@export var line_thickness:float = 1.0:
	set = setLineThickness
## Material applied to the internal [MeshInstance3D].
@export var material:Material:
	set = setMaterial
## Local-space start point of the line.
@export var point_a:Vector3:
	set = setPointA
## Local-space end point of the line.
@export var point_b:Vector3:
	set = setPointB

var mesh_instance:MeshInstance3D = MeshInstance3D.new()
var quad_mesh:QuadMesh = QuadMesh.new()


## Sets [member line_thickness] and updates the underlying [QuadMesh] thickness.
func setLineThickness(newLineHeight:float) -> void:
	line_thickness = newLineHeight
	quad_mesh.size.y = line_thickness


## Sets [member material] and applies it to the rendered mesh instance.
func setMaterial(new_material:Material) -> void:
	material = new_material
	mesh_instance.material_override = material


## Sets [member point_a] and refreshes line transform/size.
func setPointA(newPointA:Vector3) -> void:
	point_a = newPointA
	updateLineVisual()


## Sets [member point_b] and refreshes line transform/size.
func setPointB(newPointB:Vector3) -> void:
	point_b = newPointB
	updateLineVisual()


## Returns the midpoint between [param point_a] and [param point_b] in local space.
func getMidpointPoint(point_a:Vector3, point_b:Vector3) -> Vector3:
	return (point_a + point_b) / 2.0


## Initializes internal mesh resources when the node becomes ready.
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			mesh_instance.mesh = quad_mesh
			if mesh_instance.get_parent() == null:
				add_child(mesh_instance)
			mesh_instance.material_override = material
			quad_mesh.size.y = line_thickness
			updateLineVisual()


## Updates the mesh midpoint, length, and orientation from [member point_a] and [member point_b].
func updateLineVisual() -> void:
	if mesh_instance.get_parent() == null:
		return
	mesh_instance.position = getMidpointPoint(point_a, point_b)
	quad_mesh.size.x = sqrt(point_a.distance_squared_to(point_b))
	lookAtPoint(to_global(point_b), Vector3(1.0, 0.0, 0.0), Vector3.UP, mesh_instance)


## Makes [param looker] look at [param point], where [param forwards] is the front axis and [param up] is the up axis.
func lookAtPoint(point:Vector3, forwards:Vector3, up:Vector3, looker:Node3D) -> void:
	if looker == null:
		Debug.logerr("lookAtPoint failed: [param looker] cannot be null.")
		return
	
	if forwards.length_squared() == 0.0:
		Debug.logerr("lookAtPoint failed: [param forwards] cannot be zero.")
		return
	
	if up.length_squared() == 0.0:
		Debug.logerr("lookAtPoint failed: [param up] cannot be zero.")
		return
	
	var direction:Vector3 = point - looker.global_position
	if direction.length_squared() == 0.0:
		return
	
	looker.look_at(point, up.normalized())
	var forward_alignment:Basis = Basis(Quaternion(forwards.normalized(), Vector3.FORWARD))
	looker.global_basis = looker.global_basis * forward_alignment
