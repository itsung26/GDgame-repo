class_name unstuckHandler extends Node

@export var unstuck_position:Node3D
@onready var player:Player = Helper.getFirstInScene("Player")
@onready var pause_menu:pauseMenu = Helper.getFirstInScene("Pause")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_pressed() -> void:
	if unstuck_position:
		player.velocity = Vector3.ZERO
		player.global_position = unstuck_position.global_position
		player.rotation = Vector3.ZERO
		player.pivot.rotation = Vector3.ZERO
		pause_menu.pause_state = pause_menu.pause_states.UNPAUSED
		
	else:
		print("No unstuck position set! Set by assigning a node to the unstuck button.")
