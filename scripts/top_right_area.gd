@tool
extends Control

# the big style letters at the top
@onready var main_score_label_d: Label = $StyleBox/SubViewport/Panel/MainScoreLabelD
@onready var main_score_label_c: Label = $StyleBox/SubViewport/Panel/MainScoreLabelC
@onready var main_score_label_b: Label = $StyleBox/SubViewport/Panel/MainScoreLabelB
@onready var main_score_label_s: Label = $StyleBox/SubViewport/Panel/MainScoreLabelS
@onready var main_score_label_maxed: Label = $StyleBox/SubViewport/Panel/MainScoreLabelMAXED

## The style text
# +10 SP (generic kills) green
@onready var style_point_green: Label = $StyleBox/SubViewport/Panel/BoxContainer/StylePointGreen
# +12 SP (generic mobility kills) blue
@onready var style_point_orange: Label = $StyleBox/SubViewport/Panel/BoxContainer/Node/StylePointOrange
# +20 SP (advanced mobility kills) orange

# +25 SP (extreme mobility kills) red

# +25 SP (unique weapon kills) purple

# +50 SP (extremely rare/extremity kills) black
