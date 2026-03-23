extends Node
## Autoload singleton for firing hitscan bullets.
##
## Provides a unified interface for firing raycast-based bullets with configurable
## damage, visuals, and reflection behavior. Reflections are resolved immediately
## during the same fire call.
##
## Usage:
## [codeblock]
## HitscanSystem.fire(bullet_config, muzzle.global_position, raycast)
## [/codeblock]


#region regular vars
## Internal deep raycast used for reflection checks.
var _reflection_raycast: DeepRayCast3D
## Queue of pending reflection requests, drained immediately in fire().
var _reflection_queue: Array[Dictionary] = []
#endregion


func _ready() -> void:
	# Create the reflection deep raycast node (single internal instance).
	_reflection_raycast = DeepRayCast3D.new()
	_reflection_raycast.enabled = true
	_reflection_raycast.auto_forward = true
	_reflection_raycast.raycast_visible = false
	_reflection_raycast.name = "ReflectionDeepRaycast"
	add_child(_reflection_raycast)


## Fires a hitscan bullet using a DeepRayCast3D and configuration.
## [param config]: The bullet configuration resource.
## [param origin]: World position where the bullet originates (muzzle).
## [param raycast]: A DeepRayCast3D used for hit detection.
## Returns the global position of the last point hit (or the ray end if nothing was hit).
func fire(
	config: HitscanBulletConfig,
	origin: Vector3,
	raycast: DeepRayCast3D
) -> Vector3:
	var hit_point: Vector3 = origin
	var hit_normal: Vector3 = Vector3.ZERO
	var last_segment_start: Vector3 = origin
	var hit_count := raycast.get_collider_count()
	var start_pos: Vector3 = raycast.global_transform.origin
	
	# If nothing was hit, approximate the endpoint using DeepRayCast3D's forward settings.
	if hit_count == 0:
		var dir: Vector3
		var dist: float
		if raycast.auto_forward:
			dir = -raycast.global_transform.basis.z
			dist = raycast.forward_distance
		elif raycast.target:
			dir = start_pos.direction_to(raycast.target.global_position + raycast.target_offset_position)
			dist = start_pos.distance_to(raycast.target.global_position + raycast.target_offset_position)
		else:
			dir = -raycast.global_transform.basis.z
			dist = raycast.forward_distance
		
		hit_point = start_pos + dir.normalized() * dist
		_spawn_trail(config, origin, hit_point)
		# No reflections possible if nothing was initially hit.
		Debug.log("HitscanSystem: shot completed with 0 reflections")
		return hit_point
	
	var should_queue_reflection := config.can_reflect and config.max_reflections > 0
	var reflection_queued := false
	
	# Walk through deep hits in order.
	for i in range(hit_count):
		var body := raycast.get_collider(i)
		if not (body is Node3D):
			continue
		var hit_body: Node3D = body
		hit_point = raycast.get_hit_position(i)
		hit_normal = raycast.get_normal(i)
		
		# Damage behavior.
		if config.can_pierce_enemies:
			# Piercing: always apply hit logic, even for multiple enemies.
			# Treat reflective enemies as "normal" for damage/visuals here so
			# they can be damaged by piercing shots and don't spawn
			# reflection-only impact effects.
			_handle_hit(config, hit_body, hit_point, hit_normal, 1.0, true)
		else:
			# Non-piercing: apply hit, but stop after hitting a non-reflective enemy.
			_handle_hit(config, hit_body, hit_point, hit_normal, 1.0)
			
			if hit_body is Enemy and not (hit_body as Enemy).reflective:
				# Stop the original ray when hitting a normal enemy.
				break
		
		# Reflection behavior:
		# - Non-piercing: can reflect from reflective enemies and reflective world bodies.
		# - Piercing: can reflect only from reflective world bodies (not from enemies, and not from PhysicalBone3D).
		if should_queue_reflection and not reflection_queued:
			var is_enemy := hit_body is Enemy
			var is_reflective_enemy := is_enemy and (hit_body as Enemy).reflective
			var is_pistol_receiver := hit_body is PistolBombShotCollsionReciever
			var is_physical_bone := hit_body is PhysicalBone3D
			var is_reflective_worldbody: bool = hit_body is WorldBody and (hit_body.reflective == true)
			# Reflective world bodies: non-enemy, not pistol receiver, not PhysicalBone3D, reflective flag on.
			var can_reflect_from_other := not is_enemy and not is_pistol_receiver and not is_physical_bone and is_reflective_worldbody
			
			var can_reflect_here := false
			if config.can_pierce_enemies:
				# Piercing ray: only reflect off reflective world bodies.
				can_reflect_here = can_reflect_from_other
			else:
				# Non-piercing ray: reflect off reflective enemies or reflective world bodies.
				can_reflect_here = is_reflective_enemy or can_reflect_from_other
			
			if can_reflect_here:
				# Compute direction from the previous segment start to this hit.
				var direction: Vector3 = (hit_point - last_segment_start).normalized()
				# Queue the first reflection. Since this is the initial bounce,
				# start reflection_count at 1 so logging includes this first reflection.
				_queue_reflection({
					"config": config,
					"origin": hit_point,
					"incoming_direction": direction,
					"surface_normal": hit_normal,
					"collision_mask": raycast.collision_mask,
					"collide_with_areas": raycast.collide_with_areas,
					"collide_with_bodies": raycast.collide_with_bodies,
					"hit_from_inside": raycast.hit_from_inside,
					"hit_back_faces": raycast.hit_back_faces,
					"reflections_left": config.max_reflections,
					"damage_multiplier": 1.0,
					"hits": [],
					"reflection_count": 1,
				})
				reflection_queued = true
				
				# Once we reflect, we don't continue the original ray further.
				break
		
		# Next segment for deep ray starts from this hit.
		last_segment_start = hit_point
	
	# Spawn trail from origin to the last point we reached.
	_spawn_trail(config, origin, hit_point)
	
	
	# Resolve reflections in the same frame (single-threaded physics).
	_drain_reflection_queue()
	return hit_point


## Fires a hitscan bullet in a manually-defined direction using the collision layers
## and settings of the [param raycast] [DeepRayCast3D]. Returns the intial point
## of contact of the hitscan and is capable of reflection, just [code]fire()[/code].
func fireManual(
	config: HitscanBulletConfig,
	origin: Vector3,
	raycast: DeepRayCast3D,
	direction: Vector3
) -> Vector3:
	return Vector3.ZERO


## Queues a reflection request for immediate drain.
func _queue_reflection(request: Dictionary) -> void:
	_reflection_queue.append(request)


## Processes all queued reflections immediately.
func _drain_reflection_queue() -> void:
	while not _reflection_queue.is_empty():
		var request: Dictionary = _reflection_queue.pop_front()
		_process_reflection(request)


## Processes a single reflection request.
func _process_reflection(request: Dictionary) -> void:
	var scene_root: Node = get_tree().current_scene
	var config: HitscanBulletConfig = request.config
	var origin: Vector3 = request.origin
	var incoming_direction: Vector3 = request.incoming_direction
	var surface_normal: Vector3 = request.surface_normal
	var reflections_left: int = request.reflections_left
	var damage_multiplier: float = request.damage_multiplier
	var hits: Array = request.get("hits", [])
	var reflection_count: int = int(request.get("reflection_count", 0))
	
	if reflections_left <= 0:
		return
	
	# Ensure scene_root is still valid.
	if not is_instance_valid(scene_root):
		return
	
	# Calculate reflected direction.
	var reflected_dir: Vector3 = incoming_direction.bounce(surface_normal).normalized()
	
	# Offset origin slightly to avoid self-intersection.
	var ray_origin: Vector3 = origin + (surface_normal * 0.05)
	
	# Configure the internal reflection DeepRayCast3D to cast along the reflected direction.
	if not is_instance_valid(_reflection_raycast):
		return
	_reflection_raycast.global_transform = Transform3D(
		Basis().looking_at(reflected_dir, Vector3.UP),
		ray_origin
	)
	_reflection_raycast.forward_distance = 1000.0
	_reflection_raycast.collision_mask = request.collision_mask
	_reflection_raycast.collide_with_areas = false
	_reflection_raycast.collide_with_bodies = request.collide_with_bodies
	_reflection_raycast.hit_from_inside = request.hit_from_inside
	_reflection_raycast.hit_back_faces = request.hit_back_faces
	_reflection_raycast.enabled = true
	_reflection_raycast._update_raycast()
	
	# Get collision data (first hit along the reflected deep ray).
	var hit_point: Vector3
	var hit_normal: Vector3 = Vector3.UP
	var hit_body: Node3D = null
	var hit_count := _reflection_raycast.get_collider_count()
	if hit_count > 0:
		var body := _reflection_raycast.get_collider(0)
		if body is Node3D:
			hit_body = body
			hit_point = _reflection_raycast.get_hit_position(0)
			hit_normal = _reflection_raycast.get_normal(0)
			hits.append(hit_body)
	if hit_body == null:
		hit_point = _reflection_raycast.global_transform.origin + reflected_dir * 1000.0
	
	# Spawn trail for reflected bullet.
	_spawn_trail(config, ray_origin, hit_point)
	
	# If nothing was hit, we're done.
	if not hit_body:
		#Debug.log("HitscanSystem: shot completed with %d reflections" % reflection_count)
		return
	
	# Handle the hit with reduced damage. Reflections should respect the
	# reflective flag, so we don't ignore it here.
	_handle_hit(config, hit_body, hit_point, hit_normal, damage_multiplier, false)
	
	# Queue another reflection if surface is reflective (world body with reflective flag or reflective enemy).
	var can_reflect_from_enemy: bool = false
	if hit_body is Enemy:
		can_reflect_from_enemy = (hit_body as Enemy).reflective
	# Reflect from reflective world bodies (non-enemy, reflective flag), but NOT from the pistol bomb collision receiver.
	var can_reflect_from_other: bool = hit_body is WorldBody and (hit_body.reflective == true) and not (hit_body is Enemy) and not (hit_body is PistolBombShotCollsionReciever)
	
	if reflections_left > 1 and (can_reflect_from_enemy or can_reflect_from_other):
		reflection_count += 1
		var next_dir: Vector3 = reflected_dir
		var next_origin: Vector3 = hit_point
		var next_normal: Vector3 = hit_normal
		
		_queue_reflection({
			"config": config,
			"origin": next_origin,
			"incoming_direction": next_dir,
			"surface_normal": next_normal,
			"collision_mask": request.collision_mask,
			"collide_with_areas": request.collide_with_areas,
			"collide_with_bodies": request.collide_with_bodies,
			"hit_from_inside": request.hit_from_inside,
			"hit_back_faces": request.hit_back_faces,
			"reflections_left": reflections_left - 1,
			"damage_multiplier": damage_multiplier * config.reflection_damage_falloff if config.use_damage_falloff else 1.0,
			"hits": hits,
			"reflection_count": reflection_count,
		})
	else:
		# No further reflections; report total reflections for this shot.
		#Debug.log("HitscanSystem: shot completed with %d reflections" % reflection_count)
		pass


## Spawns the bullet trail effect.
func _spawn_trail(
	config: HitscanBulletConfig,
	origin: Vector3,
	target: Vector3
) -> void:
	if not config.trail_scene:
		return
	
	var trail: Node = config.trail_scene.instantiate()
	var scene_root: Node = get_tree().current_scene
	scene_root.add_child(trail)
	trail.setup(origin, target, config.trail_color)


## Spawns impact particles at the hit location.
func _spawn_impact_particles(
	config: HitscanBulletConfig,
	hit_point: Vector3,
	hit_normal: Vector3
) -> void:
	if not config.impact_particle_scene:
		return
	
	var particles: Node = config.impact_particle_scene.instantiate()
	var scene_root: Node = get_tree().current_scene
	scene_root.add_child(particles)
	particles.setup(hit_point, hit_normal)


## Spawns impact light at the hit location (optional).
func _spawn_impact_light(
	config: HitscanBulletConfig,
	hit_point: Vector3,
	hit_normal: Vector3
) -> void:
	if not config.impact_light_scene:
		return
	
	var light: Node3D = config.impact_light_scene.instantiate()
	var scene_root: Node = get_tree().current_scene
	scene_root.add_child(light)
	light.global_position = hit_point + (hit_normal * 0.01)


## Handles what happens when a bullet hits something.
func _handle_hit(
	config: HitscanBulletConfig,
	hit_body: Node3D,
	hit_point: Vector3,
	hit_normal: Vector3,
	damage_multiplier: float,
	ignore_reflective_flag: bool = false
) -> void:
	if hit_body is Enemy:
		var enemy := hit_body as Enemy
		# If the enemy is reflective and we're NOT in a context that wants to
		# ignore that (e.g. non-piercing reflections), treat it like a
		# reflective surface only: no damage, just visuals.
		if enemy.reflective and not ignore_reflective_flag:
			_spawn_impact_particles(config, hit_point, hit_normal)
			_spawn_impact_light(config, hit_point, hit_normal)
			return
		
		# Otherwise, deal normal damage (piercing or non-piercing).
		var damage: float = config.get_random_damage() * damage_multiplier
		enemy.damageEnemy(damage, config.damage_type)
		return
	
	if hit_body is Player:
		var damage: float = config.get_random_damage() * damage_multiplier
		hit_body.damagePlayer(damage, "Hitscan")
		return
	
	elif hit_body is PistolBombShotCollsionReciever:
		var bomb: PistolBomb = hit_body.getPistolBomb()
		_handle_pistol_bomb_hit(bomb)
	
	elif hit_body is PhysicalBone3D:
		return
		
	else:
		# World geometry hit - spawn impact effects.
		_spawn_impact_particles(config, hit_point, hit_normal)
		_spawn_impact_light(config, hit_point, hit_normal)


## Handles the special case of hitting a PistolBomb.
func _handle_pistol_bomb_hit(bomb: PistolBomb) -> void:
	var scene_root: Node = get_tree().current_scene
	var player: Player = scene_root.get_tree().get_first_node_in_group("players")
	if player:
		player.hitStop(bomb.hitstop_duration_on_being_shot)
		
		# Show parry visuals.
		var parry_visuals: Array[Node] = scene_root.get_tree().get_nodes_in_group("parry visuals")
		for parry_visual in parry_visuals:
			if parry_visual.name != "ParryFlash":
				parry_visual.visible = true
	
	bomb.explode()
