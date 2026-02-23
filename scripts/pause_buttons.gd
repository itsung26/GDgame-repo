extends UICollapseTweener

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	collapseVertical()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_pause_menu_paused() -> void:
	expandVertical()

func _on_pause_menu_unpaused() -> void:
	collapseVertical()
