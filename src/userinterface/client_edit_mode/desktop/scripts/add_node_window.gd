# --- License
# File: /client/src/userinterface/client_edit_mode/desktop/scripts/add_node_window.gd
# Project: OpenMinerva
# Created Date: 10 June 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends "moveable_window.gd"

@onready var _list_container = get_node("BackgroundColor/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer")
@onready var _button_template = preload("res://userinterface/dash/partials/generic_button.tscn")

var parent_node_id: int = 0

func _ready() -> void:
	_build_content()

	_node_window_title.text = window_name

	_button_close.clicked.connect(_close)

	gui_input.connect(_on_input)
	gui_input.connect(_on_input)
	return

func _build_content() -> void:
	var valid_options = NSB.get_schema().keys()

	for node in valid_options:
		var _schema_listing = NSB.get_entry(node)

		if _schema_listing.hidden == true:
			# This is not available for spawning.
			continue

		var _button = _button_template.instantiate()

		_list_container.add_child(_button)

		_button.clicked.connect(_node_selected.bind(node))

		_button.custom_minimum_size = Vector2(0, 25)
		_button.set_label(_schema_listing.pretty_name)
		_button.set_icon(_schema_listing.icon)
	return

func _node_selected(node_db_index) -> void:
	selection.emit(node_db_index, parent_node_id)
	return

func _close() -> void:
	visible = false
	return

func _on_input(event) -> void:
	if event is InputEventMouseButton:
		_mouse_click(event)
		return

	if event is InputEventMouseMotion:
		_mouse_drag(event)
		return

	return

func _mouse_drag(_event) -> void:
	if _is_dragging:
		var _game_size: Vector2 = DisplayServer.window_get_size()
		var _target_position = get_global_mouse_position() - _drag_offset
		var _is_out_of_bounds = _target_position.x < 0 || _target_position.y < 0 || _target_position.x >= _game_size.x - size.x || _target_position.y >= _game_size.y - size.y

		if _is_out_of_bounds == false:
			global_position = _target_position
	return

func _mouse_click(event) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.pressed:
		_is_dragging = true
		_drag_offset = get_global_mouse_position() - global_position
	else:
		_is_dragging = false
	return

func _on_item_activated(index: int) -> void:
	var tree_node = get_node("PanelContainer/ItemList")
	var item_text = tree_node.get_item_text(index)
	var item_type = NSB.get_entry(item_text)

	var parent_node = get_meta("selected_node")
	if parent_node == null:
		GlobalLogger.log("Tried to add a child to an invalid node.", Enum.LogLevel.WARNING)
		return

	selection.emit(item_type, int(parent_node.name))
	return
