@tool
extends EditorScript

var g = 1.0

func foo(dd:float):
	dd = 5.0

func _run() -> void:
	Debug.log(g)
	foo(g)
	Debug.log(g)
