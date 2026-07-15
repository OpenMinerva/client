# --- License
# File: /client/src/userinterface/client_edit_mode/node_property_editor/partials/object.gd
# Project: OpenMinerva
# Created Date: 15 July 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends FoldableContainer

# signal value_changed(new_value: Object)

func _ready() -> void:
	return

func set_label(new_label: String) -> void:
	title = new_label
	return
