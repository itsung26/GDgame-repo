extends Node3D
@onready var animation_player: AnimationPlayer = $minigun/AnimationPlayer
@onready var spin_up_timer: Timer = $SpinUpTimer



func isReadyToFire():
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if Input.is_action_just_pressed("reload"):
		if animation_player.is_playing():
			animation_player.stop()
		animation_player.play("allanims")
		
	if Input.is_action_pressed("right click action"):
		if animation_player.current_animation == "allanims":
			pass
		else:
			# animation_player.play("spinUp")
			if Input.is_action_pressed("fire"):
				animation_player.play("fireMinigun")
