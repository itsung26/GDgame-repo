@tool
@icon("res://physical_particle_emitter_icon.png")
class_name PhysicalParticleEmitter
extends Node3D
## This object acts as a cpu-based particle emitter, except it uses rigidbodies for
## accurate physics simulation. This particle system is unique from the others in how
## its particles are capabale of running logic. Drawbacks of this are a heavy impact
## on performance and lack of editor preview, so for simple visuals, use the built in particle systems.
## Note: this object expects a scene with a [PhysicalParticle] as the root node.

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
## Same as [GPUParticles3D.explosiveness]: 0 = spread emissions over the cycle; 1 = emit all [param particle_amount] particles at once each cycle.
@export_range(0.0, 1.0, 0.01) var explosiveness:float = 0.0

@export_group("Velocity")
## Base emission direction. Same as [ParticleProcessMaterial.direction] (normalized when applied).
@export var direction:Vector3 = Vector3(1.0, 0.0, 0.0)
## Same as [ParticleProcessMaterial.spread]: each axis of random deviation uses up to this many degrees (0–180).
@export_range(0.0, 180.0, 0.001) var spread:float = 0.0
## Same as [ParticleProcessMaterial.flatness]: 0 = full 3D cone; 1 = emission flattened on a plane.
@export_range(0.0, 1.0, 0.001) var flatness:float = 0.0
## Same as [ParticleProcessMaterial.initial_velocity_min].
@export var initial_velocity_min:float = 0.0
## Same as [ParticleProcessMaterial.initial_velocity_max].
@export var initial_velocity_max:float = 0.0

@export_group("Particle Physical Simulation")
@export var gravity_scale:float = 1.0
@export var mass:float = 1.0

@export_group("Particle Collision")
@export var hide_on_collision:bool = false
@export_flags_3d_physics var collision_layer: int
@export_flags_3d_physics var collision_mask: int


## Fractional particle spawns carried across frames (same idea as Godot's internal emission accumulator).
var _emission_accumulator:float = 0.0
var _one_shot_remaining:int = 0
var _emitting_was:bool = false
## Time elapsed in the current emission cycle (0 .. [member particle_lifetime]), matching GPUParticles3D timing.
var _cycle_elapsed:float = 0.0
var _editor_sprite_texture:Texture2D = preload("res://physical_particle_emitter_icon.png") as Texture2D


func _ready() -> void:
	if Engine.is_editor_hint():
		# spawn a sprite that shows where it is
		var _editor_sprite:Sprite3D = Sprite3D.new()
		add_child(_editor_sprite)
		_editor_sprite.texture = _editor_sprite_texture
		_editor_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_editor_sprite.pixel_size = 0.0043
	else:
		#if particle_SCENE:
		#	allocatePoolInstances(particle_SCENE, pool_allocations)
		_emitting_was = emitting
		if emitting:
			_emission_accumulator = 0.0
			_cycle_elapsed = 0.0
			if one_shot:
				_one_shot_remaining = particle_amount



func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if emitting != _emitting_was:
		if emitting:
			_emission_accumulator = 0.0
			_cycle_elapsed = 0.0
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
	_stepEmission(delta)



func _stepEmission(delta: float) -> void:
	var e:float = clampf(explosiveness, 0.0, 1.0)
	# GPUParticles3D: emission_time = lifetime * (1 - explosiveness); 0 => instant burst.
	var emission_duration:float = particle_lifetime * (1.0 - e)
	if emission_duration <= 0.0001:
		if _cycle_elapsed == 0.0:
			_emitParticleBurst()
			if not emitting:
				return
		_cycle_elapsed += delta
		while _cycle_elapsed >= particle_lifetime:
			_cycle_elapsed -= particle_lifetime
			if one_shot:
				return
			_emitParticleBurst()
			if not emitting:
				return
		return
	var rate:float = float(particle_amount) / emission_duration
	var remaining_dt:float = delta
	var t:float = _cycle_elapsed
	while remaining_dt > 0.000001:
		while t >= particle_lifetime - 0.000001:
			t -= particle_lifetime
		var seg:float = min(remaining_dt, maxf(0.0, particle_lifetime - t))
		if seg <= 0.000001:
			break
		if t < emission_duration:
			var emit_end:float = min(t + seg, emission_duration)
			var emit_dt:float = max(0.0, emit_end - t)
			_emission_accumulator += emit_dt * rate
		t += seg
		remaining_dt -= seg
	_cycle_elapsed = t
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



func _emitParticleBurst() -> void:
	var count:int = particle_amount
	if one_shot:
		count = _one_shot_remaining
	for i in range(count):
		_emitSingleParticle(particle_lifetime)
		if one_shot:
			_one_shot_remaining -= 1
			if _one_shot_remaining <= 0:
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
	particle.global_position = global_position
	particle.global_rotation = global_rotation
	particle.reset_physics_interpolation()
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
	particle.hiding_on_collide = hide_on_collision
	particle.top_level = true
	particle.freeze = false
	particle.collision_layer = collision_layer
	particle.collision_mask = collision_mask
	particle.gravity_scale = gravity_scale
	particle.mass = mass
	var vmin:float = initial_velocity_min
	var vmax:float = initial_velocity_max
	if vmin > vmax:
		var t:float = vmin
		vmin = vmax
		vmax = t
	var speed:float = lerpf(vmin, vmax, randf())
	var dir_local:Vector3 = _getRandomDirectionFromSpread3D(direction, spread, flatness)
	var emission_local:Vector3 = dir_local * speed
	var emission_world:Vector3 = global_transform.basis * emission_local
	particle.linear_velocity = emission_world
	particle.angular_velocity = Vector3.ZERO



## Port of get_random_direction_from_spread from Godot's ParticleProcessMaterial (3D path).
func _getRandomDirectionFromSpread3D(direction_raw:Vector3, spread_angle_deg:float, flatness_param:float) -> Vector3:
	var direction_nrm:Vector3
	if direction_raw.length_squared() < 0.000001:
		direction_nrm = Vector3(0.0, 0.0, 1.0)
	else:
		direction_nrm = direction_raw.normalized()
	var spread_rad:float = deg_to_rad(spread_angle_deg)
	var angle1_rad:float = randf_range(-1.0, 1.0) * spread_rad
	var angle2_rad:float = randf_range(-1.0, 1.0) * spread_rad * (1.0 - flatness_param)
	var direction_xz:Vector3 = Vector3(sin(angle1_rad), 0.0, cos(angle1_rad))
	var direction_yz:Vector3 = Vector3(0.0, sin(angle2_rad), cos(angle2_rad))
	direction_yz.z = direction_yz.z / maxf(0.0001, sqrt(abs(direction_yz.z)))
	var spread_direction:Vector3 = Vector3(
		direction_xz.x * direction_yz.z,
		direction_yz.y,
		direction_xz.z * direction_yz.z
	)
	var binormal:Vector3 = Vector3.UP.cross(direction_nrm)
	if binormal.length_squared() < 0.000001:
		binormal = Vector3(0.0, 0.0, 1.0)
	binormal = binormal.normalized()
	var normal:Vector3 = binormal.cross(direction_nrm).normalized()
	spread_direction = binormal * spread_direction.x + normal * spread_direction.y + direction_nrm * spread_direction.z
	return spread_direction.normalized()
