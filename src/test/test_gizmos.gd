# --- License
# File: /client/src/test/test_gizmos.gd
# Project: OpenMinerva
# Created Date: 12 October 2026
# Copyright (c) 2026 OpenMinerva Contributors
# License: MIT License
# --- License
extends GdUnitTestSuite

var _runner: GdUnitSceneRunner
var _scene_container: Node3D
var _session_root: Node3D
var _instance_root: Node3D
var _spawnable_manager: Node
var _registry: Node
var _mesh_instance: Node3D
var _gizmo: Node
var _gizmo_id: int = -1


## This is run once before starting the tests in the file to set up the scene once.
func before() -> void:
	_runner = scene_runner("res://scenes/base.tscn")
	_scene_container = _runner.find_child("Sessions")
	_session_root = _scene_container.get_child(0)
	_instance_root = _session_root.get_node("root")
	_spawnable_manager = _session_root.get_node("SpawnableManager")
	_registry = _spawnable_manager.get_node("Registry")

	_mesh_instance = await _spawnable_manager.create_spawnable("MeshInstance3D")
	return


## This is executed after all of the tests have completed.
func after() -> void:
	_runner = null
	return


## Make sure that the scene and manager references were resolved.
func test_setup_scene() -> void:
	assert(_scene_container != null)
	assert(_session_root != null)
	assert(_instance_root != null)
	assert(_spawnable_manager != null)
	assert(_registry != null)
	return


## Spawn a node into the session.
func test_spawn_node() -> void:
	assert(_mesh_instance != null)
	var _mesh_instance_is_meshinstance3d: bool = is_instance_of(_mesh_instance, MeshInstance3D)
	var _mesh_instance_registry_entry: MeshInstance3D = _registry.get_spawnable(int(_mesh_instance.name))

	assert(_mesh_instance_is_meshinstance3d == true)
	assert(_mesh_instance_registry_entry == _mesh_instance)
	return


## Select the spawned node with a gizmo and make sure the gizmo registered the selection.
func test_select_with_gizmo() -> void:
	_gizmo = await _spawnable_manager.select_spawnable(int(_mesh_instance.name))
	var _gizmo_is_instance_of_gizmo: bool = is_instance_of(_gizmo, Gizmo3D)

	# A gizmo should have been created and returned.
	assert(_gizmo != null)
	assert(_gizmo_is_instance_of_gizmo == true)

	_gizmo_id = int(_gizmo.name)
	var _gizmo_registry_entry: Node = _registry.get_spawnable(_gizmo_id)
	var _gizmo_in_scene: bool = _instance_root.has_node(str(_gizmo_id))
	var _gizmo_selected_mesh: bool = _gizmo.is_selected(_mesh_instance)
	var _gizmo_selected_count: int = _gizmo.get_selected_count()

	# The gizmo is a spawnable not visible in the player inspector (scene_node boolean in node metadata) that lives in the scene (direct child of session root).
	assert(_gizmo_registry_entry == _gizmo)
	assert(_gizmo_in_scene == true)

	# The spawnable was selected with the gizmo.
	assert(_gizmo_selected_mesh == true)
	assert(_gizmo_selected_count == 1)
	return


## Deselect the spawnable with the gizmo and make sure the selection was cleared.
func test_deselect_spawnable() -> void:
	# Gizmo exists in the scene. This means something is selected.
	assert(_gizmo != null)

	# The gizmo selected our target _mesh_instance.
	var _gizmo_selected_mesh: bool = _gizmo.is_selected(_mesh_instance)
	assert(_gizmo_selected_mesh == true)

	# Trigger the deselect.
	await _spawnable_manager.deselect_spawnable(_gizmo_id)

	# The spawnable was deselected.
	assert(_gizmo == null)
	return


## Spawn a amount of MeshInstance3Ds, select each one with a gizmo, then deselect every spawnable.
## This double-checks that no Gizmo3D nodes linger in the scene.
func test_many_gizmos_no_lingering() -> void:
	# FIXME: This was written assuming there would be a random amount of spawnables every time this test was ran, I realized that was stupid and made it a static amount. This function could probably be more optimized after this change, but it works so I am not touching it.
	var _amount: int = 50

	# Spawn the amount of spawnables up front.
	var _meshes: Array[Node] = []
	for _index in _amount:
		var _new_mesh: Node = await _spawnable_manager.create_spawnable("MeshInstance3D")
		_meshes.append(_new_mesh)

	var _mesh_count: int = _meshes.size()

	# There should be exactly _amount spawnables.
	assert(_mesh_count == _amount)

	# For every spawnable, select it with a gizmo, then deselect it.
	for _mesh in _meshes:
		var _gizmo_node: Node = await _spawnable_manager.select_spawnable(int(_mesh.name))
		assert(_gizmo_node != null)

		var _gizmo_is_gizmo: bool = is_instance_of(_gizmo_node, Gizmo3D)
		var _gizmo_selected_mesh: bool = _gizmo_node.is_selected(_mesh)
		var _gizmo_selected_count: int = _gizmo_node.get_selected_count()

		# A gizmo should have been created and it should have selected the spawnable.
		assert(_gizmo_is_gizmo == true)
		assert(_gizmo_selected_mesh == true)
		assert(_gizmo_selected_count == 1)

		var _gizmo_id_local: int = int(_gizmo_node.name)

		# Trigger the deselect.
		await _spawnable_manager.deselect_spawnable(_gizmo_id_local)

		# The gizmo must no longer exist in the scene.
		var _gizmo_registry_entry: Node = _registry.get_spawnable(_gizmo_id_local)
		var _gizmo_in_registry: bool = _registry._gizmos.has(_gizmo_id_local)
		var _gizmo_in_scene: bool = _instance_root.has_node(str(_gizmo_id_local))
		assert(_gizmo_registry_entry == null)
		assert(_gizmo_in_registry == false)
		assert(_gizmo_in_scene == false)

	# The registry no longer contains any gizmos.
	var _registry_gizmo_count: int = _registry._gizmos.size()
	assert(_registry_gizmo_count == 0)

	# The scene tree contains no Gizmo3D nodes at all.
	var _scene_gizmo_count: int = _count_gizmo_nodes(_session_root)
	assert(_scene_gizmo_count == 0)
	return


## Recursively counts the Gizmo3D nodes that exist under the given node in the scene tree.
func _count_gizmo_nodes(node: Node) -> int:
	var _total: int = 0
	var _node_is_gizmo: bool = is_instance_of(node, Gizmo3D)
	if _node_is_gizmo == true:
		_total += 1
	for _child in node.get_children():
		_total += _count_gizmo_nodes(_child)
	return _total
