class_name unstuckHandler extends Button

@export var unstuck_position:Node3D
@onready var player:Player = Helper.getFirstInScene("Player")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_pressed() -> void:
	if unstuck_position:
		player.global_position = unstuck_position.global_position
		player.rotation = Vector3.ZERO
		player.pivot.rotation = Vector3.ZERO
	else:
		print("No unstuck position set! Set by assigning a node to the unstuck button.")
