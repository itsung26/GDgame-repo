class_name DevConsole
extends CanvasLayer

@onready var command_input: LineEdit = $RootMargin/ConsolePanel/VBox/InputRow/CommandInput
@onready var output: RichTextLabel = $RootMargin/ConsolePanel/VBox/OutputScroll/Output

## Prevents the command console from displaying over this many lines.
@export_range(0, 500, 1) var max_lines_displayable:int = 250


func _ready() -> void:
	clearCommandInput()
	setVisible(false)
	CommandRegistry.connect("command_success", _on_command_success)
	CommandRegistry.connect("command_failure", _on_command_failure)


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("developer console"):
		setVisible(!visible)
		
		if visible:
			command_input.grab_focus()


func setVisible(value:bool) -> void:
	visible = value


func clearCommandInput() -> void:
	command_input.text = ""


## Pushes [param what] to the console output on a new line.
func pushConsoleOutput(what:String) -> void:
	var existing_lines:PackedStringArray = output.get_parsed_text().split("\n", false)
	existing_lines.append(what)
	if max_lines_displayable > 0 and existing_lines.size() > max_lines_displayable:
		var start_index:int = existing_lines.size() - max_lines_displayable
		existing_lines = PackedStringArray(existing_lines.slice(start_index, existing_lines.size()))
	output.clear()
	output.append_text("\n".join(existing_lines))
	output.scroll_to_line(output.get_line_count())


## Returns an array containing all parts of [param what] seperated by spaces.
func splitStringBySpaces(what:String) -> PackedStringArray:
	var raw_parts:PackedStringArray = what.strip_edges().split(" ", false)
	var ret:PackedStringArray = []
	for part:String in raw_parts:
		if part != "":
			ret.append(part)
	return ret


func _on_command_input_text_submitted(new_text: String) -> void:
	if new_text == "":
		return
	Debug.log(CommandRegistry.getCommandNames())
	command_input.clear()
	
	var parts:PackedStringArray = splitStringBySpaces(new_text)
	var passed_command:String = parts[0]
	var passed_args:PackedStringArray = parts
	passed_args.remove_at(0)
	
	var error_status:String = CommandRegistry.execute(passed_command, passed_args)
	if error_status != "":
		pushConsoleOutput(error_status)


func _on_command_failure(command:ConsoleCommand, failure_reason:String) -> void:
	pass


func _on_command_success(command:ConsoleCommand, success_message:String) -> void:
	pass
