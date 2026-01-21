class_name unstuckHandler extends Node

@onready var player:Player = get_tree().get_first_node_in_group("players")
@onready var pause_menu:pauseMenu = Helper.getFirstInScene("Pause")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_pressed() -> void:
	player.respawnCheckPoint()
