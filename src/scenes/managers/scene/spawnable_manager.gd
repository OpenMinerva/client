# --- License
# File: /client/src/scenes/managers/scene/spawnable_manager.gd
# Project: OpenMinerva
# Created Date: 18 May 2026
# Copyright (c) 2026 OpenMinerva Contributors
# License: MIT License
# --- License
extends Node
## This file handles the spawnable management for a session. All synchronization and physics are handled through this file.

@onready var app_scene_m: Node = get_tree().root.find_child("AppSceneManager", true, false)
@onready var app_network_m: Node = get_tree().root.find_child("AppNetworkManager", true, false)
@onready var instance_root: Node = get_parent().get_node("root")
@onready var rpcawaiter: Node = get_parent().get_node("RpcAwaiter")
@onready var session_signalbus: Node = get_node("../SignalBus")
@onready var registry: Node = get_node("./Registry")
@onready var spawnables: Node = get_node("Spawnables")
@onready var resources: Node = get_node("Resources")
@onready var gizmos: Node = get_node("Gizmos")


func _physics_process(_delta):
	if !is_multiplayer_authority():
		return

	for spawnable in registry.get_all_spawnable():
		if spawnable.get_class() != "RigidBody3D":
			continue

		if spawnable.sleeping == true:
			continue

		transform_spawnable(int(spawnable.name), spawnable.transform)
	return


@rpc("any_peer", "reliable")
func sync_all() -> void:
	if !is_multiplayer_authority():
		return

	var _spawnable_list: Array[Node] = registry.get_all_spawnable()
	var _caller_id: int = spawnables._get_caller_id()
	GlobalLogger.log("Received a request to sync all nodes from '%s'" % _caller_id, Enum.LogLevel.INFO)
	GlobalLogger.log("Registry size: '%s'" % _spawnable_list.size())

	for spawnable in _spawnable_list:
		if ("transform" in spawnable) == false:
			# We can't transform something without a transform field!
			GlobalLogger.log("'%s' does not have a transform. Not sending a transform." % spawnable.name)
			continue

		GlobalLogger.log("Sending transform for '%s'" % spawnable.name)
		spawnables.set_transform.rpc_id(_caller_id, int(spawnable.name), spawnable.transform)
	return


## Create a spawnable in the session. This is an abstraction that will automatically handle the networking between the host and the client. If the host attempts to call this function in a session, they will call `_session_create_spawnable` directly. If a client calls this function, the client will automatically `rpc` the `_session_create_spawnable` to the host.
## [param node_type] is a string name of the type of node to spawn.
## [param node_parent] is the node id of the parent node to spawn. When the node is spawned, the node is automatically parented.
func create_spawnable(node_type: String, node_parent: int = -1) -> Node:
	if multiplayer.is_server():
		GlobalLogger.log("Spawning node '%s'" % node_type)
		var _spawnable_id: int = spawnables.session_create_spawnable(node_type, node_parent)
		var _spawnable_db_entry: Node = registry.get_spawnable(_spawnable_id)

		if _spawnable_db_entry == null:
			return null

		return _spawnable_db_entry
	else:
		GlobalLogger.log("Requesting a spawn of node '%s'" % node_type)
		var _spawnable_id: int = await rpcawaiter.send_rpc(1, spawnables.session_create_spawnable.bind(node_type, node_parent))
		var _spawnable_db_entry: Node = registry.get_spawnable(_spawnable_id)
		if _spawnable_db_entry == null:
			return null
		return _spawnable_db_entry


## Destroy a spawnable in the session. This is an abstraction that will automatically handle the networking between the host and the client. If the host attempts to call this function in a session, they will call `_session_destroy_spawnable` directly. If a client calls this function, the client will automatically `rpc` the `_session_destroy_spawnable` to the host.
## [param node_id] is the id of the node to destroy.
func destroy_spawnable(node_id: int) -> void:
	if multiplayer.is_server():
		GlobalLogger.log("Destroying node '%s'" % node_id)
		spawnables.session_destroy_spawnable(node_id)
		return
	else:
		GlobalLogger.log("Requesting a destroy of node '%s'" % node_id)
		await rpcawaiter.send_rpc(1, spawnables.session_destroy_spawnable.bind(node_id))
		return


## Parent a spawnable in the session to another spawnable. This is an abstraction that will automatically handle the networking between the host and the client. If the host attempts to call this function in a session, they will call `session_parent_spawnable` directly. If a client calls this function, the client will automatically `rpc` the `session_parent_spawnable` to the host.
## [param node_id] is the id of the node to parent.
## [param parent_id] is the id of the node to parent to.
func parent_spawnable(node_id: int, parent_id: int = -1) -> void:
	if multiplayer.is_server():
		GlobalLogger.log("Parenting node '%s' to '%s'" % [node_id, parent_id])
		spawnables.session_parent_spawnable(node_id, parent_id)
		return
	else:
		GlobalLogger.log("Requesting a parent of node '%s' to '%s'" % [node_id, parent_id])
		await rpcawaiter.send_rpc(1, spawnables.session_parent_spawnable.bind(node_id, parent_id))
		return


## Transform a spawnable in the session in 3D space. This is an abstraction that will automatically handle the networking between the host and the client. If the host attempts to call this function in a session, they will call `session_transform_spawnable` directly. If a client calls this function, the client will automatically `rpc` the `session_transform_spawnable` to the host.
func transform_spawnable(node_id: int, transform: Transform3D, ignore_sender: bool = true) -> void:
	if multiplayer.is_server():
		# GlobalLogger.log("Transforming node '%s'." % node_id)
		spawnables.session_transform_spawnable(node_id, transform, ignore_sender)
		return
	else:
		# GlobalLogger.log("Requesting a transform of node '%s'" % node_id)
		await rpcawaiter.send_rpc(1, spawnables.session_transform_spawnable.bind(node_id, transform, ignore_sender))
		return


## Select a spawnable with a gizmo. This is an abstraction that will automatically handle the networking between the host and the client. Only one node can be selected at a time.
## [param node_id] is the node_id to select.
func select_spawnable(node_id: int) -> Node:
	if multiplayer.is_server():
		GlobalLogger.log("Selecting node '%s'." % node_id)
		var _gizmo_id: int = gizmos.session_select_spawnable(node_id)
		var _spawnable_db_entry: Node = registry.get_spawnable(_gizmo_id)
		if _spawnable_db_entry == null:
			return null
		return _spawnable_db_entry
	else:
		GlobalLogger.log("Requesting a selection of node '%s'" % node_id)
		var _gizmo_id: int = await rpcawaiter.send_rpc(1, gizmos.session_select_spawnable.bind(node_id))

		var _spawnable_db_entry: Node = registry.get_spawnable(_gizmo_id)
		if _spawnable_db_entry == null:
			return null
		return _spawnable_db_entry


## Deselect a spawnable with a gizmo. This is an abstraction that will automatically handle the networking between the host and the client. Only one node can be selected at a time. In effect, this will destroy the gizmo, but it has some extra checks and function calls to make sure that the application does not have an error.
## [param gizmo_id] is the id of the gizmo node to deselect.
func deselect_spawnable(gizmo_id: int) -> void:
	if multiplayer.is_server():
		GlobalLogger.log("Destroying gizmo '%s'." % gizmo_id)
		gizmos.session_deselect_spawnable(gizmo_id)
		return
	else:
		GlobalLogger.log("Requesting a destruction of gizmo '%s'." % gizmo_id)
		await rpcawaiter.send_rpc(1, gizmos.session_deselect_spawnable.bind(gizmo_id))
		return


## Set a property on a spawnable or on a resource in the session. This is an abstraction that will automatically handle the networking between the host and the client.
## [param target_id] is the id of the spawnable or resource to set the property on.
## [param property_name] is the name of the property to set.
## [param property_value] is the value to set for the property.
func set_property(target_id: int, property_name: String, property_value: Variant) -> void:
	var _property_function_call: Callable

	if registry.is_asset(target_id) == true:
		_property_function_call = resources.session_set_property
	else:
		_property_function_call = spawnables.session_set_property

	if multiplayer.is_server() == true:
		GlobalLogger.log("Setting property '%s' on '%s' to '%s'" % [property_name, target_id, property_value])
		await _property_function_call.callv([target_id, property_name, property_value])
		return
	else:
		GlobalLogger.log("Requesting property set '%s' on '%s' to '%s'" % [property_name, target_id, property_value])
		await rpcawaiter.send_rpc(1, _property_function_call.bind(target_id, property_name, property_value))
		return


@rpc("any_peer", "reliable")
func set_resource(node_id: int, property_name: String, resource_id: int) -> void:
	# NOTE: This resource settter is very basic and only works as a way for initializing a joining peer on the session.
	# There is not a complex nor complete lifecycle management for these assets.
	var _my_id: int = app_network_m.registry.get_peer_id(app_scene_m.active_session)
	var _caller_id: int = multiplayer.get_remote_sender_id()

	if _my_id == 1:
		var _resource: Resource = get_resource_by_id(resource_id)

		if _resource == null:
			GlobalLogger.log("Resource '%s' is in invalid state." % resource_id, Enum.LogLevel.ERROR)
			return

		set_resource_on_spawnable.rpc(node_id, property_name, resource_id)

		# FIXME: When a node gets deleted, there is no cleanup for the Registry.
		registry.add_relation(node_id, property_name, resource_id)
	else:
		await rpcawaiter.send_rpc(1, set_resource.bind(node_id, property_name, resource_id))
		return
	return


@rpc("call_local", "authority", "reliable")
func set_resource_on_spawnable(node_id: int, property_name: String, resource_id: int) -> void:
	var _resource: Resource = get_resource_by_id(resource_id)

	spawnables.set_property(node_id, property_name, _resource)
	return


## Create a resource in the session. This is an abstraction that will automatically handling networking.
## [param resource_type] is a string name of the type of the resource to spawn.
## [param properties] is an array of properties to set in the resource when creating it.
func create_resource(resource_type: String, properties: Array = []) -> Resource:
	if multiplayer.is_server():
		var _resource_id: int = resources.session_create_resource(resource_type, properties)
		var _resource_db_entry: Resource = registry.get_asset(_resource_id)

		if _resource_db_entry == null:
			return null

		return _resource_db_entry
	else:
		GlobalLogger.log("Requesting a spawn of resource '%s'" % resource_type)
		var _resource_id: int = await rpcawaiter.send_rpc(1, resources.session_create_resource.bind(resource_type, properties))
		var _resource_db_entry: Resource = registry.get_asset(_resource_id)

		if _resource_db_entry == null:
			return null

		return _resource_db_entry


func receive_database(state: Dictionary) -> void:
	var _my_id: int = app_network_m.registry.get_peer_id(app_scene_m.active_session)

	GlobalLogger.log("[%s] Receiving spawnable registry with %d entries" % [_my_id, -1])

	for _spawnable in state.spawnables:
		var _spawnable_type = "Node3D"

		if _spawnable.metadata.has("spawnable_type") == true:
			_spawnable_type = _spawnable.metadata.spawnable_type

		GlobalLogger.log("Spawning '%s' as '%s'." % [_spawnable.id, _spawnable_type])
		spawnables.create(_spawnable_type, 0, int(_spawnable.parent), int(_spawnable.id), true)

	for _resource in state.resources:
		var _formatted_array: Array[Dictionary] = []

		for _key in _resource.properties.keys():
			var _dictionary: Dictionary = { "name": null, "value": null }
			_dictionary.name = _key
			_dictionary.value = _resource.properties[_key]
			_formatted_array.append(_dictionary)

		resources.create(_resource.metadata.class, _formatted_array, int(_resource.id))

	for _relation in state.relations:
		# Get the target
		var _target: Variant = get_by_id(_relation.node)
		if _target == null:
			_target = get_resource_by_id(_relation.node)

		# Get the value
		var _value: Variant = get_by_id(_relation.value)
		if _value == null:
			_value = get_resource_by_id(_relation.value)

		if _target is Resource:
			resources.set_property(_relation.node, _relation.property, _value)
			continue

		if _target is Node:
			spawnables.set_property(_relation.node, _relation.property, _value)

	GlobalLogger.log("[%s] Registry sync complete." % _my_id)

	return


func get_by_id(spawnable_id: int) -> Node:
	var _db_entry: Node = registry.get_spawnable(spawnable_id)

	if _db_entry == null:
		return null

	return _db_entry


func get_resource_by_id(resource_id: int) -> Resource:
	var _asset_db_entry: Resource = registry.get_asset(resource_id)

	if _asset_db_entry == null:
		return null

	return _asset_db_entry
