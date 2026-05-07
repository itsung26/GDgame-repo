@tool
class_name Shockwave
extends Node3D

#region @onready vars
@onready var half_torus: HalfTorus = $HalfTorus
@onready var shader_driver: ShaderDriver = $ShaderDriver
@onready var shockwave_collider: CollisionShape3D = $ShockwaveHurtbox/ShockwaveCollider
@onready var shockwave_hurtbox: Area3D = $ShockwaveHurtbox
#endregion

#region @export vars
@export var shockwave_config:ShockwaveConfig
@export_tool_button("test activate") var a:Callable = setup
#endregion

#region regular vars
## Drives the size and alpha properties of the shockwave ring.
@export var size:float:
	set = setSize
@export var collision_segments:int = 12:
	set = setCollisionSegments
var expanding:bool = false:
	set = setExpanding
var _initial_size:float
#endregion


func _process(delta: float) -> void:
	if expanding:
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


func setCollisionSegments(segments_new:int) -> void:
	collision_segments = segments_new
	
	for i:int in range(segments_new):
		shockwave_hurtbox.add_child(CollisionShape3D.new())


## Disables and queues free all of the hurtbox children area3D nodes.
func queueFreeHurtboxChildren() -> void:
	var hurtbox_children:Array[Node] = shockwave_hurtbox.get_children()
	for child in hurtbox_children:
		if child is Area3D:
			child.disabled = true
			child.queue_free()


## Generates [param segments] concave colliders in the shape of the torus.
func generateConcaveColliders(segments:int) -> void:
	pass


func setup() -> void:
	shader_driver.setShaderParameter(&"primary_color", shockwave_config.ring_color)
	size = shockwave_config.beginning_size
	_initial_size = size
	expanding = true
