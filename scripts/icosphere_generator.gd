@tool
class_name IcosphereGenerator
extends MeshInstance3D

#region @export vars
@export var radius: float = 1.0:
	set = setRadius
@export_range(0, 6) var subdivisions: int = 6:
	set = setSubdivisions


func _notification(what: int) -> void:
	if what == NOTIFICATION_READY:
		return


func setRadius(newRadius: float) -> void:
	radius = maxf(newRadius, 0.0)
	_rebuildMesh()


func setSubdivisions(newSubdivisions: int) -> void:
	subdivisions = clampi(newSubdivisions, 0, 6)
	_rebuildMesh()


## Returns an ImmediateMesh Icosphere.
func generateIcosphere(radius: float, subdivisions: int) -> ImmediateMesh:
	var immidiate_mesh_new: ImmediateMesh
	if mesh is ImmediateMesh:
		immidiate_mesh_new = mesh as ImmediateMesh
	else:
		immidiate_mesh_new = ImmediateMesh.new()
	immidiate_mesh_new.clear_surfaces()
	var safeRadius: float = maxf(radius, 0.0)
	var safeSubdivisions: int = maxi(subdivisions, 0)
	var t: float = (1.0 + sqrt(5.0)) / 2.0
	var vertices: Array[Vector3] = [
		Vector3(-1.0, t, 0.0),
		Vector3(1.0, t, 0.0),
		Vector3(-1.0, -t, 0.0),
		Vector3(1.0, -t, 0.0),
		Vector3(0.0, -1.0, t),
		Vector3(0.0, 1.0, t),
		Vector3(0.0, -1.0, -t),
		Vector3(0.0, 1.0, -t),
		Vector3(t, 0.0, -1.0),
		Vector3(t, 0.0, 1.0),
		Vector3(-t, 0.0, -1.0),
		Vector3(-t, 0.0, 1.0),
	]
	var i: int = 0
	while i < vertices.size():
		vertices[i] = vertices[i].normalized()
		i += 1
	var faces: Array[PackedInt32Array] = [
		PackedInt32Array([0, 11, 5]),
		PackedInt32Array([0, 5, 1]),
		PackedInt32Array([0, 1, 7]),
		PackedInt32Array([0, 7, 10]),
		PackedInt32Array([0, 10, 11]),
		PackedInt32Array([1, 5, 9]),
		PackedInt32Array([5, 11, 4]),
		PackedInt32Array([11, 10, 2]),
		PackedInt32Array([10, 7, 6]),
		PackedInt32Array([7, 1, 8]),
		PackedInt32Array([3, 9, 4]),
		PackedInt32Array([3, 4, 2]),
		PackedInt32Array([3, 2, 6]),
		PackedInt32Array([3, 6, 8]),
		PackedInt32Array([3, 8, 9]),
		PackedInt32Array([4, 9, 5]),
		PackedInt32Array([2, 4, 11]),
		PackedInt32Array([6, 2, 10]),
		PackedInt32Array([8, 6, 7]),
		PackedInt32Array([9, 8, 1]),
	]
	var step: int = 0
	while step < safeSubdivisions:
		var midpointCache: Dictionary = { }
		var nextFaces: Array[PackedInt32Array] = []
		var faceIndex: int = 0
		while faceIndex < faces.size():
			var face: PackedInt32Array = faces[faceIndex]
			var a: int = face[0]
			var b: int = face[1]
			var c: int = face[2]
			var ab: int = _midpointIndex(a, b, vertices, midpointCache)
			var bc: int = _midpointIndex(b, c, vertices, midpointCache)
			var ca: int = _midpointIndex(c, a, vertices, midpointCache)
			nextFaces.append(PackedInt32Array([a, ab, ca]))
			nextFaces.append(PackedInt32Array([b, bc, ab]))
			nextFaces.append(PackedInt32Array([c, ca, bc]))
			nextFaces.append(PackedInt32Array([ab, bc, ca]))
			faceIndex += 1
		faces = nextFaces
		step += 1
	immidiate_mesh_new.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var drawFaceIndex: int = 0
	var windingOrder: PackedInt32Array = PackedInt32Array([0, 2, 1])
	while drawFaceIndex < faces.size():
		var drawFace: PackedInt32Array = faces[drawFaceIndex]
		var corner: int = 0
		while corner < 3:
			var vertex: Vector3 = vertices[drawFace[windingOrder[corner]]]
			var normal: Vector3 = vertex.normalized()
			immidiate_mesh_new.surface_set_normal(normal)
			immidiate_mesh_new.surface_add_vertex(normal * safeRadius)
			corner += 1
		drawFaceIndex += 1
	immidiate_mesh_new.surface_end()
	return immidiate_mesh_new


## Regenerates the icosphere based on the radius and subdivisions properties and re-assigns it
## to the meshinstance3d.
func _rebuildMesh() -> void:
	if not is_inside_tree():
		return
	mesh = generateIcosphere(radius, subdivisions)


func _midpointIndex(a: int, b: int, vertices: Array[Vector3], midpointCache: Dictionary) -> int:
	var low: int = mini(a, b)
	var high: int = maxi(a, b)
	var key: String = str(low) + "_" + str(high)
	if midpointCache.has(key):
		return midpointCache[key]
	var midpoint: Vector3 = (vertices[low] + vertices[high]) * 0.5
	var midpointIndex: int = vertices.size()
	vertices.append(midpoint.normalized())
	midpointCache[key] = midpointIndex
	return midpointIndex
#endregion
