class_name PauseMenu
extends Control
## Pause menu UI. Handles pause/unpause input and panel visibility.
## Panels in the "pause menu overlay" group open on top of the current panel (both stay visible).
## Other panels use replace behavior: the current panel collapses first, then the new one expands.
## Going back always collapses the top panel and pops it; the new top is expanded if it was collapsed.

@onready var player: Player = get_tree().get_first_node_in_group("players")
@onready var main_center_pause: UICollapseTweener = $CenterButtons/MainCenterPause
@onready var restart_confirm: UICollapseTweener = $CenterButtons/RestartConfirm
@onready var quit_confirm: UICollapseTweener = $CenterButtons/QuitConfirm
@onready var main_menu_confirm: UICollapseTweener = $CenterButtons/MainMenuConfirm
@onready var options_menu_main_frame: UICollapseTweener = %OptionsMenuMainFrame
@onready var gameplay_tab: Button = $"OptionsMenu/OptionsMenuMainFrame/ArtPanel/SettingsModeTab/PanelContainer/Settings Tabs/Gameplay"
@onready var display_tab: Button = $"OptionsMenu/OptionsMenuMainFrame/ArtPanel/SettingsModeTab/PanelContainer/Settings Tabs/Display"
@onready var graphics_tab: Button = $"OptionsMenu/OptionsMenuMainFrame/ArtPanel/SettingsModeTab/PanelContainer/Settings Tabs/Graphics"
@onready var settings_tabs_box: VBoxContainer = $"OptionsMenu/OptionsMenuMainFrame/ArtPanel/SettingsModeTab/PanelContainer/Settings Tabs"
@onready var game_play_settings: UICollapseTweener = $OptionsMenu/OptionsMenuMainFrame/ArtPanel/SettingsArea/GamePlaySettings
@onready var display_settings: UICollapseTweener = $OptionsMenu/OptionsMenuMainFrame/ArtPanel/SettingsArea/DisplaySettings
@onready var graphics_settings: UICollapseTweener = $OptionsMenu/OptionsMenuMainFrame/ArtPanel/SettingsArea/GraphicsSettings

signal paused
signal unpaused

@export var main_menu_scene: PackedScene
@export var log_panel_events:bool = false

## Root panel shown when the pause menu first opens (e.g. main pause buttons).
@onready var _root_panel: UICollapseTweener = main_center_pause

## Stack of visible panels: bottom = root, top = front. Overlay panels are all expanded; replace panels leave those below collapsed.
var _panel_stack: Array[UICollapseTweener] = []

## Panel to expand after the current top finishes collapsing (replace behavior). Null if none.
var _pending_show: UICollapseTweener = null

## If true, after the current top panel finishes collapsing we pop it (and close menu if stack becomes empty).
var _pending_go_back: bool = false

## When switching options tabs: submenu to push and expand after the current submenu finishes collapsing. Null if none.
var _pending_options_submenu_switch: UICollapseTweener = null

## Used only by _process debug: was mouse left button pressed last frame.
var _debug_mouse_was_pressed: bool = false

## The active tab in options. There must always be only one active tab at a time.
var _active_option_tab:Button

## The active options submenu opened by it's respective _active_option_tab.
## For example, gameplay_tab opens game_play_settings.
var _active_options_sub_menu:UICollapseTweener

## Contains all of the buttons (tabs) that open different menus in the options
## such as gameplay, display, etc...
var _options_tabs:Array[Button] = []


# temporary. for debugging.
func _process(delta: float) -> void:
	Debug.log(_panel_stack)
	var mouse_pressed: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var just_pressed: bool = mouse_pressed and not _debug_mouse_was_pressed
	_debug_mouse_was_pressed = mouse_pressed
	if just_pressed and visible:
		var pos: Vector2 = get_global_mouse_position()
		for panel in _get_all_panels():
			if panel.visible and panel.get_global_rect().has_point(pos):
				if log_panel_events:
					Debug.log("Clicked panel: %s" % panel.name)
				break


func _ready() -> void:
	visible = false
	# initialize option tab menu refrences
	_options_tabs.append_array(settings_tabs_box.get_children())
	# one tab must always be selected. This will always be the topmost tab, and thus
	# the frontmost element in  _options_tabs
	_switch_options_submenu_to(_options_tabs.front())
	
	_connect_panel_transition_signals()
	# Start with menu closed (no panels on stack).
	_panel_stack.clear()
	for panel in _get_all_panels():
		panel.instantCollapseVertical()
	_update_panel_mouse_filters()


func _connect_panel_transition_signals() -> void:
	for panel in _get_all_panels():
		if not panel.finished_transition.is_connected(_on_panel_finished_transition.bind(panel)):
			panel.finished_transition.connect(_on_panel_finished_transition.bind(panel))


## Returns all pause menu panels from the "pause menu panels" group (must be UICollapseTweener).
func _get_all_panels() -> Array[UICollapseTweener]:
	var panels: Array[UICollapseTweener] = []
	for node in get_tree().get_nodes_in_group("pause menu panels"):
		if node is UICollapseTweener:
			panels.append(node)
	return panels


## Makes only the topmost panel in the stack receive mouse input; panels below (and all their descendants) get MOUSE_FILTER_IGNORE.
func _update_panel_mouse_filters() -> void:
	var top: UICollapseTweener = _panel_stack[-1] if not _panel_stack.is_empty() else null
	for panel in _get_all_panels():
		var accept_input: bool = (panel == top)
		_set_mouse_filter_recursive(panel, Control.MOUSE_FILTER_STOP if accept_input else Control.MOUSE_FILTER_IGNORE)
	_update_options_tab_mouse_filters()


## Ensures the active options tab remains non-clickable and other tabs clickable when the options panel is the top panel.
func _update_options_tab_mouse_filters() -> void:
	if _active_option_tab == null:
		return
	# Only adjust tabs while the options menu is actually visible; this keeps tab
	# behavior stable regardless of which options subpanel is currently on top.
	if not options_menu_main_frame.visible:
		return
	for tab: Button in _options_tabs:
		if tab == _active_option_tab:
			tab.button_pressed = true
			tab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			tab.button_pressed = false
			tab.mouse_filter = Control.MOUSE_FILTER_STOP


## Sets [param filter] on [param node] and every descendant that is a Control.
func _set_mouse_filter_recursive(node: Node, filter: Control.MouseFilter) -> void:
	if node is Control:
		(node as Control).mouse_filter = filter
	for child in node.get_children():
		_set_mouse_filter_recursive(child, filter)


## When a panel finishes collapsing, run the pending action: show the next panel (replace) or go back (pop).
func _on_panel_finished_transition(transition: UICollapseTweener.transitions, panel: UICollapseTweener) -> void:
	var transition_name: String = "expand" if transition == UICollapseTweener.transitions.EXPAND_VERTICAL else "collapse"
	if log_panel_events:
		Debug.log("%s finished: %s" % [panel.name, transition_name])
	if transition != UICollapseTweener.transitions.COLLAPSE_VERTICAL:
		return
	if _panel_stack.is_empty() or _panel_stack[-1] != panel:
		return

	if _pending_options_submenu_switch != null:
		var to_show: UICollapseTweener = _pending_options_submenu_switch
		_pending_options_submenu_switch = null
		_panel_stack.pop_back()
		_panel_stack.append(to_show)
		to_show.expandVertical()
		_update_panel_mouse_filters()
		return

	if _pending_show != null:
		var to_show: UICollapseTweener = _pending_show
		_pending_show = null
		_panel_stack.append(to_show)
		to_show.expandVertical()
		_update_panel_mouse_filters()
		# When the options main frame just opened, show the active options submenu so it plays its transition.
		if to_show == options_menu_main_frame and _active_options_sub_menu != null:
			request_show_panel(_active_options_sub_menu)
		return

	if _pending_go_back:
		_pending_go_back = false
		_panel_stack.pop_back()
		if _panel_stack.is_empty():
			player.pause_menu.visible = false
			unpause()
		else:
			# Only expand if the panel was collapsed (replace flow); overlay panels below stayed expanded.
			if _panel_stack[-1].collapsed:
				_panel_stack[-1].expandVertical()
		_update_panel_mouse_filters()


## Disables all tab buttons other than [param self_tab], and makes them clickable again.
func unselectOtherTabs(self_tab:Button) -> void:
	for tab:Button in _options_tabs:
		if tab != self_tab:
			tab.button_pressed = false


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if Input.is_action_just_pressed("pause"):
			if get_pause():
				if not _panel_stack.is_empty() and _panel_stack[-1].is_in_group(CAN_RESUME_FROM_GROUP):
					_resume_immediately()
				elif _panel_stack.has(options_menu_main_frame):
					request_go_back_to_main_pause()
				else:
					request_go_back()
			else:
				pause()
				open_menu()


## Closes the menu and unpauses with no animations. Clears stack and collapses all panels for next open.
func _resume_immediately() -> void:
	_pending_show = null
	_pending_go_back = false
	_pending_options_submenu_switch = null
	_panel_stack.clear()
	for panel in _get_all_panels():
		panel.instantCollapseVertical()
	_update_panel_mouse_filters()
	player.pause_menu.visible = false
	unpause()


## Opens the pause menu by showing the root panel (no transition; menu was closed).
func open_menu() -> void:
	# collapse all panels beforehand to clear any stuck panels
	for panel:UICollapseTweener in get_tree().get_nodes_in_group("pause menu panels"):
		panel.instantCollapseVertical()
	player.pause_menu.visible = true
	_panel_stack.clear()
	_panel_stack.append(_root_panel)
	_root_panel.expandVertical()
	_update_panel_mouse_filters()


## Name of the group for panels that open on top without collapsing the current panel (e.g. confirm dialogs).
const OVERLAY_GROUP := "pause menu overlay"

## Panels in this group allow resuming immediately on escape (no collapse animations). E.g. main pause menu.
const CAN_RESUME_FROM_GROUP := "can resume from panel"

## Shows a panel. Overlay (in [constant OVERLAY_GROUP]): push and expand on top. Else: collapse current, then expand [param panel].
## No-op if [param panel] is already the top. If the menu was closed, opens with root first.
func request_show_panel(panel: UICollapseTweener) -> void:
	if _panel_stack.is_empty():
		open_menu()
		_panel_stack.append(panel)
		panel.expandVertical()
		_update_panel_mouse_filters()
		return
	if _panel_stack[-1] == panel:
		return
	if _is_overlay_panel(panel):
		_panel_stack.append(panel)
		panel.expandVertical()
		_update_panel_mouse_filters()
	else:
		_pending_show = panel
		_panel_stack[-1].collapseVertical()


func _is_overlay_panel(panel: Node) -> bool:
	return panel.is_in_group(OVERLAY_GROUP)


## If currently in the options menu, closes all panels until only the main pause (root) is left and expands it.
## Use when unpause is pressed while in options so we return to the main center buttons instead of one panel at a time.
func request_go_back_to_main_pause() -> void:
	if _panel_stack.is_empty():
		return
	while _panel_stack.size() > 1:
		close_panel_immediately(_panel_stack[-1])
	if _panel_stack[0].collapsed:
		_panel_stack[0].expandVertical()
	_update_panel_mouse_filters()


## Collapses only the current top panel; when done, pops it (panels below stay visible). Closes menu if stack becomes empty.
func request_go_back() -> void:
	if _panel_stack.is_empty():
		player.pause_menu.visible = false
		unpause()
		return
	_pending_go_back = true
	_panel_stack[-1].collapseVertical()


## Immediately closes [param panel]: collapses it without animation and removes it from the active stack.
## If the stack becomes empty after removal, the pause menu is hidden and the game is unpaused.
func close_panel_immediately(panel: UICollapseTweener) -> void:
	var idx: int = _panel_stack.find(panel)
	if idx == -1:
		return
	_panel_stack.remove_at(idx)
	panel.instantCollapseVertical()
	if _panel_stack.is_empty():
		player.pause_menu.visible = false
		unpause()
	_update_panel_mouse_filters()


func pause() -> void:
	if get_tree().paused:
		return
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	paused.emit()


func unpause() -> void:
	if not get_tree().paused:
		return
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	unpaused.emit()


func get_pause() -> bool:
	return get_tree().paused
	
	
func _on_resume_pressed() -> void:
	request_go_back()
	# If we were on root, request_go_back() will collapse and then hide + unpause.
	# So we don't call unpause() again here; it's done in _on_panel_finished_transition.


func _on_options_pressed() -> void:
	request_show_panel(options_menu_main_frame)


func _on_restart_pressed() -> void:
	request_show_panel(restart_confirm)


func _on_quit_pressed() -> void:
	request_show_panel(quit_confirm)


func _on_restart_confirm_pressed() -> void:
	LoadHandler.reloadCurrentLevel()


func _on_restart_cancel_pressed() -> void:
	request_go_back()


func _on_quit_confirm_pressed() -> void:
	LoadHandler.quitGame()


func _on_quit_cancel_pressed() -> void:
	request_go_back()


func _on_main_menu_pressed() -> void:
	request_show_panel(main_menu_confirm)


func _on_main_menu_confirm_pressed() -> void:
	LoadHandler.loadNewLevel(main_menu_scene.resource_path, false, 0)


func _on_main_menu_cancel_pressed() -> void:
	request_go_back()


func _on_gameplay_toggled(toggled_on: bool) -> void:
	if toggled_on:
		_switch_options_submenu_to(gameplay_tab)


func _on_display_toggled(toggled_on: bool) -> void:
	if toggled_on:
		_switch_options_submenu_to(display_tab)


func _on_graphics_toggled(toggled_on: bool) -> void:
	if toggled_on:
		_switch_options_submenu_to(graphics_tab)


## Sets the active options tab and its submenu; if the options menu is open, shows that submenu (collapse-then-expand if another submenu was open).
func _switch_options_submenu_to(new_submenu_tab: Button) -> void:
	assert(new_submenu_tab)
	var previous_submenu: UICollapseTweener = _active_options_sub_menu

	_active_option_tab = new_submenu_tab
	unselectOtherTabs(_active_option_tab)
	_update_options_tab_mouse_filters()
	match new_submenu_tab:
		gameplay_tab:
			_active_options_sub_menu = game_play_settings
		display_tab:
			_active_options_sub_menu = display_settings
		graphics_tab:
			_active_options_sub_menu = graphics_settings

	if not _panel_stack.has(options_menu_main_frame):
		return
	if _active_options_sub_menu != null:
		if previous_submenu != null and _panel_stack.has(previous_submenu) and _panel_stack[-1] == previous_submenu:
			_pending_options_submenu_switch = _active_options_sub_menu
			previous_submenu.collapseVertical()
		else:
			request_show_panel(_active_options_sub_menu)


func _on_vsync_drop_down_item_selected(index: int) -> void:
	match index:
		0: # Disabled
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		1: # Enabled
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		2: # adaptive
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)
	
