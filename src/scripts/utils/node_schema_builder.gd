# --- License
# File: /client/src/scripts/utils/node_schema_builder.gd
# Project: OpenMinerva
# Created Date: 03 June 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
class_name NSB
extends Node

static var _schema: Dictionary = {}

static func init() -> void:
	# Clear the schema just in case
	_schema = {}

	# Load the schema json file
	var _schema_raw = load("res://scripts/utils/schema.json")
	var _schema_data = _schema_raw.data

	# Build the schema from the information provided
	for _item in _schema_data.keys():
		var _entry = _schema_data[_item]
		_entry.icon = load("res://resources/icons/%s" % _entry.icon)
		# TODO: If the icon failed to load, use a fallback / placeholder

		_schema[_item] = _entry
	return

static func is_valid(search_key: Variant) -> bool:
	return false

static func get_schema() -> Dictionary:
	return _schema

static func get_entry(node_name: String) -> Dictionary:
	if !_schema.keys().has(node_name):
		# Invalid node_name
		return {}

	return _schema[node_name]

static func build(node_name: String, model_path: String = "") -> Node:
	var _entry = _schema[node_name]

	if _entry.requires_setup == false:
		var _work_node = ClassDB.instantiate(_entry.node)
		_add_node_metadata(_work_node)
		return _work_node

	if node_name == "Box":
		var _work_node = MeshInstance3D.new()
		_work_node.mesh = BoxMesh.new()
		_add_node_metadata(_work_node)
		return _work_node

	if node_name == "Capsule":
		var _work_node = MeshInstance3D.new()
		_work_node.mesh = CapsuleMesh.new()
		_add_node_metadata(_work_node)
		return _work_node

	if node_name == "RigidBody3D":
		var _work_node = RigidBody3D.new()
		_work_node.freeze = true
		_add_node_metadata(_work_node)
		return _work_node

	if node_name == "Gizmo":
		var _work_node = Gizmo3D.new()
		_work_node.top_level = true
		_add_node_metadata(_work_node)

		_work_node.set_meta("scene_node", false)
		return _work_node

	# TODO: Should this just be a camera?
	if node_name == "Camera3D":
		var _work_node = Camera3D.new()
		_add_node_metadata(_work_node)
		_work_node.current = false
		return _work_node

	if node_name == "Model":
		# TODO: Generating the scene does not seem to properly set up the MeshInstance3D, causing deletion errors.
		# TODO: Throw this into another thread.
		# That also means that this probably will not work for sending meshes over the network.
		var doc = GLTFDocument.new()
		var state = GLTFState.new()
		doc.append_from_file(model_path, state)
		var glb_scene: Node3D = doc.generate_scene(state)

		_add_node_metadata(glb_scene)

		return glb_scene

	# FIXME: This function should always return what the user wants. If it gets to this point then I made an error in the schema. Proper reporting to the user somehow?
	return Node3D.new()

static func _add_node_metadata(root: Node) -> void:
	var _class = root.get_class()
	var _schema_entry = _schema[_class]

	root.set_meta("spawnable_type", _class)
	root.set_meta("pretty_name", _schema_entry.pretty_name)
	root.set_meta("deep_delete", _schema_entry.deep_delete)

	for child in root.get_children():
		_add_node_metadata(child)
	return
