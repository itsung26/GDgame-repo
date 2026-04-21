extends Node
## Autoload: registers [ConsoleCommand] entries in [method _ready] and dispatches via [method execute].
## Handlers are methods on this node whose names contain [code]COMMAND_[/code] (see [method getCommandHandlerMethodEntries]).

## Commands in registration order (oldest index first, newest appended).
var registered_console_commands: Array[ConsoleCommand] = []

signal command_failure(command:ConsoleCommand, failure_reason:String)
signal command_success(command:ConsoleCommand, success_message:String)


#region Command Registry
## Registers built-in [ConsoleCommand]s. Add more [method registerCommand] calls here for new commands.
func _ready() -> void:
	# GODMODE
	registerCommand(
		ConsoleCommand.new(
		"Godmode",
		Callable(self, "COMMAND_godMode"),
		["god", "God", "GodMode", "God_Mode", "god_mode", "jesuschrist", "JesusChrist"],
		0,
		0
		)
	)
	
	# PRINT
	registerCommand(
		ConsoleCommand.new(
		"print",
		Callable(self, "COMMAND_print"),
		["Print", "print"],
		0,
		1
		)
	)
	
	# LISTCOMMANDS
	registerCommand(
		ConsoleCommand.new(
			"listCommands",
			Callable(self, "COMMAND_listCommands"),
			["listcommands", "ListCommands", "help"],
			0,
			0
		)
	)
	
	# QUIT
	registerCommand(
		ConsoleCommand.new(
			"quit",
			Callable(self, "COMMAND_quit"),
			["Quit", "quitgame", "QuitGame", "quitGame"],
			0,
			0
		)
	)
	
	# FREECAM
	registerCommand(
		ConsoleCommand.new(
			"freeCam",
			Callable(self, "COMMAND_freeCam"),
			["FreeCam", "freecam", "Freecam"],
			0,
			0
		)
	)
	
	# TELEPORT
	registerCommand(
		ConsoleCommand.new(
			"teleport",
			Callable(self, "COMMAND_teleport"),
			["Teleport", "goto", "tp", "Tp"],
			3,
			3
		)
	)
	
	# DISABLEAI
	registerCommand(
		ConsoleCommand.new(
			"AiEnabled",
			Callable(self, "COMMAND_AiEnabled"),
			["ai", "AIenabled", "aienabled", "Aienabled", "aiEnabled"],
			1,
			1
		)
	)
#endregion


## Walks [member registered_console_commands] in order and first filters by [method ConsoleCommand.canRecognize] using [param invoked_name].
## Once a command matches, validates [param args] size against that command's [member ConsoleCommand.min_args] and [member ConsoleCommand.max_args], then invokes [member ConsoleCommand.handler].
## Returns [code]""[/code] after a successful handler run, an error string for bad arg counts, or an unknown-command error if no entry matched [param invoked_name].
func execute(invoked_name: String, args: PackedStringArray) -> String:
	for command: ConsoleCommand in registered_console_commands:
		if not command.canRecognize(invoked_name):
			continue
		
		var passed_args: int = args.size()
		if passed_args > command.max_args:
			command_failure.emit(command, "Exceeded command argument count.")
			return "ERROR: Exceeded command argument count. Expected: \n        " + "[" + command.name + " + " + str(command.min_args) + " to " + str(command.max_args) + " arguments]"
		if passed_args < command.min_args:
			command_failure.emit(command, "Did not meet minimum command argument count.")
			return "ERROR: Did not meet minimum command argument count. Expected: \n        " + "[" + command.name + " + " + str(command.min_args) + " to " + str(command.max_args) + " arguments]"
		command.handler.call(args)
		command_success.emit(command, "")
		return ""
	
	command_failure.emit(null, "Command not recognized.")
	return "ERROR: Command not recognized."


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
	var player: Player = LoadHandler.get_tree().get_first_node_in_group("players")
	var dev_console:DevConsole = get_tree().get_first_node_in_group("developer console")
	if player.Godmode:
		player.Godmode = false
		dev_console.pushConsoleOutput("Godmode OFF")
	else:
		player.Godmode = true
		dev_console.pushConsoleOutput("Godmode ON")


## Prints one argument to [Debug]. Expects exactly one token after the command name.
## [param args] must contain at least index [code]0[/code] when invoked through [method execute] with matching bounds.
func COMMAND_print(args: PackedStringArray):
	var arg: String = str(args[0])
	Debug.log(arg)


func COMMAND_listCommands(args: PackedStringArray):
	var dev_console:DevConsole = QuickRef.dev_console
	for i:String in getCommandNames():
		dev_console.pushConsoleOutput(i)


func COMMAND_quit(args: PackedStringArray):
	# exception from the replace print with Debug.log convention
	print("goodbye")
	get_tree().quit()


func COMMAND_freeCam(args: PackedStringArray):
	var freecam:FreeCamera
	var player:Player = get_tree().get_first_node_in_group("players")
	var dev_console:DevConsole = get_tree().get_first_node_in_group("developer console")
	
	if get_tree().get_first_node_in_group("free camera"):
		freecam = get_tree().get_first_node_in_group("free camera")
		freecam.queue_free()
		player.camera_3d.make_current()
		player.enableInputAllowments()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		dev_console.pushConsoleOutput("toggled freecam OFF")
	else:
		var freecam_SCENE:PackedScene = load("res://scenes/free_camera.tscn")
		freecam = freecam_SCENE.instantiate()
		get_tree().current_scene.add_child(freecam)
		freecam.global_position = player.camera_3d.global_position
		freecam.make_current()
		player.disableInputAllowments()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		dev_console.pushConsoleOutput("toggled freecam ON")


## usage - teleport x y z
func COMMAND_teleport(args: PackedStringArray):
	if args.size() != 3:
		return
	var x:float = float(args[0])
	var y:float = float(args[1])
	var z:float = float(args[2])
	var player:Player = QuickRef.player
	var teleport_position:Vector3 = Vector3(x, y, z)
	
	player.global_position = teleport_position
	QuickRef.dev_console.pushConsoleOutput("Teleported to " + str(teleport_position))


## Toggles the ai state. Usage: AiEnabled [0 or 1]
func COMMAND_AiEnabled(args: PackedStringArray):
	var enemies:Array[Enemy] = EnemyPopulationHandler.getAllEnemies()
	var argument:int = int(args[0])
	
	if argument != 1 and argument != 0:
		QuickRef.dev_console.pushConsoleOutput("Unrecognized argument. Expected 0 or 1.")
		return
	
	for enemy:Enemy in enemies:
		if enemy:
			enemy.behavior_enabled = (argument == 1)
	
	if argument == 1:
		QuickRef.dev_console.pushConsoleOutput("ai ON")
	else:
		QuickRef.dev_console.pushConsoleOutput("ai OFF")


#endregion
