## Abstract base class for debug classes. Runs as an autoload singleton. (loaded on first startup, never
## unloaded and can be refrenced from anywhere.)
extends Node

## Prints the text and the stack function and the current line.
func log(loggable) -> void:
	var lesser_stack:Dictionary = get_stack()[1]
	print("source: " + lesser_stack["source"] + " function: " + lesser_stack["function"] + " line: " + str(lesser_stack["line"]) + "\n" + str(loggable))
