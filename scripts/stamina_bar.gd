class_name StaminaBar
extends Control
## A segmented stamina display made of three [ProgressBar]s, but behaving like a single continuous bar.
##
## - The logical range of this bar is [0, max_value].
## - The range is evenly split across three child [ProgressBar]s.
## - Each segment visually represents one third of the total range.
## - The underlying [ProgressBar].min_value is always 0.0 and is not exposed as an exported property.
signal segment_changed(is_increase: bool)

@onready var stamina_bar_1: ProgressBar = %StaminaBar1
@onready var stamina_bar_2: ProgressBar = %StaminaBar2
@onready var stamina_bar_3: ProgressBar = %StaminaBar3

@export var flash_color:Color = Color(0.0, 0.737, 1.0)
## Duration of the flash effect in seconds.
@export var flash_duration:float = 0.25
@export var charging_color:Color = Color(0.0, 0.424, 0.58)
@export var max_value:float = 300.0:
	set = set_max_value
@export var progress:float = 0.0:
	set = setProgress

## Stores the original fill stylebox color for each bar so we can tween back to it.
var _original_fill_colors: Dictionary = {}
## Tracks the previous segment index to detect threshold crossings.
var _previous_segment_index: int = 0
var tween:Tween


func _ready() -> void:
	# initialize the tweener
	tween = create_tween()
	
	# Store original fill colors for each bar so flash can tween back to them.
	_original_fill_colors[stamina_bar_1] = stamina_bar_1.get_theme_stylebox("fill").bg_color
	_original_fill_colors[stamina_bar_2] = stamina_bar_2.get_theme_stylebox("fill").bg_color
	_original_fill_colors[stamina_bar_3] = stamina_bar_3.get_theme_stylebox("fill").bg_color
	
	# Initialize segment index based on starting progress.
	_previous_segment_index = _getSegmentIndex(progress)
	
	# Ensure progress is clamped into the valid range on startup.
	setProgress(clampf(progress, 0.0, max_value))
	_calculateSubBars()


func setProgress(new_value:float) -> void:
	var old_segment := _previous_segment_index
	
	# Set the logical stamina value and update the visual segments.
	progress = clampf(new_value, 0.0, max_value)
	_calculateSubBars()
	
	var new_segment := _getSegmentIndex(progress)
	if new_segment != old_segment:
		segment_changed.emit(new_segment > old_segment)
	
	# If we moved UP into a higher segment, flash the bar that just filled.
	if new_segment > old_segment:
		# Flash all bars that were crossed (handles cases where multiple segments fill at once).
		if old_segment < 1 and new_segment >= 1:
			_flashBar(stamina_bar_3)  # first segment filled
		if old_segment < 2 and new_segment >= 2:
			_flashBar(stamina_bar_2)  # second segment filled
		if old_segment < 3 and new_segment >= 3:
			_flashBar(stamina_bar_1)  # third segment filled
	
	_previous_segment_index = new_segment


func set_max_value(new_max:float) -> void:
	# Update the logical maximum and re-clamp progress into the new range.
	max_value = max(new_max, 0.0)
	progress = clampf(progress, 0.0, max_value)
	_calculateSubBars()


## Calculates each bar's maximum value based on the maximum value of the StaminaBar,
## and calculates their value based on the progress of the StaminaBar.
func _calculateSubBars() -> void:
	var sub_bars:Array[ProgressBar] = [stamina_bar_1, stamina_bar_2, stamina_bar_3]
	# Each segment covers an equal share of the logical range.
	var segment_max:float = max_value / 3.0

	# Configure segment ranges. min_value is always 0.0 by design.
	for bar:ProgressBar in sub_bars:
		bar.min_value = 0.0
		bar.max_value = segment_max

	# Clamp logical progress and distribute it across the three segments.
	var p:float = clampf(progress, 0.0, max_value)

	# First segment (bottom bar, stamina_bar_3): from 0 to segment_max
	stamina_bar_3.value = min(p, segment_max)

	# Second segment (middle bar, stamina_bar_2): from segment_max to 2 * segment_max
	var remaining_after_first:float = max(p - segment_max, 0.0)
	stamina_bar_2.value = min(remaining_after_first, segment_max)

	# Third segment (top bar, stamina_bar_1): from 2 * segment_max to 3 * segment_max
	var remaining_after_second:float = max(remaining_after_first - segment_max, 0.0)
	stamina_bar_1.value = min(remaining_after_second, segment_max)


## Returns the bar that the top of the overall stamina segment is currently inside.
## This is the segment that is currently being filled (or the last segment if full).
func getActiveBar() -> ProgressBar:
	var segment_max:float = max_value / 3.0
	var p:float = clampf(progress, 0.0, max_value)
	
	# Determine which segment contains the current progress.
	if p <= segment_max:
		return stamina_bar_3  # bottom bar
	elif p <= segment_max * 2.0:
		return stamina_bar_2  # middle bar
	else:
		return stamina_bar_1  # top bar


## Returns segment index (0 = none full, 1 = first full, 2 = first two full, 3 = all full).
func _getSegmentIndex(p: float) -> int:
	var segment_max := max_value / 3.0
	if p >= segment_max * 3.0:
		return 3
	elif p >= segment_max * 2.0:
		return 2
	elif p >= segment_max:
		return 1
	else:
		return 0


## Flashes the given bar's fill stylebox to flash_color, then tweens back to original.
func _flashBar(bar: ProgressBar) -> void:
	var fill_style: StyleBoxFlat = bar.get_theme_stylebox("fill")
	var original_color: Color = _original_fill_colors.get(bar, fill_style.bg_color)
	
	# Instantly set to flash color.
	fill_style.bg_color = flash_color
	
	# Tween back to original color.
	tween.stop()
	tween = create_tween()
	tween.tween_property(fill_style, "bg_color", original_color, flash_duration).set_ease(Tween.EASE_OUT)


func _on_segment_changed(is_increase: bool) -> void:
	if not is_increase:
		var active_bar:ProgressBar = getActiveBar()
		var fill_style:StyleBoxFlat = active_bar.get_theme_stylebox("fill")
		tween.stop()
		
		fill_style.bg_color = charging_color
