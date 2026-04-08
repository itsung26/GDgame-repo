class_name ConsoleCommand
extends RefCounted
## Descriptor for a developer-console command: metadata plus a [Callable] invoked with parsed args.


enum ConsoleCommandPermission {
	DEBUG,
	CHEAT,
}

var name: StringName
var aliases: PackedStringArray
var help: String
var usage: String
var handler: Callable
var min_args: int
var max_args: int
var permission: ConsoleCommandPermission


func _init(
	p_name: StringName,
	p_handler: Callable,
	p_help: String = "",
	p_usage: String = "",
	p_aliases: PackedStringArray = PackedStringArray(),
	p_min_args: int = 0,
	p_max_args: int = 2147483647,
	p_permission: ConsoleCommandPermission = ConsoleCommandPermission.DEBUG,
) -> void:
	name = p_name
	handler = p_handler
	help = p_help
	usage = p_usage
	aliases = p_aliases
	min_args = p_min_args
	max_args = p_max_args
	permission = p_permission


func get_usage_or_name() -> String:
	if usage.length() > 0:
		return usage
	return str(name)


func get_one_line_help() -> String:
	var u: String = get_usage_or_name()
	if help.length() > 0:
		return u + " — " + help
	return u
