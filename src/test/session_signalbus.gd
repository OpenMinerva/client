# --- License
# File: /client/src/test/session_signalbus.gd
# Project: OpenMinerva
# Created Date: 11 October 2026
# Copyright (c) 2026 OpenMinerva Contributors
# License: MIT License
# --- License
extends GdUnitTestSuite

var _runner: GdUnitSceneRunner
var _scene_container: Node3D
var _spawnable_manager: Node
var _signalbus: Node
# Test variables
var _node_created_called: bool = false
var _node_created_reference: Node = null
var _node_destroyed_called: bool = false
var _node_destroyed_reference: Node = null
var _resource_created_called: bool = false
var _resource_created_reference: Resource = null
var _node_metadata_change_called: bool = false
var _node_metadata_reference: Node = null


func before() -> void:
	_runner = scene_runner("res://scenes/base.tscn")
	_scene_container = _runner.find_child("Sessions")
	_spawnable_manager = _scene_container.get_child(0).get_manager(_scene_container.get_child(0).MANAGER_TYPE.SPAWNABLE)
	_signalbus = _scene_container.get_child(0).get_manager(_scene_container.get_child(0).MANAGER_TYPE.SIGNAL_BUS)

	_node_created_called = false
	_node_destroyed_called = false
	_resource_created_called = false
	_node_metadata_change_called = false
	return


func after() -> void:
	_runner = null
	return


func test_signalbus_node_created() -> void:
	_signalbus.node_created.connect(
		func(node):
			_node_created_called = true
			_node_created_reference = node
	)

	assert(_node_created_called == false)
	assert(_node_created_reference == null)

	var _spawnable: MeshInstance3D = await _spawnable_manager.create_spawnable("MeshInstance3D")

	assert(_node_created_reference == _spawnable)
	assert(_node_created_called == true)
	return


func test_signalbus_node_destroyed() -> void:
	var _mesh_instance = await _spawnable_manager.create_spawnable("MeshInstance3D")
	_signalbus.node_destroyed.connect(
		func(node):
			_node_destroyed_called = true
			_node_destroyed_reference = node
	)

	assert(_node_destroyed_called == false)
	assert(_node_destroyed_reference == null)

	var _spawnable: Node3D = await _spawnable_manager.destroy_spawnable(int(_mesh_instance.get_name()))

	assert(_node_destroyed_reference == _spawnable)
	assert(_node_destroyed_called == true)
	return


func test_signalbus_resource_created() -> void:
	_signalbus.resource_created.connect(
		func(resource):
			_resource_created_called = true
			_resource_created_reference = resource
	)

	assert(_resource_created_called == false)
	assert(_resource_created_reference == null)

	var _resource: BoxMesh = await _spawnable_manager.create_resource("BoxMesh", [])

	assert(_resource_created_reference == _resource)
	assert(_resource_created_called == true)
	return


func test_signalbus_node_metadata_change() -> void:
	_signalbus.node_metadata_change.connect(
		func(node):
			_node_metadata_change_called = true
			_node_metadata_reference = node
	)

	assert(_node_metadata_change_called == false)
	assert(_node_metadata_reference == null)

	var _mesh_instance = await _spawnable_manager.create_spawnable("MeshInstance3D")
	await _spawnable_manager.set_metadata(int(_mesh_instance.name), "test_meta", "test_value")

	assert(_node_metadata_reference == _mesh_instance)
	assert(_node_metadata_change_called == true)
	return
