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


static var schema = {
	"Gizmo": {
		"requires_setup": true,
		"pretty_name": "Gizmo",
		"node": null,
		"icon": load("res://resources/icons/Gizmo.svg"),
	},
	"Model": {
		"requires_setup": true,
		"pretty_name": "Imported Model",
		"node": null,
		"icon": load("res://resources/icons/godot/MeshInstance3D.svg"),
	},
	"Node3D": {
		"requires_setup": false,
		"pretty_name": "Node3D",
		"node": "Node3D",
		"icon": load("res://resources/icons/godot/Node3D.svg"),
	},
	"Box": {
		"requires_setup": true,
		"pretty_name": "Box",
		"node": null,
		"icon": load("res://resources/icons/godot/MeshInstance3D.svg"),
	},
	"Capsule": {
		"requires_setup": true,
		"pretty_name": "Capsule",
		"node": null,
		"icon": load("res://resources/icons/godot/MeshInstance3D.svg"),
	},
	"RigidBody3D": {
		"requires_setup": true,
		"pretty_name": "RigidBody3D",
		"node": RigidBody3D,
		"icon": load("res://resources/icons/godot/RigidBody3D.svg"),
	},
	"MeshInstance3D": {
		"requires_setup": false,
		"pretty_name": "MeshInstance3D",
		"node": "MeshInstance3D",
		"icon": load("res://resources/icons/godot/MeshInstance3D.svg"),
	},
}


static func get_valid() -> Array[String]:
	var result: Array[String] = []
	result.assign(schema.keys())
	return result


static func get_node_index(node_name: String) -> int:
	return schema.keys().find(node_name)


static func get_formatted(node_name: int) -> Variant:
	return schema[schema.keys()[node_name]]


static func _build_node(node_name: String, model_path: String = "") -> Node:
	var schema_index = get_node_index(node_name)
	var schema_entry = get_formatted(schema_index)

	if schema_entry.requires_setup == false:
		return ClassDB.instantiate(schema_entry.node)

	if node_name == "Box":
		var _work_node = MeshInstance3D.new()
		_work_node.mesh = BoxMesh.new()
		return _work_node

	if node_name == "Capsule":
		var _work_node = MeshInstance3D.new()
		_work_node.mesh = CapsuleMesh.new()
		return _work_node

	if node_name == "RigidBody3D":
		var _work_node = RigidBody3D.new()
		_work_node.freeze = true
		return _work_node

	if node_name == "Gizmo":
		var _work_node = Gizmo3D.new()
		_work_node.top_level = true
		return _work_node

	if node_name == "Model":
		var doc = GLTFDocument.new()
		var state = GLTFState.new()
		doc.append_from_file(model_path, state)
		var glb_scene: Node3D = doc.generate_scene(state)
		return glb_scene

	# FIXME: This function should always return what the user wants. If it gets to this point then I made an error in the schema. Proper reporting to the user somehow?
	return Node3D.new()
