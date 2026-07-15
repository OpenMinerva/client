# --- License
# File: /client/src/userinterface/client_edit_mode/node_property_editor/partials/vector_3.gd
# Project: OpenMinerva
# Created Date: 15 July 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Control

signal value_changed(new_value: Vector3)

@export var property_name: String = ""
@export var value: Vector3 = Vector3(0, 0, 0)

@onready var _label = get_node("VBoxContainer/Label")
@onready var _container: HBoxContainer = get_node("VBoxContainer/HBoxContainer")

func _ready() -> void:
	_label.text = property_name

	for child in _container.get_children():
		var _name = child.name
		child.spinbox_value_changed.connect(func (new_value): _child_value_changed(_name, new_value))
	return

func set_value(new_value: Vector3) -> void:
	value = new_value

	for child in _container.get_children():
		var _node_name: String = child.name
		_container.get_node(_node_name).value = value[_node_name.to_lower()]
	return

func set_label(new_label: String) -> void:
	_label.text = new_label
	property_name = new_label
	return

func _child_value_changed(type: String, new_value: float) -> void:
	type = type.to_lower()
	value[type] = new_value
	value_changed.emit(value)
	return
