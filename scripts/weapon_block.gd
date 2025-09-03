extends Button

var self_style
var mouse_in_box:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	print(mouse_in_box)
	pass


func _on_mouse_entered() -> void:
	print("mouse entered")
	mouse_in_box = true

func _on_mouse_exited() -> void:
	print("mouse exited")
	mouse_in_box = false
	
