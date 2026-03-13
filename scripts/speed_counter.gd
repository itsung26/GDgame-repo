class_name SpeedCounter
extends Panel

@onready var label: Label = $CenterContainer/Label
@onready var player:Player = get_tree().get_first_node_in_group("players")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	setReadout(player.velocity.length())

func setReadout(speed:float) -> void:
	speed = clamp(speed, 0.0, 99.9)
	# Round to one decimal place.
	var rounded_speed:float = snapped(speed, 0.1)
	
	# Format with leading zero if needed (e.g. 7.3 -> "07.3").
	var value_as_string:String
	if rounded_speed < 10.0:
		value_as_string = "0" + "%.1f" % rounded_speed
	else:
		value_as_string = "%.1f" % rounded_speed
	
	label.text = value_as_string + "\nu/s"
