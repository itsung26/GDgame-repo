extends Node

var freeze_timer:Timer

func _ready() -> void:
	freeze_timer = Timer.new()
	add_child(freeze_timer)
	freeze_timer.one_shot = true
	# connect the freeze_timer's signal to this object's listener method
	freeze_timer.timeout.connect(_on_freeze_timer_timeout)

func _on_freeze_timer_timeout() -> void:
	pass
