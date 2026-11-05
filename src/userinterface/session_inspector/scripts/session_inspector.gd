# --- License
# File: /client/src/userinterface/session_inspector/scripts/session_inspector.gd
# Project: OpenMinerva
# Created Date: 3 November 2026
# Copyright (c) 2026 OpenMinerva Contributors
# License: MIT License
# --- License
extends Control
## This is the master script that controls the session inspector. This script provides the intended public access for functionality within the inspector.
## It is intended for this script to be space agnostic. So this script can make an inspector work in a 3D space, just the same as the 2D interface on desktop.

var in_3d_space: bool = false
var state: Dictionary = { }
# Not guaranteed to be accurate, but is a way for the 3D inspector to cache the current session in the scene tree.
var _session_id: String = ""
var _session_signal_bus: Node = null
var _session_spawnable_manager: Node = null


func _init() -> void:
	var _node_path: String = get_path()
	if _node_path.contains("/root/Master/Sessions") == true:
		await get_tree().process_frame
		_set_space_3d(_node_path)
	return


# TODO: If application inspector: Connect to session signal bus when switching to session. 
# If 3D inspector should connect automatically and never change.
func _ready() -> void:
	return


func new_scene_state(state: Dictionary) -> void:
	return


## Force the inspector to change itself so that it fits into the 3D space inspector prefab.
## See INSPECTOR_LINK to see where this is expected to fit.
# TODO: Provide link to 3D inspector.
func _set_space_3d(node_path) -> void:
	var app_scene_m = get_tree().root.find_child("AppSceneManager", true, false)

	in_3d_space = true

	# Get the session signal bus
	var _path_parts: PackedStringArray = node_path.split("/")
	_session_id = _path_parts[4]
	_session_signal_bus = app_scene_m.get_session_manager(_session_id, "SignalBus")
	_session_spawnable_manager = app_scene_m.get_session_manager(_session_id, "SpawnableManager")

	# Remove spacing from center of inspector. This is only needed in flat screen.
	var _node_id: int = int(get_child(0).get_child(1).get_child(1).name)
	_session_spawnable_manager.destroy_spawnable(_node_id)
	return
