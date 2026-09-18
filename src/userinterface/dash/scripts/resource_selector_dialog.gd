# --- License
# File: /client/src/userinterface/dash/scripts/resource_selector_dialog.gd
# Project: OpenMinerva
# Created Date: 18 September 2026
# Copyright (c) 2026 OpenMinerva Contributors
# License: MIT License
# --- License
extends "res://userinterface/client_edit_mode/desktop/scripts/movable_window.gd"

const icon_dir: String = "res://resources/icons/godot/"

var _template_button = preload("res://userinterface/dash/partials/generic_button.tscn")
var _node_db_entry: Dictionary

@onready var scene_m: Node = get_tree().root.find_child("AppSceneManager", true, false)
@onready var spawnable_m: Node
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

	spawnable_m = scene_m.get_master_scene(scene_m.active_session).get_node("SpawnableManager")

	_node_db_entry = spawnable_m.get_by_id(target_node_id)

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

		_new_button.clicked.connect(_resource_button_clicked.bind(_valid_option))
	return


func _resource_button_clicked(resource_class: String) -> void:
	var _resource: Resource = await spawnable_m.create_asset(resource_class, [])
	spawnable_m.set_resource(_node_db_entry.id, "mesh", int(_resource.get_name()))
	return
