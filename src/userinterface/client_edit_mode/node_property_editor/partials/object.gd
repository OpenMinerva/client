# --- License
# File: /client/src/userinterface/client_edit_mode/node_property_editor/partials/object.gd
# Project: OpenMinerva
# Created Date: 15 July 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Control

signal value_changed(new_value: Object)

@export var property_name: String = ""
# @export var value: Object

@onready var _label = get_node("VBoxContainer/Label")

func _ready() -> void:
	_label.text = property_name
	return

func set_value(new_value: Object) -> void:
	# FIXME: Not sure what to do here.
	return

func set_label(new_label: String) -> void:
	_label.text = new_label
	property_name = new_label
	return
