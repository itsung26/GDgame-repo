class_name StaminaBar
extends Control
## A segmented stamina display made of three [ProgressBar]s, but behaving like a single continuous bar.
##
## - The logical range of this bar is [0, max_value].
## - The range is evenly split across three child [ProgressBar]s.
## - Each segment visually represents one third of the total range.
## - The underlying [ProgressBar].min_value is always 0.0 and is not exposed as an exported property.

@onready var stamina_bar_1: ProgressBar = %StaminaBar1
@onready var stamina_bar_2: ProgressBar = %StaminaBar2
@onready var stamina_bar_3: ProgressBar = %StaminaBar3

@export var ready_color:Color = Color(0.0, 0.737, 1.0)
@export var flash_color:Color = Color(0.0, 0.737, 1.0)
@export var max_value:float = 300.0:
	set = set_max_value
@export var progress:float = 0.0:
	set = setProgress


func _ready() -> void:
	# Ensure progress is clamped into the valid range on startup.
	setProgress(clampf(progress, 0.0, max_value))
	_calculateSubBars()


func setProgress(new_value:float) -> void:
	# Set the logical stamina value and update the visual segments.
	progress = clampf(new_value, 0.0, max_value)
	_calculateSubBars()


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


func _process(delta: float) -> void:
	return
	Debug.log(progress)
