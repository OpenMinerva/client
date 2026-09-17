# --- License
# File: /client/src/test/spawnables.gd
# Project: OpenMinerva
# Created Date: 17 September 2026
# Copyright (c) 2026 OpenMinerva Contributors
# License: MIT License
# --- License
extends GdUnitTestSuite

var _runner: GdUnitSceneRunner
var _scene_container: Node3D


func before_test(_do_skip: bool = true) -> void:
	_runner = scene_runner("res://scenes/master.tscn")
	_scene_container = _runner.find_child("Scenes")
	return


func after_test() -> void:
	_runner = null
	return


func test_spawn_spawnable(_do_skip: bool = true) -> void:
	return


func test_destroy_spawnable(_do_skip: bool = true) -> void:
	return


func test_move_spawnable(_do_skip: bool = true) -> void:
	return


func test_set_property_spawnable(_do_skip: bool = true) -> void:
	return


func test_rotate_spawnable(_do_skip: bool = true) -> void:
	return


func test_create_asset(_do_skip: bool = true) -> void:
	return


func test_manipulate_asset(_do_skip: bool = true) -> void:
	return


func test_destroy_asset(_do_skip: bool = true) -> void:
	return
