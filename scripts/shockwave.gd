@tool
class_name Shockwave
extends Node3D

#region @onready vars
@onready var half_torus: HalfTorus = $HalfTorus
@onready var shader_driver: ShaderDriver = $ShaderDriver
@onready var shockwave_hurtbox: Area3D = $ShockwaveHurtbox
@onready var shockwave_collider: CollisionShape3D = $ShockwaveHurtbox/ShockwaveCollider
#endregion

#region @export vars
@export var shockwave_config:ShockwaveConfig
## Drives the size and alpha properties of the shockwave ring.
@export var size:float:
	set = setSize
@export_tool_button("test activate") var a:Callable = setup
@export_tool_button("test collider generation") var b:Callable = test
#endregion

#region regular vars
var expanding:bool = false:
	set = setExpanding
var _initial_size:float
#endregion


func test() -> void:
	return
	buildTrimeshCollider()


func _process(delta: float) -> void:
	#var current_scene:Node = get_tree().current_scene
	#if current_scene != null:
		#var collision_shapes:Array[Node] = current_scene.find_children("*", "CollisionShape3D", true, false)
		#for collision_shape:Node in collision_shapes:
			#Debug.log(collision_shape)
	if not Engine.is_editor_hint():
		if Input.is_action_just_pressed("debug func"):
			setup()
	if expanding:
		size = move_toward(size, shockwave_config.ending_size, shockwave_config.expand_speed * delta)
		if size == shockwave_config.ending_size:
			expanding = false


func setSize(size_new:float) -> void:
	size = size_new
	if half_torus == null or shader_driver == null or shockwave_hurtbox == null:
		return
	
	# update the mesh visual radius
	half_torus.outer_radius = size_new
	# update the mesh shader alpha
	shader_driver.setShaderParameter(&"alpha", shockwave_config.alpha_curve.sample_baked(getNormalizedSize()))
	# update the collision shape
	buildTrimeshCollider()
	# update ring height
	half_torus.fixed_height = shockwave_config.shockwave_height


## Creates multiple convex colliders in the form of collisionshape3D from source_mesh_instance
## using decomposition_settings as children of target_parent.
func decomposeToMultipleConvex(
	source_mesh_instance: MeshInstance3D,
	target_parent: Node,
	decomposition_settings: MeshConvexDecompositionSettings
) -> void:
	if source_mesh_instance == null:
		return
	if target_parent == null:
		return

	var existing_children:Array[Node] = source_mesh_instance.get_children()
	source_mesh_instance.create_multiple_convex_collisions(decomposition_settings)
	var generated_children:Array[Node] = source_mesh_instance.get_children()

	for child:Node in generated_children:
		if existing_children.has(child):
			continue
		if child is StaticBody3D:
			for static_body_child:Node in child.get_children():
				if static_body_child is CollisionShape3D:
					static_body_child.reparent(target_parent, true)
			child.queue_free()


func setExpanding(expanding_new:bool) -> void:
	expanding = expanding_new
	
	if expanding_new:
		shockwave_collider.disabled = false
	elif not expanding_new:
		shockwave_collider.disabled = true


## Returns how close size is to shockwave_config.ending_size in terms of 0 to 1.
## When size = shockwave_config.ending_size, 1 is returned.
## When size = shockwave_config.beginning_size, 0 is returned.
func getNormalizedSize() -> float:
	return remap(size, shockwave_config.beginning_size, shockwave_config.ending_size, 0.0, 1.0)


## Disables and queues free all of the hurtbox children of type [param target_type].
func queueFreeHurtboxChildren(target_type:Variant) -> void:
	var hurtbox_children:Array[Node] = shockwave_hurtbox.get_children()
	for child in hurtbox_children:
		if is_instance_of(child, target_type):
			child.queue_free()


## Returns an arraymesh constructed from [param source_mesh].
func buildArrayMeshFromImmidiate(source_mesh:ImmediateMesh) -> ArrayMesh:
	var array_mesh:ArrayMesh = ArrayMesh.new()
	if source_mesh == null:
		return array_mesh

	var surface_count:int = source_mesh.get_surface_count()
	for surface_idx:int in range(surface_count):
		var surface_arrays:Array = source_mesh.surface_get_arrays(surface_idx)
		if surface_arrays.is_empty():
			continue
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_arrays)

	return array_mesh


## Builds a trimesh concave shape3d from an arraymesh copy of the torus mesh and assigns it to
## ShockwaveCollider.
func buildTrimeshCollider() -> void:
	var new_array_mesh:ArrayMesh = buildArrayMeshFromImmidiate(half_torus.mesh)
	var dummy_mesh_instance:MeshInstance3D = MeshInstance3D.new()
	dummy_mesh_instance.mesh = new_array_mesh
	dummy_mesh_instance.create_trimesh_collision()
	var new_shape:ConcavePolygonShape3D = dummy_mesh_instance.get_child(0).get_child(0).shape
	shockwave_collider.shape = new_shape
	dummy_mesh_instance.free()


func setup() -> void:
	half_torus.fixed_height = shockwave_config.shockwave_height
	shader_driver.setShaderParameter(&"primary_color", shockwave_config.ring_color)
	size = shockwave_config.beginning_size
	_initial_size = size
	expanding = true


func _on_shockwave_hurtbox_body_entered(body: Node3D) -> void:
	if body is Player:
		body.applyForceImpulse(shockwave_config.force_applied, Vector3.UP)
		body.setHealth(body.health - shockwave_config.damage)
	elif body is Enemy:
		body.setHealth(body.health - shockwave_config.damage)
	elif body is PhysicalBone3D:
		body.linear_velocity.y = shockwave_config.force_applied
