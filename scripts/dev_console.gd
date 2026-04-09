class_name DevConsole
extends CanvasLayer

@onready var command_input: LineEdit = $RootMargin/ConsolePanel/VBox/InputRow/CommandInput
@onready var output: RichTextLabel = $RootMargin/ConsolePanel/VBox/OutputScroll/Output

## Prevents the command console from displaying over this many lines.
@export_range(0, 500, 1) var max_lines_displayable:int = 250


func _ready() -> void:
	setVisible(false)


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
	pass


func _on_command_input_text_submitted(new_text: String) -> void:
	pass # Replace with function body.
