# --- License
# File: /client/src/userinterface/client_edit_mode/node_property_editor/partials/bool.gd
# Project: OpenMinerva
# Created Date: 15 July 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Control

signal value_changed(new_value: bool)

@export var property_name: String = ""
@export var value: bool

@onready var _label = get_node("VBoxContainer/Label")
@onready var _bool = get_node("VBoxContainer/CheckBox")

func _ready() -> void:
	_label.text = property_name
	_bool.toggled.connect(_on_value_changed)
	return

func set_value(new_value: bool) -> void:
	value = new_value
	_bool.button_pressed = new_value
	return

func set_label(new_label: String) -> void:
	_label.text = new_label
	property_name = new_label
	return

func _on_value_changed(new_value: bool) -> void:
	value_changed.emit(new_value)
