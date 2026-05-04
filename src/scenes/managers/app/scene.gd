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
var active_session: String = ""

func _ready():
	network_m.start_server()
	return

func create_master_scene():
	var _scene_id = Random.random_string()
	var _base_scene = preload("res://scenes/levels/base.tscn")

	_base_scene = _base_scene.instantiate()
	_base_scene.name = _scene_id
	_base_scene.top_level = true
	_base_scene.visible = false

	scene_container.add_child(_base_scene)

	return _scene_id

func get_master_scene(id: String) -> Node3D:
	var _scene = scene_container.get_node(id)
	return _scene

func destroy_master_scene(id: String):
	var _scene = scene_container.get_node_or_null(id)

	if _scene == null:
		GlobalLogger.logs("'%s' does not exist, could not delete." % id, Enum.LogLevel.WARNING)
		return

	_scene.queue_free()
	return

func set_master_root_from_program(id: String, scene_type: Enum.BaseLevel) -> void:
	var _scene = get_master_scene(id)

	var _root_scene: PackedScene = _get_scene_by_type(scene_type)
	var _root_node = get_master_root(id)

	# Stop everything
	stop_master_scene(id)

	# Remove everything
	_scene.remove_child(_root_node)
	_root_node.queue_free()

	# Get new scene
	var _root_scene_node = _root_scene.instantiate()
	_root_scene_node.name = "root"

	# Add new scene
	_scene.add_child(_root_scene_node)

	# Start everything
	start_master_scene(id)

	Events.emit_signal("instance_root_changed")
	return

func get_master_root(id: String) -> Node3D:
	var _scene: Node3D = get_master_scene(id)
	var _root = _scene.get_node_or_null("root")
	return _root

func set_master_root_from_inventory(_id: String, _scene_type: Enum.BaseLevel) -> bool:
	GlobalLogger.logs("'%s' is not implemented." % get_stack()[0]["function"], Enum.LogLevel.WARNING)
	# get_master_scene
	# Find scene from inventory.
	# Validate scene integrity.
	# Find node "root".
	# Destroy node.
	# Replace with new scene.
	return false

func start_master_scene(id: String):
	const MANAGERS = ["PlayerManager", "SignalBus"]

	var _scene = get_master_scene(id)

	for node_name in MANAGERS:
		var _scene_manager = _scene.get_node_or_null(node_name)
		if _scene_manager:
			_scene_manager.module_active = true
			GlobalLogger.logs("'%s' started in server '%s'" % [node_name, id])
			continue

		GlobalLogger.logs("Could not start invalid manager '%s' in server '%s'" % [node_name, id], Enum.LogLevel.ERROR)
	return

func stop_master_scene(id: String):
	const MANAGERS = ["PlayerManager", "SignalBus"]

	var _scene = get_master_scene(id)

	for node_name in MANAGERS:
		var _scene_manager = _scene.get_node_or_null(node_name)
		if _scene_manager:
			_scene_manager.module_active = true
			GlobalLogger.logs("'%s' stopped in server '%s'" % [node_name, id])
			continue

		GlobalLogger.logs("Could not stop invalid manager '%s' in server '%s'" % [node_name, id], Enum.LogLevel.ERROR)
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

func set_active_session(session_id: String):
	GlobalLogger.logs("Setting session '%s' active." % session_id)

	for _scene in network_m.get_connected_sessions():
		# Each session gets disabled
		scene_container.get_node(_scene.id).visible = false
		_set_camera_active_state(_scene.id, false)
		_set_player_authority_state(_scene.id, false)

	# session_id gets enabled.
	active_session = session_id
	_set_camera_active_state(session_id, true)
	scene_container.get_node(session_id).visible = true
	_set_player_authority_state(session_id, true)
	return

func _set_camera_active_state(session_id, state: bool = false) -> void:
	# TODO: check if session exists.
	var my_id: String = str(network_m._database.sessions_api[session_id].get_unique_id())
	var master_scene: Node3D = get_master_scene(session_id)
	# HACK: If my_id = 0, we get the desired result. This is not safe though.
	if my_id == "0":
		GlobalLogger.logs("Could not set active state for session '%s', is session open?" % [session_id], Enum.LogLevel.WARNING)
		return
	var player_manager: Node = master_scene.get_node("PlayerManager")
	var player_database = player_manager.players
	var my_database_entry = player_database.get(my_id)
	var camera = my_database_entry.get("node").get_node("Head/Camera3D")

	camera.current = state
	return

func _set_player_authority_state(session_id, is_active: bool = false) -> void:
	var my_id: String = str(network_m._database.sessions_api[session_id].get_unique_id())
	var master_scene: Node3D = get_master_scene(session_id)
	# HACK: If my_id = 0, we get the desired result. This is not safe though.
	if my_id == "0":
		GlobalLogger.logs("Could not set player authority for session '%s', is session open?" % [session_id], Enum.LogLevel.WARNING)
		return
	var player_manager: Node = master_scene.get_node("PlayerManager")
	var player_database = player_manager.players
	var my_database_entry = player_database.get(my_id)
	var player = my_database_entry.get("node")

	if is_active:
		player.set_multiplayer_authority(int(my_id))
		return

	player.set_multiplayer_authority(0)
	return
