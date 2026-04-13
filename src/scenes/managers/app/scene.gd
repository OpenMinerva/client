# --- License
# File: /client/src/scenes/managers/app/scene_manager.gd
# Project: OpenMinerva
# Created Date: 13 April 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Node

# Game managers
@onready var network_m: Node = get_tree().current_scene.get_node("NetworkManager")
@onready var scene_container: Node3D = get_tree().current_scene.get_node("Scenes")

func _ready():
	network_m.start_server()
	return

func create_master_scene():
	var _scene_id = Random.random_string()
	var _base_scene = preload("res://scenes/levels/base.tscn")

	_base_scene = _base_scene.instantiate()
	_base_scene.name = _scene_id

	scene_container.add_child(_base_scene)

	return _scene_id

func get_master_scene(id: String) -> Node3D:
	# Find scene by id from scene list.
	# return Node3D or null.
	return

func destroy_master_scene(id: String):
	# get_master_scene
	# Check if currently being used by a server.
	# Check if being used as client to server.
	# Queue free.
	return

func set_master_root_from_program(id: String, scene_type: Enum.BaseLevel) -> bool:
	# get_master_scene.
	# Find scene by scene_type. (Make function)
	# Validate scene integrity.
	# Find node "root".
	# Destroy node.
	# Replace with new scene.
	return false

func get_master_root(id: String) -> Node3D:
	# get_master_scene
	# Find node "root".
	return

func set_master_root_from_inventory(id: String, scene_type: Enum.BaseLevel) -> bool:
	GlobalLogger.logs("'%s' is not implemented." % get_stack()[0]["name"])
	# get_master_scene
	# Find scene from inventory.
	# Validate scene integrity.
	# Find node "root".
	# Destroy node.
	# Replace with new scene.
	return false
