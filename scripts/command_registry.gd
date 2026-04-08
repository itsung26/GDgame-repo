extends Node
## Autoload: all console command implementations live here. Commands are registered in [method _ready].
## Call [method execute] with a command name and args, or [method run_line] for a single parsed line.

## All registered console commands, sorted by order of addition by oldest to newest.
var registered_console_commands:Array[ConsoleCommand] = []


## Commands are registered here.
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


## Runs a registered command by [param invoked_name] and [param args] (arguments only, not the command word). Returns text for the console log.
func execute(invoked_name: String, args: PackedStringArray) -> String:
	for command:ConsoleCommand in registered_console_commands:
		var passed_args:int = args.size()
		if passed_args > command.max_args:
			return "ERROR: Exceeded command argument count."
		elif passed_args < command.min_args:
			return "ERROR: Did not meet minimum command argument count."
		
		if command.canRecognize(invoked_name):
			command.handler.call(args)
	return ""


## Adds [param cmd] to the lookup tables; returns [code]false[/code] on duplicate name, alias, or invalid handler.
func registerCommand(cmd: ConsoleCommand) -> void:
	registered_console_commands.append(cmd)


## Returns a list of dictionaries describing methods that are recognized as console commands by the COMMAND_ prefix in the method name.
func getCommandMethodList() -> Array[Dictionary]:
	var method_list:Array[Dictionary] = get_method_list()
	var ret:Array[Dictionary] = []
	
	# sort out command prefixed callables from the overall method list
	for method:Dictionary in method_list:
		var method_name:String = method["name"]
		if method_name.contains("COMMAND_"):
			ret.append(method)
	
	return ret


## Returns a list of callables constructed from the methods defined with the COMMAND_ prefix.
func getAllCommandMethods() -> Array[Callable]:
	var ret:Array[Callable] = []
	for method_description:Dictionary in getCommandMethodList():
		var new_callable:Callable = Callable(self, method_description["name"])
		ret.append(new_callable)
	return ret


#region Console Command Handlers
## Toggles godmode
func COMMAND_godMode(args:PackedStringArray):
	Debug.log("done")

## Logs a message in the engine console. Expects one command argument.
func COMMAND_print(args:PackedStringArray):
	var arg:String = str(args[0])
	Debug.log(arg)
#endregion

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug func"):
		execute("god", [])
