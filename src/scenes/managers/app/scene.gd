# --- License
# File: /client/src/scenes/managers/app/scene_manager.gd
# Project: OpenMinerva
# Created Date: 13 April 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Node

var active_session: String = ""

# Game managers
@onready var network_m: Node = get_tree().current_scene.get_node("NetworkManager")
@onready var scene_container: Node3D = get_tree().current_scene.get_node("Scenes")
@onready var spawnable_file_handling: Node = get_tree().current_scene.get_node("SpawnableFileHandling")


func _ready():
	network_m.start_server(0, Enum.BaseLevel.HOME)
	return


func create_master_scene():
	var _scene_id = Random.string(6)
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
		GlobalLogger.log("'%s' does not exist, could not delete." % id, Enum.LogLevel.WARNING)
		return

	_scene.queue_free()
	return


func set_master_root_from_program(id: String, scene_type: Enum.BaseLevel, scene_dir: String = "", set_up_root: bool = true) -> void:
	var _scene = get_master_scene(id)

	var _root_scene: String = _get_scene_by_type(scene_type)
	var _root_node = get_master_root(id)

	# Stop everything
	stop_master_scene(id)

	# Remove everything
	_scene.remove_child(_root_node)
	_root_node.queue_free()

	var _root_scene_node: Node3D = Node3D.new()
	_root_scene_node.name = "root"
	_scene.add_child(_root_scene_node)

	# HACK: Wait a frame for the active_session variable to populate
	await get_tree().process_frame

	# Use spawnable system to read the TSCN file, and instantiate it into the multiplayer instance.
	if scene_type == Enum.BaseLevel.CUSTOM:
		if scene_dir == "":
			GlobalLogger.log("Tried to load a custom scene, but there was not a directiory!", Enum.LogLevel.WARNING)
			_root_scene = _get_scene_by_type(Enum.BaseLevel.GRID)
			await spawnable_file_handling.load_spawnable(_root_scene)
		else:
			await spawnable_file_handling.load_spawnable(scene_dir)
	else:
		await spawnable_file_handling.load_spawnable(_root_scene)

	# Remove the "root" node of the world, and instead parent all nodes under the true instance root.
	# HACK: Force reparent the children of the node to the world root.
	if set_up_root && _root_scene_node.get_children().size() > 0:
		var _target_node: Node3D = _root_scene_node.get_children()[1]
		var _spawnable_manager: Node = _scene.get_node("SpawnableManager")

		for _world_node in _target_node.get_children():
			_spawnable_manager.set_parent.rpc(int(_world_node.name), 0)

		# Delete the initial fake root from the loaded world.
		_spawnable_manager.destroy.rpc(int(_target_node.name))

	# Allow scene to be visible in the inspector
	_root_scene_node.set_meta("scene_node", true)

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
	GlobalLogger.log("'%s' is not implemented." % get_stack()[0]["function"], Enum.LogLevel.WARNING)
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
			GlobalLogger.log("'%s' started in server '%s'" % [node_name, id])
			continue

		GlobalLogger.log("Could not start invalid manager '%s' in server '%s'" % [node_name, id], Enum.LogLevel.ERROR)
	return


func stop_master_scene(id: String):
	const MANAGERS = ["PlayerManager", "SignalBus"]

	var _scene = get_master_scene(id)

	for node_name in MANAGERS:
		var _scene_manager = _scene.get_node_or_null(node_name)
		if _scene_manager:
			GlobalLogger.log("'%s' stopped in server '%s'" % [node_name, id])
			continue

		GlobalLogger.log("Could not stop invalid manager '%s' in server '%s'" % [node_name, id], Enum.LogLevel.ERROR)
	return


func set_active_session(session_id: String):
	GlobalLogger.log("Setting session '%s' active." % session_id)

	active_session = session_id

	for _scene in network_m.get_connected_sessions():
		# Each session gets disabled
		var _target_scene = scene_container.get_node(_scene.id)
		_target_scene.visible = false
		_target_scene.process_mode = Node.PROCESS_MODE_DISABLED

		_set_camera_active_state(_scene.id, false)
		_set_player_authority_state(_scene.id, false)
		for gizmo in scene_container.get_node(_scene.id).get_node("SpawnableManager")._gizmos:
			gizmo._set_visibility(false)

	# session_id gets enabled.
	scene_container.get_node(session_id).process_mode = Node.PROCESS_MODE_INHERIT
	_set_camera_active_state(session_id, true)
	scene_container.get_node(session_id).visible = true
	_set_player_authority_state(session_id, true)
	Events.dash_session_changed.emit(session_id)
	for gizmo in scene_container.get_node(session_id).get_node("SpawnableManager")._gizmos:
		gizmo._set_visibility(true)

	return


func _get_scene_by_type(scene_type: Enum.BaseLevel) -> String:
	var _scene_dir: String = ""

	match scene_type:
		Enum.BaseLevel.DEBUG:
			_scene_dir = "res://scenes/levels/debug.tscn"
		Enum.BaseLevel.EMPTY:
			_scene_dir = "res://scenes/levels/empty.tscn"
		Enum.BaseLevel.GRID:
			_scene_dir = "res://scenes/levels/grid.tscn"
		Enum.BaseLevel.HOME:
			_scene_dir = "res://scenes/levels/home.tscn"
		_:
			_scene_dir = "res://scenes/levels/debug.tscn"

	return _scene_dir


func _set_camera_active_state(session_id, state: bool = false) -> void:
	# TODO: check if session exists.
	var _my_peer_id: String = network_m.registry.get_peer_id(session_id)
	var master_scene: Node3D = get_master_scene(session_id)
	# HACK: If my_id = 0, we get the desired result. This is not safe though.
	if _my_peer_id == "0":
		GlobalLogger.log("Could not set active state for session '%s', is session open?" % [session_id], Enum.LogLevel.WARNING)
		return
	var player_manager: Node = master_scene.get_node("PlayerManager")
	var player_database = player_manager.players
	var my_database_entry = player_database.get(_my_peer_id)
	if my_database_entry != null:
		if my_database_entry.node == null:
			# FIXME: This error should not be necessary, there is a bigger problem somewhere else.
			return

		var camera = my_database_entry.node.get_node("Head/Camera3D")
		camera.current = state
	return


func _set_player_authority_state(session_id, is_active: bool = false) -> void:
	var _my_peer_id: String = network_m.registry.get_peer_id(session_id)
	var master_scene: Node3D = get_master_scene(session_id)
	# HACK: If my_id = 0, we get the desired result. This is not safe though.
	if _my_peer_id == "0":
		GlobalLogger.log("Could not set player authority for session '%s', is session open?" % [session_id], Enum.LogLevel.WARNING)
		return
	var player_manager: Node = master_scene.get_node("PlayerManager")
	var player_database = player_manager.players
	var my_database_entry = player_database.get(_my_peer_id)

	if my_database_entry != null:
		var player = my_database_entry.node

		if player == null:
			# FIXME: This error should not be necessary, there is a bigger problem somewhere else.
			return

		if is_active:
			player.set_multiplayer_authority(int(_my_peer_id))
			return

		player.set_multiplayer_authority(0)
	return
