# --- License
# File: /client/src/userinterface/client_edit_mode/node_property_editor/partials/spin_box.gd
# Project: OpenMinerva
# Created Date: 15 July 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends SpinBox

signal spinbox_value_changed(value: float)

@export var max_decimals: int = 4
@export var is_int: bool = false

func _ready() -> void:
	if is_int == true:
		max_decimals = 0
		step = 1

	value_changed.connect(_on_value_changed)
	get_line_edit().focus_entered.connect(_on_focus_entered)
	get_line_edit().focus_exited.connect(_on_focus_exited)

	get_line_edit().text = _format_value(value)
	return

func _on_value_changed(new_value: float) -> void:
	get_line_edit().text = _format_value(new_value)
	spinbox_value_changed.emit(new_value)

func _on_focus_entered() -> void:
	get_line_edit().text = String.num(value, max_decimals)

func _on_focus_exited() -> void:
	get_line_edit().text = _format_value(value)

func _format_value(v: float) -> String:
	return (prefix + String.num(v, max_decimals) + suffix).trim_suffix(".0")
