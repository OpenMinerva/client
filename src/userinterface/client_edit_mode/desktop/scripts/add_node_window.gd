# --- License
# File: /client/src/userinterface/client_edit_mode/desktop/scripts/add_node_window.gd
# Project: OpenMinerva
# Created Date: 10 June 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Node

signal selection(type: int, parent: int)


func _ready() -> void:
	var valid_options = NSB.get_valid()
	var tree_node = get_node("PanelContainer/ItemList")
	tree_node.item_activated.connect(_on_item_activated)

	for node in valid_options:
		var schema_index = NSB.get_node_index(node)
		var schema_listing = NSB.get_formatted(schema_index)
		var _item = tree_node.add_item(schema_listing.pretty_name, schema_listing.icon)
	return

func _on_item_activated(index: int) -> void:
	var tree_node = get_node("PanelContainer/ItemList")
	var item_text = tree_node.get_item_text(index)
	var item_type = NSB.get_node_index(item_text)

	var parent_node = get_meta("selected_node")
	if parent_node == null:
		GlobalLogger.log("Tried to add a child to an invalid node.", Enum.LogLevel.WARNING)
		return

	selection.emit(item_type, int(parent_node.name))
	return
