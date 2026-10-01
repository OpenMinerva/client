# --- License
# File: /client/src/test/spawnables_properties.gd
# Project: OpenMinerva
# Created Date: 29 September 2026
# Copyright (c) 2026 OpenMinerva Contributors
# License: MIT License
# --- License
extends GdUnitTestSuite

var _runner: GdUnitSceneRunner
var _scene_container: Node3D
var _spawnable_manager: Node
var _mesh_instance: Node3D


func before() -> void:
	_runner = scene_runner("res://scenes/master.tscn")
	_scene_container = _runner.find_child("Scenes")
	_spawnable_manager = _scene_container.get_child(0).get_node("SpawnableManager")
	_mesh_instance = await _spawnable_manager.create_spawnable("MeshInstance3D")
	return


func after() -> void:
	_runner = null
	return


func test_setup_scene() -> void:
	assert(_scene_container != null)
	assert(_spawnable_manager != null)
	return


func test_spawn_meshinstance3d() -> void:
	assert(_mesh_instance != null)
	assert(is_instance_of(_mesh_instance, MeshInstance3D) == true)
	return


func test_set_meshinstance3d_mesh() -> void:
	var _mesh_resource: Resource = await _spawnable_manager.create_asset("BoxMesh", [])

	assert(_mesh_resource != null)
	assert(is_instance_of(_mesh_resource, BoxMesh) == true)

	_spawnable_manager.set_property(int(_mesh_instance.name), "mesh", _mesh_resource)

	assert(_mesh_instance.mesh != null)
	assert(is_instance_of(_mesh_instance.mesh, BoxMesh) == true)
	return


func test_set_meshinstance3d_position(_do_skip: bool = true) -> void:
	return


func test_set_meshinstance3d_scale(_do_skip: bool = true) -> void:
	return


func test_set_meshinstance3d_mesh_scale(_do_skip: bool = true) -> void:
	return
