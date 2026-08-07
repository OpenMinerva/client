# --- License
# File: /client/src/userinterface/client_edit_mode/desktop/scripts/moveable_window.gd
# Project: OpenMinerva
# Created Date: 17 July 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Control

signal selection(type: String, parent: int)
signal closed()

@export var window_name: String = "Window Name"

var _is_dragging: bool = false
var _drag_offset: Vector2

@onready var _button_close = get_node("BackgroundColor/MarginContainer/VBoxContainer/HBoxContainer/GenericButton")
@onready var _node_window_title = get_node("BackgroundColor/MarginContainer/VBoxContainer/HBoxContainer/Label")


func _ready() -> void:
	_node_window_title.text = window_name
	_button_close.clicked.connect(_close)

	gui_input.connect(_on_input)
	return


func _close() -> void:
	visible = false
	closed.emit()
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
