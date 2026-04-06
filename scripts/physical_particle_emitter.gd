@tool
class_name PhysicalParticleEmitter
extends Node3D
## This object acts as a cpu-based particle emitter, except it uses rigidbodies.
## Note that this object expects a scene with a [PhysicalParticle] as the root node.
## The scenes are instanced into a pool with a finite number of allocations.

@export_category("Particle Instancing")
## The scene that is instanced. Note that the scene selected MUST have a [PhysicalParticle] as the root node.
@export var particle_SCENE:PackedScene
## Determines the amount of instances allocated to pool memory. This number must be greater than 0, and should not be too high for complex particle scenes.
@export var pool_allocations:int = 1

@export_group("Particle Process Behavior")
@export var particle_lifetime:float = 1.0
@export var particle_amount:int = 5
@export var one_shot:bool = false
@export var emitting:bool = false

@export_group("Velocity")
## The direction of emission. Expects a normalized vector
@export var direction:Vector3 = Vector3(1.0, 0.0, 0.0)
@export var velocity:float = 0.0

var _particle_pool:Array[PhysicalParticle]
var active_particles:Array[PhysicalParticle]


func _ready() -> void:
	if particle_SCENE:
		_allocatePoolInstances(particle_SCENE, pool_allocations)


func _process(delta: float) -> void:
	if emitting:
		pass # emit here


func _allocatePoolInstances(scene:PackedScene, amount:int) -> void:
	for i in range(amount):
		_particle_pool.append(scene.instantiate())


func _emitSingleParticle(particle_lifetime:float) -> void:
	assert(not _particle_pool.is_empty())
	var particle:PhysicalParticle = _particle_pool.pop_front()
	var particle_life_time_timer:Timer = Timer.new()
	
	active_particles.append(particle)
	
	# add the particle and it's timer to the scene
	add_child(particle)
	particle.add_child(particle_life_time_timer)
	
	# configure and start the particle's lifetime timer
	particle_life_time_timer.one_shot = true
	particle_life_time_timer.start(particle_lifetime)
	particle_life_time_timer.connect(&"timeout", func() -> void: particle.get_parent().remove_child(particle))
