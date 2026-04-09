extends Node
## Autoload: registers [ConsoleCommand] entries in [method _ready] and dispatches via [method execute].
## Handlers are methods on this node whose names contain [code]COMMAND_[/code] (see [method getCommandHandlerMethodEntries]).

## Commands in registration order (oldest index first, newest appended).
var registered_console_commands: Array[ConsoleCommand] = []

signal command_failure(command:ConsoleCommand, failure_reason:String)
signal command_success(command:ConsoleCommand, success_message:String)


## Registers built-in [ConsoleCommand]s. Add more [method registerCommand] calls here for new commands.
func _ready() -> void:
	registerCommand(ConsoleCommand.new(
		"Godmode",
		Callable(self, "COMMAND_godMode"),
		["god", "God", "GodMode", "God_Mode", "god_mode", "jesuschrist", "JesusChrist"],
		0,
		0
	))

	registerCommand(ConsoleCommand.new(
		"print",
		Callable(self, "COMMAND_print"),
		["Print"],
		0,
		1
	))


## Walks [member registered_console_commands] in order. For each entry, checks [param args] size against that entry's [member ConsoleCommand.min_args] / [member ConsoleCommand.max_args] first, then [method ConsoleCommand.canRecognize] with [param invoked_name]. If recognition succeeds, calls [member ConsoleCommand.handler] (return values are discarded); the loop does not stop, so later entries can also run if they recognize the same [param invoked_name]. Returns an error string as soon as an entry's argument bounds fail, or [code]""[/code] after the loop (including when nothing matched).
func execute(invoked_name: String, args: PackedStringArray) -> String:
	for command: ConsoleCommand in registered_console_commands:
		
		var passed_args: int = args.size()
		if passed_args > command.max_args:
			command_failure.emit(command, "Exceeded command argument count.")
			return "ERROR: Exceeded command argument count."
		elif passed_args < command.min_args:
			command_failure.emit(command, "Did not meet minimum command argument count.")
			return "ERROR: Did not meet minimum command argument count."
		
		# If the invoked_name matches the command's name or an alias, call its helper.
		if command.canRecognize(invoked_name):
			command.handler.call(args)
	return ""


## Appends [param cmd] to [member registered_console_commands]. Does not check for duplicate names or aliases.
func registerCommand(cmd: ConsoleCommand) -> void:
	registered_console_commands.append(cmd)


## Subset of [method Object.get_method_list] for this node: dictionary entries whose [code]"name"[/code] [String] [method String.contains] the substring [code]COMMAND_[/code] (not limited to a strict prefix).
func getCommandHandlerMethodEntries() -> Array[Dictionary]:
	var method_list: Array[Dictionary] = get_method_list()
	var ret: Array[Dictionary] = []

	# sort out command prefixed callables from the overall method list
	for method: Dictionary in method_list:
		var method_name: String = method["name"]
		if method_name.contains("COMMAND_"):
			ret.append(method)

	return ret


## Builds [Callable]s on this node for each [code]"name"[/code] from [method getCommandHandlerMethodEntries].
func getCommandHandlerCallables() -> Array[Callable]:
	var ret: Array[Callable] = []
	for method_description: Dictionary in getCommandHandlerMethodEntries():
		var new_callable: Callable = Callable(self, method_description["name"])
		ret.append(new_callable)
	return ret


## Finds and returns the console command from registered_console_commands that has the
## handler passed.
func getConsoleCommand(handler:Callable) -> ConsoleCommand:
	for command:ConsoleCommand in registered_console_commands:
		if command.handler == handler:
			return command
	return null


func getCommandNames() -> Array[String]:
	var ret:Array[String] = []
	for method_description: Dictionary in getCommandHandlerMethodEntries():
		ret.append(method_description["name"])
	return ret


#region Console Command Handlers
## Godmode command: placeholder; logs to [Debug].
## [param args] must satisfy the [ConsoleCommand] bounds registered for this handler (currently zero arguments).
func COMMAND_godMode(args: PackedStringArray):
	var player:Player = LoadHandler.get_tree().get_first_node_in_group("players")
	player.Godmode = true
	command_success.emit()


## Prints one argument to [Debug]. Expects exactly one token after the command name.
## [param args] must contain at least index [code]0[/code] when invoked through [method execute] with matching bounds.
func COMMAND_print(args: PackedStringArray):
	var arg: String = str(args[0])
	Debug.log(arg)
#endregion


## Debug: when the [code]debug func[/code] input action fires, runs [method execute] with [code]"god"[/code] and no args.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug func"):
		execute("god", [])
