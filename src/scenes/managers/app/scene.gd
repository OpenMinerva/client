# --- License
# File: /client/src/scenes/managers/app/scene.gd
# Project: OpenMinerva
# Created Date: 13 April 2026
# Copyright (c) 2026 OpenMinerva Contributors
# License: MIT License
# --- License
extends Node

var active_session: String = ""

# Game managers
@onready var app_network_m: Node = get_tree().root.find_child("AppNetworkManager", true, false)
@onready var sessions_container: Node = get_tree().root.find_child("Sessions", true, false)
@onready var spawnable_file_handling: Node = get_tree().root.find_child("SpawnableFileHandling", true, false)


func _ready():
	app_network_m.start_session(0, Enum.BaseLevel.HOME)
	return


func create_session_master():
	var _session_id = Random.string(6)
	var _base_scene = preload("res://scenes/levels/session.tscn")

	_base_scene = _base_scene.instantiate()
	_base_scene.name = _session_id
	_base_scene.top_level = true
	_base_scene.visible = false

	sessions_container.add_child(_base_scene)

	return _session_id


func get_session_master(id: String) -> Node3D:
	var _session_master_node = sessions_container.get_node(id)
	return _session_master_node


func destroy_session_master(id: String):
	var _session_master_node = sessions_container.get_node_or_null(id)

	if _session_master_node == null:
		GlobalLogger.log("'%s' does not exist, could not delete." % id, Enum.LogLevel.WARNING)
		return

	_session_master_node.queue_free()
	return


func set_session_master_root_from_program(id: String, scene_type: Enum.BaseLevel, scene_dir: String = "", set_up_root: bool = true) -> void:
	GlobalLogger.log("Setting master root from program.")

	var _session_master_node: Node3D = get_session_master(id)
	var _spawnable_manager: Node = _session_master_node.get_node("SpawnableManager")
	var _world_path: String = _get_scene_by_type(scene_type)
	var _session_root_node: Node3D = get_session_master_root(id)
	var _session_empty_root: Node3D = Node3D.new()
	var _instantiated_world_root: Node3D # Root of the loaded world from disk. This is typically removed.

	# Remove everything
	_session_root_node.free()

	# Build the new session root
	_session_empty_root.name = "root"
	_session_empty_root.set_meta("scene_node", true)
	_session_master_node.add_child(_session_empty_root)

	await await_session_ready(id)

	# Use spawnable system to read the TSCN file, and instantiate it into the multiplayer instance.
	if scene_type == Enum.BaseLevel.CUSTOM:
		if scene_dir == "":
			GlobalLogger.log("Tried to load a custom scene, but there was not a directiory!", Enum.LogLevel.WARNING)
			_world_path = _get_scene_by_type(Enum.BaseLevel.GRID)
			await spawnable_file_handling.load_spawnable(_world_path)
		else:
			_instantiated_world_root = await spawnable_file_handling.load_spawnable(scene_dir)
	else:
		_instantiated_world_root = await spawnable_file_handling.load_spawnable(_world_path)

	# Remove the "root" node of the world, and instead parent all nodes under the true instance root.
	if set_up_root == true:
		for _world_node in _instantiated_world_root.get_children():
			_spawnable_manager.parent_spawnable(int(_world_node.name), -1)

		# Delete the initial fake root from the loaded world.
		_spawnable_manager.spawnables.session_destroy_spawnable(int(_instantiated_world_root.name))

	Events.emit_signal("instance_root_changed")
	return


func get_session_master_root(id: String) -> Node3D:
	var _session_master_node: Node3D = get_session_master(id)
	var _root = _session_master_node.get_node_or_null("root")
	return _root


func set_active_session(session_id: String):
	GlobalLogger.log("Setting session '%s' active." % session_id)

	active_session = session_id

	for _scene in app_network_m.get_connected_sessions():
		# Each session gets disabled
		var _target_scene = sessions_container.get_node(_scene.id)
		_target_scene.visible = false
		_target_scene.process_mode = Node.PROCESS_MODE_DISABLED

		_set_camera_active_state(_scene.id, false)
		_target_scene.get_node("SpawnableManager/Gizmos").hide_session_gizmos()

	# session_id gets enabled.
	var _scene_node: Node3D = sessions_container.get_node(session_id)
	_scene_node.process_mode = Node.PROCESS_MODE_INHERIT
	_scene_node.visible = true
	_scene_node.get_node("SpawnableManager/Gizmos").show_session_gizmos()

	_set_camera_active_state(session_id, true)
	app_network_m.registry.set_recent(session_id)

	Events.dash_session_changed.emit(session_id)

	return


func is_scene_ready(session_id: String) -> bool:
	var _session_master_node: Node3D = get_session_master(session_id)
	return _session_master_node.is_ready


# TODO: Safety! Replace with function that resolves with boolean. If timeout is reached, resolve false otherwise true.
func await_session_ready(session_id: String) -> void:
	var _session_ready: bool = false
	while _session_ready == false:
		var _scene_ready: bool = is_scene_ready(session_id)
		var _active_session_set: bool = app_network_m.app_scene_m.active_session.is_empty() == false

		_session_ready = _scene_ready == true && _active_session_set == true

		await get_tree().process_frame
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

	var _my_peer_id: String = str(app_network_m.registry.get_peer_id(session_id))
	var _session_master_node: Node3D = get_session_master(session_id)
	var _sess_player_m: Node = _session_master_node.get_node("PlayerManager")
	var _session_player_info = _sess_player_m.players.get(_my_peer_id)

	if _my_peer_id == "0" && state == true:
		GlobalLogger.log("Could not set active state for session '%s' to 'true', is session open?" % [session_id], Enum.LogLevel.WARNING)
		return

	if _session_player_info == null:
		GlobalLogger.log("There is no player information for this player in session '%s'." % [session_id], Enum.LogLevel.WARNING)
		return

	if _session_player_info.node == null:
		# TODO: Should we queue or retry periodically?
		GlobalLogger.log("Could not find player node in session '%s'." % [session_id], Enum.LogLevel.WARNING)
		return

	_session_player_info.node.set_camera_state(state)
	return
