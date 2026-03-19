class_name LineOfSightQuery
extends RayCast3D
## Performs a physics-based line-of-sight check using a `RayCast3D`.
##
## This node works by temporarily positioning the ray at `from` and setting
## `target_position` toward `to`. It then raycasts and reports whether any
## enabled collision layers block the ray.
##
## Note: `test()` resets the collision mask on every call so results don't
## depend on previous queries.

const LAYER_PLAYERS: int = 1
const LAYER_ENEMIES: int = 2
const LAYER_WORLD: int = 3


func _clear_collision_masks() -> void:
	# Godot collision masks can use up to 32 layer indices (0..31).
	# Clear everything so each `test()` call starts from a known state.
	for i in range(1, 32):
		set_collision_mask_value(i, false)


func _ready() -> void:
	target_position = Vector3(0.0, 0.0, 0.0)
	debug_shape_custom_color = Color.YELLOW
	_clear_collision_masks()


## Performs a line-of-sight query from [param from] to [param to] (global/world
## coordinates).
##
## If [param stop_on_players], [param stop_on_enemies], or [param stop_on_world]
## is `true`, the corresponding collision layer will be enabled in the ray's
## collision mask. If the ray collides with anything on any enabled layer,
## this function returns `false`.
##
## Returns `true` only when there is a clear path along the ray for the
## enabled layers.
func test(
	from: Vector3,
	to: Vector3,
	stop_on_players: bool,
	stop_on_enemies: bool,
	stop_on_world: bool
) -> bool:
	# First, set the coordinates for this query.
	global_position = from
	target_position = to_local(to)

	# Clear and then enable only what this query wants.
	_clear_collision_masks()
	if stop_on_players:
		set_collision_mask_value(LAYER_PLAYERS, true)
	if stop_on_enemies:
		set_collision_mask_value(LAYER_ENEMIES, true)
	if stop_on_world:
		set_collision_mask_value(LAYER_WORLD, true)

	# Now run the actual physics query.
	force_raycast_update()
	return not is_colliding()
