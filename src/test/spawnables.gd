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
var _spawnable_manager: Node
var _mesh_instance: Node3D
var _mesh_resource: Resource


func before() -> void:
	_runner = scene_runner("res://scenes/base.tscn")
	_scene_container = _runner.find_child("Sessions")
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
	_mesh_resource = await _spawnable_manager.create_resource("BoxMesh", [])

	assert(_mesh_resource != null)
	assert(is_instance_of(_mesh_resource, BoxMesh) == true)

	_spawnable_manager.set_property(int(_mesh_instance.name), "mesh", _mesh_resource)

	assert(_mesh_instance.mesh != null)
	assert(is_instance_of(_mesh_instance.mesh, BoxMesh) == true)
	return


func test_set_meshinstance3d_position() -> void:
	var _basis_90: Basis = Basis.from_euler(Vector3(0, PI / 2, 0))

	var _initial_transform: Transform3D = Transform3D(Basis(), Vector3(0, 0, 0))
	var _target_transform_position: Transform3D = Transform3D(Basis(), Vector3(1, 1, 1))

	# Make sure that the transform of the node is at the root of the scene.
	assert(_mesh_instance.transform.is_equal_approx(_initial_transform))

	# Move the transform
	_spawnable_manager.spawnables.set_transform(int(_mesh_instance.name), _target_transform_position)
	assert(_mesh_instance.transform.is_equal_approx(_target_transform_position))

	return


func test_set_meshinstance3d_scale() -> void:
	var _basis_scaled: Basis = Basis.IDENTITY.scaled(Vector3(2, 2, 2))
	var _target_transform_scale: Transform3D = Transform3D(_basis_scaled, Vector3(0, 0, 0))

	# Move transform
	_spawnable_manager.spawnables.set_transform(int(_mesh_instance.name), _target_transform_scale)
	assert(_mesh_instance.transform.is_equal_approx(_target_transform_scale))

	return


func test_set_meshinstance3d_mesh_scale() -> void:
	var _initial_scale: Vector3 = Vector3(1, 1, 1)
	var _target_scale: Vector3 = Vector3(2, 5, 3)

	# Make sure we start at a known scale.
	assert(_mesh_resource.size == _initial_scale)

	# Change the resource scale.
	_spawnable_manager.set_property_on_resource(int(_mesh_resource.get_name()), "size", _target_scale)

	# Make sure the resource is set.
	assert(_mesh_resource.size == _target_scale)
	return


func test_remove_spawnable() -> void:
	await _spawnable_manager.destroy_spawnable(int(_mesh_instance.get_name()))

	# Mesh instance should be removed.
	assert(_mesh_instance == null)
	return


func test_remove_resource(_do_skip: bool = true) -> void:
	# TODO: Remove resource from session.
	return
