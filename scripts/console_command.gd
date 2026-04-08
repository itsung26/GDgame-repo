class_name ConsoleCommand
extends RefCounted
## Descriptor for a developer-console command: metadata plus a [Callable] invoked with parsed args.
## Commands are formatted as such:
## [codeblock]name_or_alias arg1 arg2[/codeblock]
## [br]Note that all arguments are parsed as strings.


## Whether the command is allowed in normal debug builds ([code]DEBUG[/code]) or only when cheats are enabled ([code]CHEAT[/code]).
enum Permission {
	DEBUG,
	CHEAT,
}

## Primary name used on the command line (first token).
var name: StringName
## Alternate names that resolve to this command.
var aliases: PackedStringArray
## Method actually executing the command.
var handler: Callable
## Minimum number of argument tokens after the command name.
var min_args: int
## Maximum number of argument tokens after the command name.
var max_args: int


## Stores metadata and [param p_handler], which the registry invokes with argument tokens only.
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


func _to_string() -> String:
	return "Command(" + name + ", " + "min args: " + str(min_args) + ")"


## Returns true if [param what] is equal to the main name or any of the aliases.
func canRecognize(what:String) -> bool:
	if what == name:
		return true
	else:
		for alias:String in aliases:
			if what == alias:
				return true
	return false
