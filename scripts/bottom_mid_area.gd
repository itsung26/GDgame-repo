# Godot version: 4.4.1 stable
extends Control
@onready var tooltip_margin: MarginContainer = $tooltipMargin
@export_category("Showable tooltips")
@export var tooltip_array: Array[Label]
@onready var tool_tip_dissapear_timer: Timer = $Tooltip/ToolTipDissapearTimer
@onready var player = Helper.getFirstInScene("player")

# hides the tooltip on ui load
func _ready() -> void:
	tooltip_margin.visible = false

func showToolTip(node_pattern:String):
	for tip:Label in tooltip_array:
		if tip.name == node_pattern:
			tip.visible = true

func hideToolTip(node_pattern:String):
	for tip:Label in tooltip_array:
		if tip.name == node_pattern:
			tip.visible = false

func setToolTipText(node_pattern:String, text:String):
	for tip:Label in tooltip_array:
		if tip.name == node_pattern:
			tip.text = text

func getAssociatedKey(action:StringName) -> String:
	var events: Array = InputMap.action_get_events(action)
	for ev in events:
		if ev is InputEventKey:
			# Prefer a human readable string from the event (works in both Godot 3/4)
			var s = ev.as_text()
			# Strip any leading "Key: " if present
			s = s.replace("Key: ", "").replace("KEY: ", "")
			# Remove the "(physical)" marker and any surrounding whitespace
			s = s.replace(" (Physical)", "")
			return s + " "
		elif ev is InputEventMouseButton:
			match ev.button_index:
				1:
					return "LMB"
				2:
					return "RMB"
				3:
					return "MMB"
				4:
					return "X1"
				5:
					return "X2"
			# fallback for other mouse buttons
			return "Mouse " + str(ev.button_index)
	return "Unassigned"

# the jump tooltip show area
func _on_area_3d_body_entered(body: Player) -> void:
	tooltip_margin.visible = true
	var associated_key = getAssociatedKey("jump")
	setToolTipText("KEY", associated_key)
	setToolTipText("ACTION", "jump.")

# the jump tooltip hide area
func _on_area_3d_2_body_entered(body: Player) -> void:
	tooltip_margin.visible = false


func _on_dash_tooltip_show_body_entered(body: Player) -> void:
	var checkpoint:Marker3D = Helper.getCheckPoint()
	checkpoint.global_position = Helper.getFirstInScene("checkpointPos1").global_position
	tooltip_margin.visible = true
	var associated_key = getAssociatedKey("dash")
	setToolTipText("KEY", associated_key)
	setToolTipText("ACTION", "dash.")
	body.player_dash_input_enabled = true


func _on_dash_tooltip_hide_body_entered(body: Player) -> void:
	var associated_key = getAssociatedKey("Slide | Slam")
	setToolTipText("KEY", associated_key)
	setToolTipText("ACTION", "slam while in the air.")
	body.player_slide_slam_input_enabled = true


func _on_slam_tooltip_hide_body_entered(body: Player) -> void:
	tooltip_margin.visible = false


func _on_slide_tooltip_show_body_entered(body: Player) -> void:
	var checkpoint:Marker3D = Helper.getCheckPoint()
	checkpoint.global_position = Helper.getFirstInScene("checkpointPos2").global_position
	tooltip_margin.visible = true
	var associated_key = getAssociatedKey("Slide | Slam")
	setToolTipText("KEY", associated_key)
	setToolTipText("ACTION", "slide long distances.")


func _on_slide_tooltip_hide_body_entered(body: Player) -> void:
	tooltip_margin.visible= false
