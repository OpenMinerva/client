# --- License
# File: /client/src/userinterface/client_edit_mode/node_property_editor/partials/int.gd
# Project: OpenMinerva
# Created Date: 16 July 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Control

signal value_changed(new_value: bool)

@export var property_name: String = ""
@export var value: int

@onready var _label = get_node("VBoxContainer/Label")
@onready var _spinbox = get_node("VBoxContainer/SpinBox")

func _ready() -> void:
	_label.text = property_name
	_spinbox.spinbox_value_changed.connect(_on_value_changed)
	return

func set_value(new_value: int) -> void:
	value = new_value
	_spinbox.set_value(new_value)
	return

func set_label(new_label: String) -> void:
	_label.text = new_label
	property_name = new_label
	return

func _on_value_changed(new_value: int) -> void:
	value_changed.emit(new_value)
