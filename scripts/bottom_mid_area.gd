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

func getAssociatedKey(action:StringName):
	return InputMap.action_get_events(action)

func _on_area_3d_body_entered(body: Player) -> void:
	tooltip.visible = true
	showToolTip("JumpToolTip")
