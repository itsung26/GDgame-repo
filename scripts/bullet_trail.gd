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
	billboardToCameraX()
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

## Serves as a constructor, called after being added as a child to scene.
func setup(origin_pos:Vector3, target_pos:Vector3, color:Color = Color.WHITE):
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

## Rotate on Z axis so the X+ axis (quad front face) faces the currently active camera.
func billboardToCameraX() -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return
	# Camera position in this node's local space
	var cam_local: Vector3 = to_local(cam.global_position)
	# Rotate only around the Z axis so X+ faces the camera direction
	var desired_pitch := atan2(cam_local.y, cam_local.x) # X+ is forward
	var r := rotation
	r.z = desired_pitch
	rotation = r
