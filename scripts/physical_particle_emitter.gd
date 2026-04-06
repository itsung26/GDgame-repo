@tool
class_name PhysicalParticleEmitter
extends Node3D
## This object acts as a cpu-based particle emitter, except it uses rigidbodies.
## Note that this object expects a scene with a [PhysicalParticle] as the root node.
# ## The scenes are instanced into a pool with a finite number of allocations.

@export_category("Particle Instancing")
## The scene that is instanced. Note that the scene selected MUST have a [PhysicalParticle] as the root node.
@export var particle_SCENE:PackedScene
## Determines the amount of instances allocated to pool memory. This number must be greater than 0, and should not be too high for complex particle scenes.
## (Unused while pooling is commented out.)
#@export var pool_allocations:int = 1

@export_group("Particle Process Behavior")
@export var particle_lifetime:float = 1.0
@export var particle_amount:int = 5
@export var one_shot:bool = false
@export var emitting:bool = false

@export_group("Velocity")
## The direction of emission. Expects a normalized vector
@export var direction:Vector3 = Vector3(1.0, 0.0, 0.0)
@export var spread:float = 0.0
@export var velocity:float = 0.0

@export_group("Particle Physical Simulation")
@export var gravity_scale:float = 1.0
@export var mass:float = 1.0

@export_group("Particle Collision")
@export_flags_3d_physics var collision_layer: int
@export_flags_3d_physics var collision_mask: int

#var _particle_pool:Array[PhysicalParticle]
#var active_particles:Array[PhysicalParticle]
## Fractional particle spawns carried across frames (same idea as Godot's internal emission accumulator).
var _emission_accumulator:float = 0.0
var _one_shot_remaining:int = 0
var _emitting_was:bool = false


func _ready() -> void:
	PhysicsServer3D.set_active(true)
	#if particle_SCENE:
	#	allocatePoolInstances(particle_SCENE, pool_allocations)
	_emitting_was = emitting
	if emitting:
		_emission_accumulator = 0.0
		if one_shot:
			_one_shot_remaining = particle_amount



func _process(delta: float) -> void:
	if emitting != _emitting_was:
		if emitting:
			_emission_accumulator = 0.0
			if one_shot:
				_one_shot_remaining = particle_amount
		else:
			_emission_accumulator = 0.0
		_emitting_was = emitting
	if not emitting:
		return
	if particle_lifetime <= 0.0 or particle_amount <= 0:
		if one_shot:
			emitting = false
		return
	# Matches GPUParticles3D: effective rate = amount / lifetime (particles per second).
	var emission_rate:float = float(particle_amount) / particle_lifetime
	_emission_accumulator += delta * emission_rate
	while _emission_accumulator >= 1.0:
		if one_shot and _one_shot_remaining <= 0:
			_emission_accumulator = 0.0
			emitting = false
			return
		_emitSingleParticle(particle_lifetime)
		_emission_accumulator -= 1.0
		if one_shot:
			_one_shot_remaining -= 1
			if _one_shot_remaining <= 0:
				_emission_accumulator = 0.0
				emitting = false
				return



#func allocatePoolInstances(scene:PackedScene, amount:int) -> void:
#	for i in range(amount):
#		_particle_pool.append(scene.instantiate())


#func requestParticleFromPool() -> PhysicalParticle:
#	if _particle_pool.is_empty():
#		Debug.logerr("PhysicalParticleEmitter: particle pool is exhausted.")
#		return null
#	var particle:PhysicalParticle = _particle_pool.pop_front()
#	active_particles.append(particle)
#	add_child(particle)
#	particle._setup()
#	return particle


#func returnParticleToPool(particle:PhysicalParticle) -> void:
#	if not active_particles.has(particle):
#		Debug.logerr("PhysicalParticleEmitter: returnParticleToPool called with a particle that is not active.")
#		return
#	if particle.get_parent() == self:
#		remove_child(particle)
#	active_particles.erase(particle)
#	_particle_pool.append(particle)


func _emitSingleParticle(p_lifetime:float) -> void:
	#var particle:PhysicalParticle = requestParticleFromPool()
	#if particle == null:
	#	return
	if particle_SCENE == null:
		return
	var particle:PhysicalParticle = particle_SCENE.instantiate() as PhysicalParticle
	add_child(particle)
	_configureParticle(particle)
	var particle_life_time_timer:Timer = Timer.new()
	particle.add_child(particle_life_time_timer)
	particle_life_time_timer.one_shot = true
	particle_life_time_timer.start(p_lifetime)
	particle_life_time_timer.connect(
		&"timeout",
		func() -> void:
			particle_life_time_timer.queue_free()
			if particle.get_parent() == self:
				remove_child(particle)
			particle.queue_free()
	)


func _configureParticle(particle:PhysicalParticle) -> void:
	particle.top_level = true
	particle.freeze = false
	particle.collision_layer = collision_layer
	particle.collision_mask = collision_mask
	particle.gravity_scale = gravity_scale
	particle.mass = mass
