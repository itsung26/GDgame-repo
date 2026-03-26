@tool
extends Node

## Main debug class for debug-related things. Runs as an autoload singleton. 
## (loaded on first startup, never unloaded and can be refrenced from anywhere.)


## Gets a cleaned-up version of the current stack trace and returns it as a concatenated
## string.
func getStackSlim() -> String:
	var stack:Array[Dictionary] = get_stack()
	var lesser_stack:Dictionary = stack.back()
	var r:String = "source: " + lesser_stack["source"] + " function: " + lesser_stack["function"] + " line: " + str(lesser_stack["line"])
	return r


## Prints the string from of the variant and the stack function and the current line.
## Intended to replace default print() behaviour.
func log(loggable = "") -> void:
	var stackslim:String = getStackSlim()
	print(stackslim + "\n" + str(loggable))


## Prints the string from of the variant in a standard error line.
## The stack trace is printed above the error line as a regular print line.
## Intended to replace default printerr() behaviour.
func logerr(loggable = "") -> void:
	var stackslim:String = getStackSlim()
	print(stackslim)
	printerr(str(loggable))
