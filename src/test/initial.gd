# --- License
# File: /client/src/test/initial.gd
# Project: OpenMinerva
# Created Date: 16 September 2026
# Copyright (c) 2026 OpenMinerva Contributors
# License: MIT License
# --- License
extends GdUnitTestSuite

var _runner: GdUnitSceneRunner


func before_test() -> void:
	_runner = scene_runner("res://scenes/master.tscn")


func test_starts() -> void:
	var _inspector: Control = _runner.find_child("Inspector")
	var _scenes_container: Node3D = _runner.find_child("Scenes")
	var _app_network_manager: Node = _runner.find_child("AppNetworkManager")
	var _app_scene_manager: Node = _runner.find_child("SceneManager")
	var _app_spawnable_file_handling: Node = _runner.find_child("SpawnableFileHandling")
	var _dashboard: Control = _runner.find_child("Dashboard")

	assert(_inspector != null)
	assert(_scenes_container != null)
	assert(_app_network_manager != null)
	assert(_app_scene_manager != null)
	assert(_app_spawnable_file_handling != null)
	assert(_dashboard != null)
	return


func after_test() -> void:
	_runner = null
