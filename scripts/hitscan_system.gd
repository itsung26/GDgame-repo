extends Node
## Autoload singleton for firing hitscan bullets.
##
## Provides a unified interface for firing raycast-based bullets with configurable
## damage, visuals, and reflection behavior. Reflections are queued and processed
## in _physics_process() to work with multithreaded physics.
##
## Usage:
## [codeblock]
## HitscanSystem.fire(bullet_config, muzzle.global_position, raycast, get_tree().current_scene)
## [/codeblock]

## Internal raycast used for reflection checks, processed in _physics_process.
var _reflection_raycast: RayCast3D

## Queue of pending reflection requests to process in _physics_process.
var _reflection_queue: Array[Dictionary] = []


func _ready() -> void:
	# Create the reflection raycast node.
	_reflection_raycast = RayCast3D.new()
	_reflection_raycast.enabled = false  # We manually control updates
	_reflection_raycast.name = "ReflectionRaycast"
	add_child(_reflection_raycast)


func _physics_process(_delta: float) -> void:
	# Process all queued reflections.
	while not _reflection_queue.is_empty():
		var request: Dictionary = _reflection_queue.pop_front()
		_process_reflection(request)


## Fires a hitscan bullet using the provided raycast and configuration.
## [param config]: The bullet configuration resource.
## [param origin]: World position where the bullet originates (muzzle).
## [param raycast]: The RayCast3D used for hit detection (must be force_raycast_update'd or active).
## [param scene_root]: The node to add visual effects to (usually current_scene).
func fire(
	config: HitscanBulletConfig,
	origin: Vector3,
	raycast: RayCast3D,
	scene_root: Node
) -> void:
	var hit_body: Node3D = raycast.get_collider()
	var hit_point: Vector3 = raycast.get_collision_point()
	var hit_normal: Vector3 = raycast.get_collision_normal()
	
	# If nothing was hit, use the raycast's target position as the endpoint.
	if not hit_body:
		hit_point = raycast.to_global(raycast.target_position)
	
	# Spawn bullet trail.
	_spawn_trail(config, origin, hit_point, scene_root)
	
	# If nothing was hit, we're done.
	if not hit_body:
		return
	
	# Handle the hit (damage, effects, etc.).
	_handle_hit(config, hit_body, hit_point, hit_normal, scene_root, 1.0)
	
	# Queue reflection if enabled and we hit a non-enemy surface.
	if config.can_reflect and config.max_reflections > 0 and not (hit_body is Enemy):
		var direction: Vector3 = (hit_point - origin).normalized()
		_queue_reflection({
			"config": config,
			"origin": hit_point,
			"incoming_direction": direction,
			"surface_normal": hit_normal,
			"scene_root": scene_root,
			"collision_mask": raycast.collision_mask,
			"collide_with_areas": raycast.collide_with_areas,
			"collide_with_bodies": raycast.collide_with_bodies,
			"hit_from_inside": raycast.hit_from_inside,
			"hit_back_faces": raycast.hit_back_faces,
			"reflections_left": config.max_reflections,
			"damage_multiplier": config.reflection_damage_falloff
		})


## Queues a reflection request to be processed in _physics_process.
func _queue_reflection(request: Dictionary) -> void:
	_reflection_queue.append(request)


## Processes a single reflection request (called from _physics_process).
func _process_reflection(request: Dictionary) -> void:
	var config: HitscanBulletConfig = request.config
	var origin: Vector3 = request.origin
	var incoming_direction: Vector3 = request.incoming_direction
	var surface_normal: Vector3 = request.surface_normal
	var scene_root: Node = request.scene_root
	var reflections_left: int = request.reflections_left
	var damage_multiplier: float = request.damage_multiplier
	
	if reflections_left <= 0:
		return
	
	# Ensure scene_root is still valid.
	if not is_instance_valid(scene_root):
		return
	
	# Calculate reflected direction.
	var reflected_dir: Vector3 = incoming_direction.bounce(surface_normal).normalized()
	
	# Offset origin slightly to avoid self-intersection.
	var ray_origin: Vector3 = origin + (surface_normal * 0.05)
	
	# Configure the reflection raycast.
	_reflection_raycast.global_position = ray_origin
	_reflection_raycast.target_position = reflected_dir * 1000.0
	_reflection_raycast.collision_mask = request.collision_mask
	_reflection_raycast.collide_with_areas = request.collide_with_areas
	_reflection_raycast.collide_with_bodies = request.collide_with_bodies
	_reflection_raycast.hit_from_inside = request.hit_from_inside
	_reflection_raycast.hit_back_faces = request.hit_back_faces
	_reflection_raycast.enabled = true
	_reflection_raycast.force_raycast_update()
	_reflection_raycast.enabled = false
	
	# Get collision data.
	var hit_body: Node3D = _reflection_raycast.get_collider()
	var hit_point: Vector3
	var hit_normal: Vector3 = Vector3.UP
	
	if hit_body:
		hit_point = _reflection_raycast.get_collision_point()
		hit_normal = _reflection_raycast.get_collision_normal()
	else:
		hit_point = _reflection_raycast.to_global(_reflection_raycast.target_position)
	
	# Spawn trail for reflected bullet.
	_spawn_trail(config, ray_origin, hit_point, scene_root)
	
	# If nothing was hit, we're done.
	if not hit_body:
		return
	
	# Handle the hit with reduced damage.
	_handle_hit(config, hit_body, hit_point, hit_normal, scene_root, damage_multiplier)
	
	# Queue another reflection if we hit a non-enemy surface.
	if not (hit_body is Enemy) and reflections_left > 1:
		_queue_reflection({
			"config": config,
			"origin": hit_point,
			"incoming_direction": reflected_dir,
			"surface_normal": hit_normal,
			"scene_root": scene_root,
			"collision_mask": request.collision_mask,
			"collide_with_areas": request.collide_with_areas,
			"collide_with_bodies": request.collide_with_bodies,
			"hit_from_inside": request.hit_from_inside,
			"hit_back_faces": request.hit_back_faces,
			"reflections_left": reflections_left - 1,
			"damage_multiplier": damage_multiplier * config.reflection_damage_falloff
		})


## Spawns the bullet trail effect.
func _spawn_trail(
	config: HitscanBulletConfig,
	origin: Vector3,
	target: Vector3,
	scene_root: Node
) -> void:
	if not config.trail_scene:
		return
	
	var trail: Node = config.trail_scene.instantiate()
	scene_root.add_child(trail)
	trail.setup(origin, target, config.trail_color)


## Spawns impact particles at the hit location.
func _spawn_impact_particles(
	config: HitscanBulletConfig,
	hit_point: Vector3,
	hit_normal: Vector3,
	scene_root: Node
) -> void:
	if not config.impact_particle_scene:
		return
	
	var particles: Node = config.impact_particle_scene.instantiate()
	scene_root.add_child(particles)
	particles.setup(hit_point, hit_normal)


## Spawns impact light at the hit location (optional).
func _spawn_impact_light(
	config: HitscanBulletConfig,
	hit_point: Vector3,
	hit_normal: Vector3,
	scene_root: Node
) -> void:
	if not config.impact_light_scene:
		return
	
	var light: Node3D = config.impact_light_scene.instantiate()
	scene_root.add_child(light)
	light.global_position = hit_point + (hit_normal * 0.01)


## Handles what happens when a bullet hits something.
func _handle_hit(
	config: HitscanBulletConfig,
	hit_body: Node3D,
	hit_point: Vector3,
	hit_normal: Vector3,
	scene_root: Node,
	damage_multiplier: float
) -> void:
	if hit_body is Enemy:
		var damage: float = config.get_random_damage() * damage_multiplier
		hit_body.damageEnemy(damage, config.damage_type)
	
	elif hit_body is PistolBomb:
		_handle_pistol_bomb_hit(hit_body, scene_root)
	
	elif hit_body is PistolBombShotCollsionReciever:
		var bomb: PistolBomb = hit_body.getPistolBomb()
		_handle_pistol_bomb_hit(bomb, scene_root)
	
	else:
		# World geometry hit - spawn impact effects.
		_spawn_impact_particles(config, hit_point, hit_normal, scene_root)
		_spawn_impact_light(config, hit_point, hit_normal, scene_root)


## Handles the special case of hitting a PistolBomb.
func _handle_pistol_bomb_hit(bomb: PistolBomb, scene_root: Node) -> void:
	var player: Player = scene_root.get_tree().get_first_node_in_group("players")
	if player:
		player.hitStop(bomb.hitstop_duration_on_being_shot)
		
		# Show parry visuals.
		var parry_visuals: Array[Node] = scene_root.get_tree().get_nodes_in_group("parry visuals")
		for parry_visual in parry_visuals:
			if parry_visual.name != "ParryFlash":
				parry_visual.visible = true
	
	bomb.explode()
