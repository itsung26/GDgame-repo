extends AnimationPlayer

var _last_ticks_usec:int = 0


func _ready() -> void:
	# Disable built-in stepping so we can advance with unscaled real time.
	set_process_callback(AnimationPlayer.ANIMATION_PROCESS_MANUAL)
	_last_ticks_usec = Time.get_ticks_usec()


func _process(_delta: float) -> void:
	var now_usec:int = Time.get_ticks_usec()
	var unscaled_delta:float = float(now_usec - _last_ticks_usec) / 1000000.0
	_last_ticks_usec = now_usec
	if unscaled_delta <= 0.0:
		return
	advance(unscaled_delta)
