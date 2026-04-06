extends Node

var freeze_timer:Timer
var _cached_timescale:float
var _cached_timestop_end_callable:Callable = Callable()
var _callback_queue:Array[Callable]
var interruption_mode:interruption_modes = interruption_modes.WARN

## The mode determining the behavior of interruptions to the timeflow. [br]
## [br]
## [color=yellow]WARNING:[/color] changing this at runtime may have unintended effects.
enum interruption_modes {
	## If an interruption is requested while one is already active, replace it as well as its callback.
	REPLACE,
	## If an interruption is requested while one is already active, add to the active interruption duration and add its callback to a queue after the first callback.
	QUEUE,
	## Return and push an error/warning to the console, do nothing else.
	WARN,
	## Immidiately throw an exception.
	EXCEPTION,
	## Return immidiately, cancelling the callback passed.
	IGNORE
}


func _ready() -> void:
	freeze_timer = Timer.new()
	add_child(freeze_timer)
	freeze_timer.name = "FreezeTimer"
	freeze_timer.one_shot = true
	freeze_timer.ignore_time_scale = true
	# connect the freeze_timer's signal to this object's listener method
	freeze_timer.timeout.connect(_on_freeze_timer_timeout)
	_cached_timescale = getTimeScale()


func _on_freeze_timer_timeout() -> void:
	setTimeScale(_cached_timescale)
	if _cached_timestop_end_callable.is_valid():
		_cached_timestop_end_callable.call_deferred()
	_cached_timestop_end_callable = Callable()


## Sets the timescale to zero for the [param duration] specified, before resuming it
## back to the prior time when the duration has passed.
func interruptTimeflow(duration:float, on_interrupt_end:Callable = Callable()) -> void:
	if duration <= 0.0:
		Debug.logerr("Attempted to stop timeflow for a zero or less than zero duration.")
		return
	if getTimeScale() == 0.0:
		if interruption_mode == interruption_modes.WARN:
			Debug.logerr("Timescale is already zero. Was this call intended?")
			return
		elif interruption_mode == interruption_modes.EXCEPTION:
			assert(false, "Attempted to interrupt timeflow while timeflow is already interrupted.")
		elif interruption_mode == interruption_modes.REPLACE:
			pass
	
	_cached_timescale = getTimeScale()
	_cached_timestop_end_callable = on_interrupt_end
	setTimeScale(0.0)
	freeze_timer.start(duration)


## Setter for the engine timescale.
func setTimeScale(timescale:float) -> void:
	Engine.time_scale = timescale


func getTimeScale() -> float:
	return Engine.time_scale
