class_name DoubleDoor extends Node3D
@onready var door_animator: AnimationPlayer = $DoorAnimator
@onready var collision_shape_3d: CollisionShape3D = $DoorExitCollision/CollisionShape3D
@onready var door_open_timer: Timer = $DoorOpenTimer
@onready var door_light: OmniLight3D = $DoorLight

## Delay before door opens in seconds.
@export var door_open_delay:float = 1.0
@export var player_has_entered:bool = false

func _ready() -> void:
	door_light.light_energy = 0

# Green box is the exit
# Red box is the enter

func _on_door_enter_collision_body_entered(body:Player) -> void:
	door_animator.play("door_open")


func _on_door_enter_collision_body_exited(body:Player) -> void:
	door_animator.play("door_close")


func _on_door_exit_collision_body_entered(body:Player) -> void:
	if not player_has_entered:
		player_has_entered = true
		door_open_timer.start(door_open_delay)
		collision_shape_3d.disabled = true
		door_light.light_energy = 5.262


func _on_door_exit_collision_body_exited(body:Player) -> void:
	# door_animator.play("door_close")
	pass


func _on_door_open_timer_timeout() -> void:
	door_animator.play("door_open")
