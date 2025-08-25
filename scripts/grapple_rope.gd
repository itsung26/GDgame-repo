extends MeshInstance3D
@onready var player: CharacterBody3D = $"../../.."


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(float) -> void:
	if player.grappling:
		visible = true
	else:
		visible = false
	
	var player_dist_to_grapplePoint = player.global_position.distance_to(player.grapple_target_pos)
	var direction = (player.grapple_target_pos - player.global_position).normalized()
	
	# Create a cylinder mesh between the points
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.05
	cylinder.bottom_radius = 0.05
	cylinder.height = player_dist_to_grapplePoint
	mesh = cylinder
	
	# Compute midpoint
	var midpoint = player.global_position + direction * player_dist_to_grapplePoint / 2
	
	global_position = midpoint
	
	look_at(player.grapple_target_pos, Vector3.UP)
	rotate_x(deg_to_rad(90))
