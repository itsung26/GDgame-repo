class_name MenuSetOnStartup
extends Node
## Sets the owner's value the one specified in default_settings.cfg.
## The section and key to look under in the cfg have to be manually specified.
## The values of the dropdown have to have the same name as the value in default_Settings.cfg.


@export var cfg_section:String
@export var cfg_key:String

func _ready() -> void:
	if owner is OptionButton:
		var default_value = CfgParser.get_string(cfg_section, cfg_key)

## Returns an array of strings of the elements pickable in the dropdown.
func getDropDownElements(dropdown:OptionButton) -> Array[String]:
	var elements: Array[String] = []
	var count: int = dropdown.item_count
	for i in count:
		elements.append(dropdown.get_item_text(i))
	return elements
