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
const _dev_whitelist_mesh_properties = ["material", "flip_faces", "add_uv2", "uv2_padding", "size", "subdivide_width", "subdivide_height", "subdivide_depth", ]

var _node: Node

# TODO: Add protections from making changes on null nodes (invalid nodes)

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
	_clear_node_properties()
	_node = node
	var _property_tree: Dictionary = _get_property_tree(node)

	var _property_categories: Array = _property_tree.keys()
	_property_categories.reverse()

	for _category in _property_categories:
		# Create the container node.
		var _category_node = _get_partial("FoldableContainer")
		_dev_property_container.add_child(_category_node)
		_category_node.set_label(_category)

		# Add all of the sub properties.
		for _prop in _property_tree[_category]:
			var _sub_property = _get_partial("%s" % type_string(_prop.type))

			if _sub_property == null:
				continue

			_category_node.add_child(_sub_property)
			_sub_property.set_value(node.get(_prop.name))
			_sub_property.set_label(_prop.name.capitalize())
			_sub_property.value_changed.connect(func (new_value): _property_changed(_prop.name, new_value))
			break

	update_node_properties(node)
	return

func _get_property_tree(node: Node) -> Dictionary:
	var tree := {}
	var current_category := ""
	var group := ""
	var sub_group := ""

	for _property in node.get_property_list():
		var _usage: int = _property["usage"]
		var _p_name: String = _property["name"]

		if _p_name.begins_with("metadata/"):
			# Metadata is ignored.
			continue

		if _dev_basic_props.has(_p_name):
			# These properties are handled at the top of the NPE.
			continue

		if _usage & PROPERTY_USAGE_CATEGORY:
			# If this property is a category.
			current_category = _p_name
			tree[current_category] = []
			continue

		if _usage & (PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SUBGROUP):
			# Ignore groups and subgroups.
			continue

		if _usage & PROPERTY_USAGE_EDITOR && !current_category.is_empty():

			tree[current_category].append(_property)

	return tree

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
	if _node == null:
		return

	_node.set_indexed(property_name, property_value)
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
