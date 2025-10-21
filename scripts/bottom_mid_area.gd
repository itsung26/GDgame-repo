extends Control
@onready var tooltip: Panel = $Tooltip
@export_category("Showable tooltips")
@export var tooltip_array: Array[Label]
@onready var tool_tip_dissapear_timer: Timer = $Tooltip/ToolTipDissapearTimer

# sets the text of every tooltip to the corresponding key when the ui is loaded
func _ready() -> void:
	var events = InputMap.get_actions()
	setToolTipText("JumpToolTip", "Press " + getAssociatedKey("jump") + "to jump.")
	

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

func getAssociatedAction(key:InputEvent):
	pass

func getAssociatedKey(action:StringName) -> String:
	var events: Array = InputMap.action_get_events(action)
	for ev in events:
		if ev is InputEventKey:
			# Prefer a human readable string from the event (works in both Godot 3/4)
			# as_text() returns a concise representation like "Key: W" or "Key: Space".
			var s = ev.as_text()
			# Strip any leading "Key: " if present
			s = s.replace("Key: ", "").replace("KEY: ", "")
			return s
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
	tooltip.visible = true
	showToolTip("JumpToolTip")

# the jump tooltip hide area
func _on_area_3d_2_body_entered(body: Player) -> void:
	tooltip.visible = false
	hideToolTip("JumpToolTip")
