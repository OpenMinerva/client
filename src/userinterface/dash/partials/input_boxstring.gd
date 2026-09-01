# --- License
# File: /client/src/userinterface/dash/partials/input_boxstring.gd
# Project: OpenMinerva
# Created Date: 3 August 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Control

@export var display_text: String = "Default Text"

@onready var label_node = $PanelContainer/MarginContainer/HBoxContainer/Label
@onready var lineedit_node = $PanelContainer/MarginContainer/HBoxContainer/MarginContainer/LineEdit


func _ready():
	label_node.text = display_text
	lineedit_node.placeholder_text = display_text


func get_value() -> String:
	return lineedit_node.text
