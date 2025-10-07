extends Control
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var damage_number_label: Label = %DamageNumberLabel

var tracked_enemy:Enemy = null
var tracked_camera: Camera3D = null
var randoffset:Vector2 = Vector2.ZERO

func _ready() -> void:
	randoffset.x = randf_range(-50,50)
	randoffset.y = randf_range(-50,50)
	# generates a random 2d vector upon being instanced
	
	if tracked_enemy and tracked_camera:
		# generates a random value integer to decide the animation the hitmarker plays (left or right)
		var R_or_L_anim:int = randi_range(0,1)
		# falloff right
		if R_or_L_anim == 0:
			if tracked_enemy.last_hit_damage_type == tracked_enemy.damage_types.DARK:
				animation_player.play("falloff_right_purple")
			elif tracked_enemy.last_hit_damage_type == tracked_enemy.damage_types.NORMAL:
				animation_player.play("falloff_right")
			elif tracked_enemy.last_hit_damage_type == tracked_enemy.damage_types.LASER:
				animation_player.play("falloff_right_red")
		# falloff left
		elif R_or_L_anim == 1:
			if tracked_enemy.last_hit_damage_type == tracked_enemy.damage_types.DARK:
				animation_player.play("falloff_left_purple")
			elif tracked_enemy.last_hit_damage_type == tracked_enemy.damage_types.NORMAL:
				animation_player.play("falloff_left")
			elif tracked_enemy.last_hit_damage_type == tracked_enemy.damage_types.LASER:
				animation_player.play("falloff_left_red")
	

func _process(_delta):
	
	if tracked_enemy and tracked_camera:
		var damage_type = "UNKNOWN"
		position = tracked_camera.unproject_position(tracked_enemy.global_position)
		if tracked_enemy.last_hit_damage_type == tracked_enemy.damage_types.DARK:
			damage_type = "DARK"
		elif tracked_enemy.last_hit_damage_type == tracked_enemy.damage_types.NORMAL:
			damage_type = "NORMAL"
		elif tracked_enemy.last_hit_damage_type == tracked_enemy.damage_types.LASER:
			damage_type = "OVERCLOCK"
