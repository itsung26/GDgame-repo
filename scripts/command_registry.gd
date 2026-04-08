extends Node
## Autoload: register [ConsoleCommand]s, parse lines, enforce permissions and arg counts, run handlers.
## The dev console UI should call [method run_line] and display the returned text.


## When false, cheat permission commands are rejected by [method run_line].
var cheat_commands_allowed: bool = false

var _by_name: Dictionary = {}
var _unique: Array[ConsoleCommand] = []


func register(cmd: ConsoleCommand) -> bool:
	if cmd.name == StringName():
		Debug.logerr("CommandRegistry.register: command name is empty.")
		return false
	if not cmd.handler.is_valid():
		Debug.logerr("CommandRegistry.register: handler is not valid for command: " + str(cmd.name))
		return false
	if _by_name.has(cmd.name):
		Debug.logerr("CommandRegistry.register: duplicate command name: " + str(cmd.name))
		return false
	for a: String in cmd.aliases:
		var alias_key: StringName = StringName(a)
		if _by_name.has(alias_key):
			Debug.logerr("CommandRegistry.register: alias already in use: " + a)
			return false
	if _unique.has(cmd):
		Debug.logerr("CommandRegistry.register: command object already registered.")
		return false
	_unique.append(cmd)
	_by_name[cmd.name] = cmd
	for a2: String in cmd.aliases:
		_by_name[StringName(a2)] = cmd
	return true


func unregister_by_name(primary_name: StringName) -> void:
	if not _by_name.has(primary_name):
		return
	var cmd: ConsoleCommand = _by_name[primary_name] as ConsoleCommand
	if cmd == null:
		return
	if cmd.name != primary_name:
		Debug.logerr("CommandRegistry.unregister_by_name: not a primary name: " + str(primary_name))
		return
	_by_name.erase(cmd.name)
	for a: String in cmd.aliases:
		_by_name.erase(StringName(a))
	_unique.erase(cmd)


func find_command(key: StringName) -> ConsoleCommand:
	if not _by_name.has(key):
		return null
	return _by_name[key] as ConsoleCommand


func get_all_commands() -> Array[ConsoleCommand]:
	return _unique.duplicate()


func run_line(line: String) -> String:
	var parts: PackedStringArray = split_command_line(line)
	if parts.is_empty():
		return ""
	var cmd_name: StringName = StringName(parts[0])
	var cmd: ConsoleCommand = find_command(cmd_name)
	if cmd == null:
		return "Unknown command: " + str(cmd_name)
	var arg_count: int = parts.size() - 1
	if arg_count < cmd.min_args or arg_count > cmd.max_args:
		return "Usage: " + cmd.get_usage_or_name()
	if cmd.permission == ConsoleCommand.ConsoleCommandPermission.CHEAT and not cheat_commands_allowed:
		return "Cheat commands are disabled."
	var args: PackedStringArray = _parts_to_args(parts)
	return _invoke(cmd, args)


func format_help() -> String:
	var lines: PackedStringArray = PackedStringArray()
	for cmd: ConsoleCommand in _unique:
		lines.append(cmd.get_one_line_help())
	lines.sort()
	return "\n".join(lines)


static func split_command_line(line: String) -> PackedStringArray:
	var out: Array[String] = []
	var cur: String = ""
	var in_quotes: bool = false
	var quote_ch: String = ""
	var s: String = line.strip_edges()
	var i: int = 0
	while i < s.length():
		var ch: String = s[i]
		if in_quotes:
			if ch == quote_ch:
				in_quotes = false
				quote_ch = ""
			else:
				cur += ch
			i += 1
			continue
		if ch == "\"" or ch == "'":
			in_quotes = true
			quote_ch = ch
			i += 1
			continue
		if ch == " " or ch == "\t":
			if cur.length() > 0:
				out.append(cur)
				cur = ""
			i += 1
			continue
		cur += ch
		i += 1
	if cur.length() > 0:
		out.append(cur)
	return PackedStringArray(out)


func _parts_to_args(parts: PackedStringArray) -> PackedStringArray:
	if parts.size() <= 1:
		return PackedStringArray()
	return PackedStringArray(parts.slice(1, parts.size()))


func _invoke(cmd: ConsoleCommand, args: PackedStringArray) -> String:
	var result: Variant = cmd.handler.call(args)
	if result == null:
		return ""
	return str(result)
