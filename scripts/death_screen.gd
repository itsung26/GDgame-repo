@tool
extends Control

# object refrences
@onready var bg: Panel = $bg
@onready var label_2: Label = $bg/VBoxContainer/Label2
@onready var timer: Timer = $Timer

@export_tool_button("Reset") var reset_action = reset
@export_tool_button("Activate") var activate_action = activate

func reset():
	bg.visible = false
	
	
func activate():
	bg.visible = true
	timer.start()
	print("timer started")
	
