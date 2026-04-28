@tool
extends Node

## Main debug class for debug-related things. Runs as an autoload singleton. 
## (loaded on first startup, never unloaded and can be refrenced from anywhere.)
var debug_loggers:Array[DebugLogger] = []


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


## Prints the string from of the variant in a standard warning line.
## The stack trace is printed above the warning line as a regular print line.
func logwarn(loggable = "") -> void:
	var stackslim:String = getStackSlim()
	print(stackslim)
	push_warning(str(loggable))


## Creates a variable watcher that logs whenever the getter's value changes.
func createDebugLogger(name:String, getter:Callable, print_initial:bool = false) -> void:
	if name.is_empty():
		self.logerr("createDebugLogger(): name cannot be empty.")
		return
	if not getter.is_valid():
		self.logerr("createDebugLogger(): getter callable is invalid for logger: " + name)
		return
	if _get_logger_index(name) != -1:
		self.logerr("createDebugLogger(): logger already exists with name: " + name)
		return
	
	var logger:DebugLogger = DebugLogger.new(name, getter)
	debug_loggers.append(logger)
	if print_initial:
		self.log(name + " = " + str(logger.last_value))


## Removes a logger by its unique name.
func removeDebugLogger(name:String) -> void:
	var logger_index:int = _get_logger_index(name)
	if logger_index == -1:
		return
	debug_loggers.remove_at(logger_index)


## Removes all registered debug loggers.
func clearDebugLoggers() -> void:
	debug_loggers.clear()


func _process(_delta: float) -> void:
	var logger_count:int = debug_loggers.size()
	for logger_idx:int in range(logger_count):
		var logger:DebugLogger = debug_loggers[logger_idx]
		if logger == null:
			continue
		
		var has_change:bool = logger.pollHasChange()
		if has_change:
			self.log(logger.name + " = " + str(logger.last_value))


func _get_logger_index(name:String) -> int:
	var logger_count:int = debug_loggers.size()
	for logger_idx:int in range(logger_count):
		var logger:DebugLogger = debug_loggers[logger_idx]
		if logger != null and logger.name == name:
			return logger_idx
	return -1


class DebugLogger:
	var name:String = ""
	var getter:Callable
	var last_value:Variant = null
	var initialized:bool = false
	
	
	func _init(logger_name:String, logger_getter:Callable) -> void:
		name = logger_name
		getter = logger_getter
		last_value = getter.call()
		initialized = true
	
	
	func pollHasChange() -> bool:
		if not getter.is_valid():
			return false
		
		var new_value:Variant = getter.call()
		if initialized == false:
			last_value = new_value
			initialized = true
			return false
		
		if new_value != last_value:
			last_value = new_value
			return true
		return false
	
	
