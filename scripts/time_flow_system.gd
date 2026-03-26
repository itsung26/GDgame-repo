extends Node

var freeze_timer:Timer
var _cached_timescale:float


func _ready() -> void:
	freeze_timer = Timer.new()
	add_child(freeze_timer)
	freeze_timer.one_shot = true
	# connect the freeze_timer's signal to this object's listener method
	freeze_timer.timeout.connect(_on_freeze_timer_timeout)
	_cached_timescale = Engine.time_scale


func _on_freeze_timer_timeout() -> void:
	Engine.time_scale = _cached_timescale


func interruptTimeflow(duration:float) -> void:
	if Engine.time_scale == 0.0:
		printerr()
	_cached_timescale = Engine.time_scale
	Engine.time_scale = 0.0
	freeze_timer.start(duration)
