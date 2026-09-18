# --- License
# File: /client/src/userinterface/dash/scripts/resource_editor_dialog.gd
# Project: OpenMinerva
# Created Date: 18 September 2026
# Copyright (c) 2026 OpenMinerva Contributors
# License: MIT License
# --- License
extends "res://userinterface/client_edit_mode/desktop/scripts/movable_window.gd"

const icon_dir: String = "res://resources/icons/godot/"

@export var base: Enum.BaseLevel = Enum.BaseLevel.GRID

var _template_button = preload("res://userinterface/dash/partials/generic_button.tscn")

@onready var scene_m: Node = get_tree().root.find_child("AppSceneManager", true, false)
@onready var dashboard: Node = get_tree().root.find_child("Dashboard", true, false)
@onready var listing_container: Node = get_node("%GRE_ValidList")


func _ready() -> void:
	super._ready()
	closed.connect(func(): close_window(false))
	update_ui()

	Events.cem_open_rem_window.connect(show_window)
	return


func show_window(target_node_id: int, property_hints: PackedStringArray) -> void:
	update_ui()
	super._open()
	visible = true

	_clear_window()
	_populate_window(property_hints)
	return


func close_window(call_super: bool = true) -> void:
	if call_super == true:
		super._close()

	_clear_window()
	return


func update_ui() -> void:
	return


func _clear_window() -> void:
	for _child in listing_container.get_children():
		_child.queue_free()

	return


func _populate_window(property_hints: PackedStringArray) -> void:
	var _inherit = ClassDB.get_inheriters_from_class(property_hints[0])
	for _valid_option in _inherit:
		var _icon: Texture2D = load(icon_dir + '/' + _valid_option + '.svg')
		if _icon == null:
			_icon = load(icon_dir + '/Error.svg')
		var _new_button = _template_button.instantiate()
		listing_container.add_child(_new_button)
		_new_button.set_label(_valid_option)
		_new_button.set_icon(_icon)
	return
