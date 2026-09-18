# --- License
# File: /client/src/userinterface/client_edit_mode/node_property_editor/partials/Object.gd
# Project: OpenMinerva
# Created Date: 18 September 2026
# Copyright (c) 2026 OpenMinerva Contributors
# License: MIT License
# --- License
extends Control

signal value_changed(new_value)

@export var property_name: String = ""
@export var valid_classes: PackedStringArray = []
@export var _resource: Resource
@export var node_id: int = -1

@onready var _label = get_node("VBoxContainer/Label")
@onready var _edit_object = get_node("VBoxContainer/HBoxContainer/Edit")
@onready var _change_object = get_node("VBoxContainer/HBoxContainer/Change")


func _ready() -> void:
	_label.text = property_name
	_change_object.clicked.connect(_on_button_clicked)
	_edit_object.clicked.connect(_on_edit_object_clicked)
	return


func set_hint_string(string: String) -> void:
	if string.is_empty() == true:
		return

	valid_classes = string.split(",", false)
	return


func set_resource(resource: Resource) -> void:
	_resource = resource
	return


func set_value(_new_value) -> void:
	# No op.
	return


func set_label(new_label: String) -> void:
	_label.text = new_label
	property_name = new_label
	return


func _on_value_changed(new_value: int) -> void:
	value_changed.emit(new_value)


func _on_button_clicked() -> void:
	Events.cem_open_rem_window.emit(node_id, valid_classes)
	return


func _on_edit_object_clicked() -> void:
	Events.cem_open_rem_edit_window.emit(node_id, _resource)
	return
