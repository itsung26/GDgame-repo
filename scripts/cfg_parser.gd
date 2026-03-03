extends Node
## Parses and persists settings to a ConfigFile (e.g. user://settings.cfg).
## Loads on startup and holds values in memory; UI and game code read/write via get/set methods.
## Supports sections such as "gameplay", "graphics", and "display". Call [method save] to write changes to disk.

const DEFAULT_PATH := "user://settings.cfg"
## Bundled default config (graphics, etc.). Used when user config does not exist yet.
const BUNDLED_DEFAULTS_PATH := "res://default_settings.cfg"

var _config: ConfigFile


func _ready() -> void:
	_ensure_user_data_path_ready()
	load_config()


## Ensures the user data directory is accessible; logs the resolved path for verification.
func _ensure_user_data_path_ready() -> void:
	var resolved: String = ProjectSettings.globalize_path("user://")
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		push_warning("CfgParser: user data path not accessible: %s" % resolved)
		return
	print("CfgParser: user data path = ", resolved)


## Loads settings from [param path]. If the file does not exist, loads from [constant BUNDLED_DEFAULTS_PATH] and saves to [param path].
func load_config(path: String = DEFAULT_PATH) -> void:
	_config = ConfigFile.new()
	var err: Error = _config.load(path)
	if err == OK:
		return
	if err == ERR_FILE_NOT_FOUND:
		var default_cfg: ConfigFile = ConfigFile.new()
		var load_default: Error = default_cfg.load(BUNDLED_DEFAULTS_PATH)
		if load_default == OK:
			_config = default_cfg
			var save_err: Error = _config.save(path)
			if save_err != OK:
				push_warning("CfgParser: could not write initial config to %s (code %d)" % [path, save_err])
		else:
			push_warning("CfgParser: bundled defaults not found at %s (code %d)" % [BUNDLED_DEFAULTS_PATH, load_default])
	else:
		push_warning("CfgParser: failed to load %s (code %d)" % [path, err])


## Writes current in-memory settings to [param path]. Returns [constant OK] on success.
func save(path: String = DEFAULT_PATH) -> Error:
	return _config.save(path)


## Returns the value for [param section] and [param key], or [param default] if missing.
func get_value(section: String, key: String, default: Variant = null) -> Variant:
	if not _config.has_section_key(section, key):
		return default
	return _config.get_value(section, key, default)


## Sets [param value] for [param section] and [param key]. Does not write to disk until [method save] is called.
func set_value(section: String, key: String, value: Variant) -> void:
	_config.set_value(section, key, value)


## Returns true if [param section] has [param key].
func has_key(section: String, key: String) -> bool:
	return _config.has_section_key(section, key)


## Returns the value as a bool, or [param default] if missing or not a bool.
func get_bool(section: String, key: String, default: bool = false) -> bool:
	return bool(get_value(section, key, default))


## Returns the value as an int, or [param default] if missing or not a number.
func get_int(section: String, key: String, default: int = 0) -> int:
	return int(get_value(section, key, default))


## Returns the value as a float, or [param default] if missing or not a number.
func get_float(section: String, key: String, default: float = 0.0) -> float:
	return float(get_value(section, key, default))


## Returns the value as a String, or [param default] if missing.
func get_string(section: String, key: String, default: String = "") -> String:
	return str(get_value(section, key, default))


## Sets a bool value for [param section] and [param key].
func set_bool(section: String, key: String, value: bool) -> void:
	set_value(section, key, value)


## Sets an int value for [param section] and [param key].
func set_int(section: String, key: String, value: int) -> void:
	set_value(section, key, value)


## Sets a float value for [param section] and [param key].
func set_float(section: String, key: String, value: float) -> void:
	set_value(section, key, value)


## Sets a String value for [param section] and [param key].
func set_string(section: String, key: String, value: String) -> void:
	set_value(section, key, value)
