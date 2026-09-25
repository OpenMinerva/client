# --- License
# File: /client/src/userinterface/dash/scripts/resource_editor_dialog.gd
# Project: OpenMinerva
# Created Date: 18 September 2026
# Copyright (c) 2026 OpenMinerva Contributors
# License: MIT License
# --- License
extends "res://userinterface/client_edit_mode/desktop/scripts/movable_window.gd"

const icon_dir: String = "res://resources/icons/godot/"

var partials: Dictionary = { }
var _resource: Resource

@onready var scene_m: Node = get_tree().root.find_child("AppSceneManager", true, false)
@onready var spawnable_m: Node
@onready var dashboard: Node = get_tree().root.find_child("Dashboard", true, false)
@onready var listing_container: Node = get_node("%GRE_ResourceProperties")


func _ready() -> void:
	super._ready()
	closed.connect(func(): close_window(false))
	update_ui()

	Events.cem_open_rem_edit_window.connect(show_window)
	return


func show_window(resource: Resource) -> void:
	update_ui()
	super._open()
	visible = true

	spawnable_m = scene_m.get_master_scene(scene_m.active_session).get_node("SpawnableManager")

	_resource = resource

	_clear_window()
	_populate_window()
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


func _populate_window() -> void:
	if _resource == null:
		GlobalLogger.log("No resource present.", Enum.LogLevel.WARNING)
		return

	var _list = _resource.get_property_list()
	for _item in _list:
		var _partial = _get_partial(type_string(_item.type))

		if _partial == null:
			continue

		listing_container.add_child(_partial)
		_partial.set_label(_item.name)
		_partial.set_value(_resource[_item.name])

		if type_string(_item.type) == "Object":
			_partial.set_hint_string(_item.hint_string)

			_partial.set_resource(_resource[_item.name], _item.name)

		_partial.value_changed.connect(_partial_value_changed.bind(_item.name))
	return


func _partial_value_changed(value: Variant, property: String) -> void:
	spawnable_m.set_property_on_resource(int(_resource.get_name()), property, value)
	return


func _get_partial(type: String) -> Node:
	if partials.keys().has(type):
		return partials[type].instantiate()

	var _new_partial = load("res://userinterface/client_edit_mode/node_property_editor/partials/%s.tscn" % type)
	if _new_partial == null:
		GlobalLogger.log("Could not find partial for type '%s'" % type, Enum.LogLevel.WARNING)
		return null

	partials[type] = _new_partial
	return partials[type].instantiate()
