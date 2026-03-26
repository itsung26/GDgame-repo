extends Node

var freeze_timer:Timer
var _cached_timescale:float
var _cached_timestop_end_callable:Callable = Callable()


func _ready() -> void:
	freeze_timer = Timer.new()
	add_child(freeze_timer)
	freeze_timer.name = "FreezeTimer"
	freeze_timer.one_shot = true
	freeze_timer.ignore_time_scale = true
	# connect the freeze_timer's signal to this object's listener method
	freeze_timer.timeout.connect(_on_freeze_timer_timeout)
	_cached_timescale = Engine.time_scale


func _on_freeze_timer_timeout() -> void:
	Engine.time_scale = _cached_timescale
	if _cached_timestop_end_callable.is_valid():
		_cached_timestop_end_callable.call_deferred()
	_cached_timestop_end_callable = Callable()


## Sets the timescale to zero for the [param duration] specified, before resuming it
## back to the prior time when the duration has passed.
func interruptTimeflow(duration:float, on_interrupt_end:Callable = Callable()) -> void:
	if duration <= 0.0:
		Debug.logerr(
			"Attempted to stop timeflow for a zero or less than zero duration."
			)
		return
	if Engine.time_scale == 0.0:
		Debug.logerr("Timescale is already zero. Was this call intended?")
		return
	_cached_timescale = Engine.time_scale
	_cached_timestop_end_callable = on_interrupt_end
	Engine.time_scale = 0.0
	freeze_timer.start(duration)


## Setter for the engine timescale.
func setTimeScale(timescale:float) -> void:
	Engine.time_scale = timescale


func getTimeScale() -> float:
	return Engine.time_scale
