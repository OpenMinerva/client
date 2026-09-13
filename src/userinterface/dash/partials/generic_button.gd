# --- License
# File: /client/src/userinterface/dash/partials/generic_button.gd
# Project: OpenMinerva
# Created Date: 30 June 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Control

signal clicked
signal double_clicked

# Double clicking functionality
const DOUBLE_CLICK_TIME: float = 0.25

@export var toggle: bool = false
@export var default_state: bool = false
@export var label: String = ""
@export var icon: Texture2D = null
@export var only_icon: bool = false

var _click_count: int = 0
var _last_click_time: float = 0

@onready var _node_button: Button = get_node("Button")
@onready var _node_label: Label = get_node("Button/MarginContainer/VBoxContainer/Label")
@onready var _node_icon: TextureRect = get_node("Button/MarginContainer/VBoxContainer/TextureRect")


func _ready() -> void:
	_node_button.toggle_mode = toggle
	_node_button.button_pressed = default_state
	_node_button.pressed.connect(_on_single_click)
	_node_label.text = label
	_node_icon.texture = icon

	if only_icon == true:
		_node_label.queue_free()
		_node_icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_node_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		return

	return


func set_label(new_label: String) -> void:
	label = new_label
	_node_label.text = new_label
	return


func set_toggle(state: bool = false) -> void:
	_node_button.toggle_mode = state
	return


func set_icon(new_icon: Texture2D) -> void:
	icon = new_icon
	_node_icon.texture = new_icon
	return


func _on_single_click() -> void:
	var now = Time.get_ticks_msec() / 1000.0

	if now - _last_click_time < DOUBLE_CLICK_TIME:
		_click_count += 1
		if _click_count >= 2:
			double_clicked.emit()
			_click_count = 0
		else:
			clicked.emit()
	else:
		_click_count = 1
		clicked.emit()

	_last_click_time = now
