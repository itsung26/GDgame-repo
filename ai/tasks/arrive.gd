@tool
extends BTAction

@export var target_position_var:StringName = &"target_pos"
@export var nav_agent:BBNode
## How close the agent needs to be to the target to return SUCCESS
@export var tolerance: float = 1.0

func _generate_name() -> String:
	return "Arrive pos: %s" % LimboUtility.decorate_var(target_position_var)

func _tick(delta: float) -> Status:
	var target_pos: Vector3 = blackboard.get_var(target_position_var, Vector3.ZERO)
	
	# Check if we're close enough to the target (using XZ distance only)
	var current_pos: Vector3 = agent.global_position
	var distance_xz: float = Vector2(target_pos.x, target_pos.z).distance_to(Vector2(current_pos.x, current_pos.z))
	if distance_xz < tolerance:
		# stop enemy from moving
		agent.velocity = Vector3(0.0, agent.velocity.y, 0.0)
		return SUCCESS
	
	if nav_agent:
		# Get the node from BBNode's saved_value (NodePath)
		var node_path: NodePath = nav_agent.saved_value
		if node_path:
			var nav_node: Node = agent.get_node_or_null(node_path)
			if nav_node is NavigationAgent3D:
				var agent_navigator: NavigationAgent3D = nav_node as NavigationAgent3D
				
				# Always update the target position (in case it changes)
				agent_navigator.target_position = target_pos
				
				# Check if navigation is finished (reached target)
				if agent_navigator.is_navigation_finished():
					return SUCCESS
				
				# Get the next navigation point
				var next_nav_point: Vector3 = agent_navigator.get_next_path_position()
				
				# Calculate direction to next nav point (XZ plane only)
				var dir_to_next_nav_point: Vector3 = (next_nav_point - current_pos)
				dir_to_next_nav_point.y = 0.0  # Ignore Y component for XZ plane movement
				
				# Only move if we have a valid direction
				if dir_to_next_nav_point.length() > 0.01:
					dir_to_next_nav_point = dir_to_next_nav_point.normalized()
					
					if agent is Enemy:
						# Multiply by delta for frame-rate independent movement
						var dir_and_speed_vector: Vector3 = dir_to_next_nav_point * agent.SPEED * delta
						agent.velocity.x = dir_and_speed_vector.x
						agent.velocity.z = dir_and_speed_vector.z
	
	return RUNNING
