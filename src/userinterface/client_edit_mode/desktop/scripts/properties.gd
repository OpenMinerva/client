# --- License
# File: /client/src/userinterface/client_edit_mode/desktop/scripts/properties.gd
# Project: OpenMinerva
# Created Date: 15 July 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends MarginContainer

const _dev_basic_props = ["position", "rotation", "scale", "visible"]
const _dev_whitelist_properties = ["mesh"]
var _node: Node

@onready var _dev_transform_container: Node = get_node("VBoxContainer/Container/ScrollContainer/MarginContainer/VBoxContainer/FoldableContainer/VBoxContainer")
@onready var _dev_property_container: Node = get_node("VBoxContainer/Container/ScrollContainer/MarginContainer/VBoxContainer")

var partials: Dictionary = {}

func _ready() -> void:
	_dev_property_container.get_node("Visible").value_changed.connect(func (new_value): _property_changed("visible", new_value))
	_dev_transform_container.get_node("Position").value_changed.connect(func (new_value): _property_changed("position", new_value))
	_dev_transform_container.get_node("Rotation").value_changed.connect(func (new_value): _property_changed("rotation_degrees", new_value))
	_dev_transform_container.get_node("Scale").value_changed.connect(func (new_value): _property_changed("scale", new_value))
	return

func get_node_properties(node: Node) -> void:
	_node = node
	_clear_node_properties()
	var properties = node.get_property_list()

	for prop in properties:
		if _dev_whitelist_properties.has(prop.name) == false:
			continue

		var _partial = _get_partial("%s" % type_string(prop.type))
		if _partial == null:
			print("Property: %s" % prop.name)
			print("Type: %s" % type_string(prop.type))
			print("Class: %s" % prop.class_name)
			print("Hint: %s" % prop.hint)
			print("Hint String: %s" % prop.hint_string)
			print("Value: %s" % node.get(prop.name))
			print("---")
			continue

		_dev_property_container.add_child(_partial)
		_partial.set_label(prop.name.capitalize())
		_partial.set_value(node.get(prop.name))
		_partial.value_changed.connect(func (new_value): _property_changed(prop.name, new_value))


	# Display the values
	update_node_properties(node)
	return

func _clear_node_properties() -> void:
	var _child_number: int = 0
	for child in _dev_property_container.get_children():
		if _child_number <= 1:
			_child_number = _child_number + 1
			continue
		child.queue_free()
	return

func update_node_properties(node: Node) -> void:
	_dev_property_container.get_node("Visible").set_value(node.get("visible"))
	_dev_transform_container.get_node("Position").set_value(node.get("position"))
	_dev_transform_container.get_node("Rotation").set_value(node.get("rotation_degrees"))
	_dev_transform_container.get_node("Scale").set_value(node.get("scale"))
	return

func _property_changed(property_name: String, property_value: Variant) -> void:
	# TODO: Network change
	_node.set(property_name, property_value)
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
