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
	var _scene = scene_container.get_node(id)
	return _scene

func destroy_master_scene(id: String):
	GlobalLogger.logs("'%s' is not implemented." % get_stack()[0]["function"], 3)
	# get_master_scene
	# Check if currently being used by a server.
	# Check if being used as client to server.
	# Queue free.
	return

func set_master_root_from_program(id: String, scene_type: Enum.BaseLevel) -> void:
	# TODO: Disable spawning players while changing master root.
	var _scene = get_master_scene(id)

	var _root_scene: PackedScene = _get_scene_by_type(scene_type)

	# TODO: Validate scene integrity.

	var _root_node = get_master_root(id)
	_scene.remove_child(_root_node)
	_root_node.queue_free()

	# Replace with new scene.
	var _root_scene_node = _root_scene.instantiate()
	_root_scene_node.name = "root"
	_scene.add_child(_root_scene_node)

	# TODO: Emit signal of root changed.
	return

func get_master_root(id: String) -> Node3D:
	var _scene: Node3D = get_master_scene(id)
	var _root = _scene.get_node_or_null("root")
	return _root

func set_master_root_from_inventory(id: String, scene_type: Enum.BaseLevel) -> bool:
	GlobalLogger.logs("'%s' is not implemented." % get_stack()[0]["function"], 3)
	# get_master_scene
	# Find scene from inventory.
	# Validate scene integrity.
	# Find node "root".
	# Destroy node.
	# Replace with new scene.
	return false

func start_master_scene(id: String):
	GlobalLogger.logs("'%s' is not implemented." % get_stack()[0]["function"], 3)
	# get_master_scene
	# Start Player manager.
	# Start ServerSignalManager.
	return

func _get_scene_by_type(scene_type: Enum.BaseLevel) -> PackedScene:
	var _scene_dir: String = ""

	match scene_type:
		Enum.BaseLevel.DEBUG:
			_scene_dir = "res://scenes/levels/debug.tscn"
		Enum.BaseLevel.EMPTY:
			_scene_dir = "res://scenes/levels/empty.tscn"
		Enum.BaseLevel.GRID:
			_scene_dir = "res://scenes/levels/grid.tscn"
		_:
			_scene_dir = "res://scenes/levels/debug.tscn"

	return load(_scene_dir)