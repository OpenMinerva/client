# --- License
# File: /client/src/userinterface/client_edit_mode/node_property_editor/partials/color.gd
# Project: OpenMinerva
# Created Date: 17 July 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Control

signal value_changed(new_value: Color)

@export var property_name: String = ""
@export var value: Color

@onready var _label = get_node("VBoxContainer/Label")
@onready var _value = get_node("VBoxContainer/ColorPickerButton")

func _ready() -> void:
	_label.text = property_name
	_value.color_changed.connect(_on_value_changed)
	return

func set_value(new_value: Color) -> void:
	value = new_value
	_value.color = new_value
	return

func set_label(new_label: String) -> void:
	_label.text = new_label
	property_name = new_label
	return

func _on_value_changed(new_value: Color) -> void:
	value_changed.emit(new_value)
