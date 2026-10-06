# --- License
# File: /client/src/test/scene.gd
# Project: OpenMinerva
# Created Date: 16 September 2026
# Copyright (c) 2026 OpenMinerva Contributors
# License: MIT License
# --- License
extends GdUnitTestSuite

var _runner: GdUnitSceneRunner
var _scene_container: Node3D


func before_test() -> void:
	_runner = scene_runner("res://scenes/master.tscn")
	_scene_container = _runner.find_child("Scenes")
	return


## Make sure that the "master" scene containing all of our UI elements exists.
func test_initial_scene() -> void:
	var _inspector: Control = _runner.find_child("Inspector")
	_scene_container = _runner.find_child("Scenes")
	var _app_network_manager: Node = _runner.find_child("AppNetworkManager")
	var _app_scene_manager: Node = _runner.find_child("AppSceneManager")
	var _app_spawnable_file_handling: Node = _runner.find_child("SpawnableFileHandling")
	var _dashboard: Control = _runner.find_child("Dashboard")

	assert(_inspector != null)
	assert(_scene_container != null)
	assert(_app_network_manager != null)
	assert(_app_scene_manager != null)
	assert(_app_spawnable_file_handling != null)
	assert(_dashboard != null)
	return


## This will make sure that the initial home world layout is what we expect.
func test_home_world_layout() -> void:
	# There should be a single session when the application opens.
	assert(_scene_container.get_child_count() == 1)

	var _home_session_root: Node3D = _scene_container.get_children()[0].get_node("root")
	await _test_world_layout(_home_session_root)

	# There should be a player in the session (us)
	var _node_one: Node3D = _home_session_root.get_node("1")
	assert(_node_one != null)
	assert(_node_one.get_class() == "CharacterBody3D")

	return


func test_start_server() -> void:
	Events.action_start_server.emit()

	var _new_scene: Node3D = _scene_container.get_children()[1]
	await _test_world_layout(_new_scene)

	# TODO: Make sure our player connected and is in the scene.
	return


func test_stop_server(_do_skip: bool = true) -> void:
	return


func test_stop_home_server(_do_skip: bool = true) -> void:
	# NOTE: Should not be allowed to stop the home server.
	return


func test_close_application() -> void:
	var _is_closing: bool = false
	Bootstrap.quit_action = func() -> void: return

	await _runner.simulate_frames(10)
	# It looks like I don't need to assert anything here, gdUnit4 treats this as an error if this fails?
	# That's probably wrong, but I can figure out what I need to assert here when something else fails.
	await Bootstrap._notification(NOTIFICATION_WM_CLOSE_REQUEST)

	# Application is in a closing state.
	assert(StateManager.app_closing == true)

	# We are not in any more servers.
	assert(Bootstrap.network_m.registry.get_all().size() == 0)

	# Make sure we do not have any more scene nodes.
	var _scenes: Array[Node] = _scene_container.get_children()
	assert(_scenes.size() == 0)

	return


func after_test() -> void:
	_runner = null
	return


func _test_world_layout(world_root: Node) -> void:
	await _runner.simulate_frames(5)

	# There should be more than three children in the scene.
	# This makes sure the session root was set up properly, destroying the initial parent node when loading a world.
	assert(world_root.get_child_count() > 3)

	return
