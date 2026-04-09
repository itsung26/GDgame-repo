class_name ConsoleCommand
extends RefCounted
## Lightweight descriptor for a developer-console command: a display name, aliases, argument bounds, and a [Callable] handler.
## Typical input shape (tokens after splitting a line):
## [code]name_or_alias arg1 arg2[/code]
## All argument tokens are strings; parsing (quotes, spaces) is done by the caller.


## Reserved for future permission tiers (e.g. cheat vs debug). Not read by [CommandRegistry] yet.
enum Permission {
	DEBUG,
	CHEAT,
}

## Display / canonical name for the command (also matched by [method canRecognize]).
var name: StringName
## Extra strings that [method canRecognize] treats as this command (case-sensitive [code]==[/code]).
var aliases: PackedStringArray
## Called by [method CommandRegistry.execute] when this command matches; receives only argument tokens (not the invoked name).
var handler: Callable
## Minimum number of argument tokens required after the command name.
var min_args: int
## Maximum number of argument tokens allowed after the command name.
var max_args: int


## Assigns fields. [param p_handler] should accept [code]PackedStringArray[/code] (often a [code]COMMAND_*[/code] method on [CommandRegistry]).
func _init(
	p_name: StringName,
	p_handler: Callable,
	p_aliases: PackedStringArray = PackedStringArray(),
	p_min_args: int = 0,
	p_max_args: int = 2147483647,
) -> void:
	name = p_name
	handler = p_handler
	aliases = p_aliases
	min_args = p_min_args
	max_args = p_max_args


## Debug string: primary name and [member min_args] only.
func _to_string() -> String:
	return "Command(" + name + ", " + "min args: " + str(min_args) + ")"


## [code]true[/code] if [param what] equals [member name] or one of [member aliases] (case-sensitive; [String] and [StringName] compare by value).
func canRecognize(what: String) -> bool:
	if what == name:
		return true
	else:
		for alias: String in aliases:
			if what == alias:
				return true
	return false
