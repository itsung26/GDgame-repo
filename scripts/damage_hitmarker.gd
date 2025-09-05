extends Control
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var tracked_enemy: Node3D = null
var tracked_camera: Camera3D = null
var randoffset:Vector2 = Vector2.ZERO

func _ready() -> void:
	randoffset.x = randf_range(-50,50)
	randoffset.y = randf_range(-50,50)
	# generates a random 2d vector upon being instanced

	# generates a random value integer to decide the animation the hitmarker plays
	var R_or_L_anim:int = randi_range(0,1)
	if R_or_L_anim == 0:
		if Global.pistol_special_state:
			animation_player.play("falloff_right_red")
		else:
			animation_player.play("falloff_right")
	elif R_or_L_anim == 1:
		if Global.pistol_special_state:
			animation_player.play("falloff_left_red")
		else:
			animation_player.play("falloff_left")
	

func _process(_delta):
	
	if tracked_enemy and tracked_camera:
		position = tracked_camera.unproject_position(tracked_enemy.global_position)
