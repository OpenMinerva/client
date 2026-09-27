# --- License
# File: /client/src/test/worlds.gd
# Project: OpenMinerva
# Created Date: 22 September 2026
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


func after_test() -> void:
	_runner = null
	return


func test_load_world(_do_skip: bool = true) -> void:
	#  Load a world from disk
	return
