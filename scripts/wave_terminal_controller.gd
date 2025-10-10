@tool
class_name WaveTerminal extends Node3D
@onready var cube_head: MeshInstance3D = $Cube_head
@onready var target: Marker3D = %target
@onready var cube_head_ears: MeshInstance3D = $Cube_head/Cube_head_ears
@onready var screen: MeshInstance3D = $Cube_head/Screen
@onready var screen_top_left: Marker3D = $Cube_head/Screen/EdgeMarkers/screenTopLeft
@onready var screen_top_right: Marker3D = $Cube_head/Screen/EdgeMarkers/screenTopRight
@onready var screen_bottom_left: Marker3D = $Cube_head/Screen/EdgeMarkers/screenBottomLeft
@onready var screen_bottom_right: Marker3D = $Cube_head/Screen/EdgeMarkers/screenBottomRight
@onready var top_left_line: MeshInstance3D = $EdgeLines/topLeftLine
@onready var top_right_line: MeshInstance3D = $EdgeLines/topRightLine
@onready var bottom_left_line: MeshInstance3D = $EdgeLines/bottomLeftLine
@onready var bottom_right_line: MeshInstance3D = $EdgeLines/bottomRightLine
@onready var cube_head_lens: MeshInstance3D = $Cube_head/Cube_head_lens
@onready var player:Player = Helper.getFirstInScene("Player")
@onready var animation_player: AnimationPlayer = $AnimationPlayer


@export var look_at_target:Vector3 = Vector3.ZERO
@export var player_in_collider:bool = false
@export var look_at_enabled:bool = false
var cube_ears_inactive_rotation = Vector3.ZERO
var cube_ears_active_rotation = Vector3(0.0,0.0,60.0)

func linesGotoEdges():
	top_left_line.global_position = (screen_top_left.global_position + cube_head_lens.global_position)/2
	top_left_line.look_at(screen_top_left.global_position)
	top_left_line.rotation.x -= deg_to_rad(90)
	
	top_right_line.global_position = (screen_top_right.global_position + cube_head_lens.global_position)/2
	top_right_line.look_at(screen_top_right.global_position)
	top_right_line.rotation.x -= deg_to_rad(90)
	
	bottom_left_line.global_position = (screen_bottom_left.global_position + cube_head_lens.global_position)/2
	bottom_left_line.look_at(screen_bottom_left.global_position)
	bottom_left_line.rotation.x -= deg_to_rad(90)

	bottom_right_line.global_position = (screen_bottom_right.global_position + cube_head_lens.global_position)/2
	bottom_right_line.look_at(screen_bottom_right.global_position)
	bottom_right_line.rotation.x -= deg_to_rad(90)

func _process(delta: float) -> void:
	if look_at_enabled:
		if not Engine.is_editor_hint():
			target.global_position = player.global_position
			look_at_target = target.global_position
		else:
			look_at_target = target.global_position
	
	# cube head to look in the opposite direction of look_at_target
	var opposite_direction = cube_head.global_position - look_at_target
	cube_head.look_at(cube_head.global_position + opposite_direction, Vector3.UP)
	cube_head.rotation.z = 0
	cube_head.rotation.x = 0
	cube_head.rotation.y = cube_head.rotation.y + deg_to_rad(90)
	
	linesGotoEdges()


func _on_player_collider_body_entered(body: Player) -> void:
	look_at_enabled = true
	animation_player.play("activate")


func _on_player_collider_body_exited(body: Player) -> void:
	look_at_enabled = false
	animation_player.play("deactivate")
