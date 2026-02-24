extends UICollapseTweener

@onready var pause_menu: PauseMenu = $"../.."

func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	Debug.log(size.y)
	Debug.log("visible: " + str(pause_menu.visible))
