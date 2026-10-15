# --- License
# File: /client/src/userinterface/client_edit_mode/desktop/scripts/popup_selection.gd
# Project: OpenMinerva
# Created Date: 30 June 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Node

signal entry_clicked(name: String)

@onready var _button_container = get_node("MarginContainer/VBoxContainer")

var _entries = []

func _ready() -> void:
	for child in _button_container.get_children():
		_add_entry(child)
	return

func _add_entry(button: Node) -> void:

	button.clicked.connect(_on_button_clicked.bind(button))

	_entries.append(button)
	return

func _on_button_clicked(button: Node) -> void:
	entry_clicked.emit(button.label)
	return
