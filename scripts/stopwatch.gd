extends Node

var running:bool
var TIME:float

func start():
	TIME = 0.0
	running = false
	


## Returns time in seconds.
func getTimeSeconds() -> int:
	return TIME

func getTimeMinutes() -> int:
	var a = TIME / 60
	a = floor(a)
	var b:int = a
	return b

func getTimeMs() -> int:
	return TIME * 1000

func reset(stop:bool):
	if stop:
		running = false
		TIME = 0.0
	else:
		TIME = 0.0
		
func pause():
	running = false

func resume():
	running = true
	

func _process(delta: float) -> void:
	running = true
	if running:
		TIME += delta
	
