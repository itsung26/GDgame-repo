class_name SettingsDropdown
extends OptionButton


## Returns the index of the dropdown's item that matches the corresponding setting in the user's cfg.
func getUserSettingsIndex(cfg_section:String, cfg_key:String) -> int:
	var user_setting:String = CfgParser.get_string(cfg_section, cfg_key).to_lower()
	for i in item_count:
		var item_name:String = get_item_text(i).to_lower()
		if item_name == user_setting:
			return i
	return -1
