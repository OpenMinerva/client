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
@onready var player_m: Node = get_node("../PlayerManager")
@onready var registry: Node = get_node("./Registry")
@onready var spawnables: Node = get_node("Spawnables")
@onready var gizmos: Node = get_node("Gizmos")


func _physics_process(_delta):
	if !is_multiplayer_authority():
		return

	for spawnable in registry.get_all_spawnable():
		if spawnable.get_class() != "RigidBody3D":
			continue
		if spawnable.node.sleeping == true:
			continue

		transform_spawnable(spawnable.id, spawnable.node.transform)
	return


@rpc("any_peer", "reliable")
func sync_all() -> void:
	if !is_multiplayer_authority():
		return

	var _database: Array[Node] = registry.get_all_spawnable()
	var _caller_id: int = spawnables._get_caller_id()
	GlobalLogger.log("Received a request to sync all nodes from '%s'" % _caller_id, Enum.LogLevel.INFO)
	GlobalLogger.log("Database size: '%s'" % _database.size())

	for spawnable in _database:
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


@rpc("call_local", "any_peer", "reliable")
func set_metadata(node_id: int, metadata_name: String, metadata_value: Variant) -> void:
	var _my_id: int = app_network_m.registry.get_peer_id(app_scene_m.active_session)
	var _caller_id: int = multiplayer.get_remote_sender_id()

	if _my_id == 1:
		set_metadata_on_spawnable.rpc(node_id, metadata_name, metadata_value)
	else:
		await rpcawaiter.send_rpc(1, set_property.bind(node_id, metadata_name, metadata_value))
		return

	return


@rpc("call_local", "any_peer", "reliable")
func set_property(node_id: int, property_name: String, property_value: Variant) -> void:
	# I think this function might need to get axed. I am now working on editing resources directly instead of though a path. 
	# That, or this function should be renamed to a more specific role as this function is still used for translating physical nodes in the scene and other surface-level node values.
	var _my_id: int = app_network_m.registry.get_peer_id(app_scene_m.active_session)
	var _caller_id: int = multiplayer.get_remote_sender_id()

	if _my_id == 1:
		set_property_on_spawnable.rpc(node_id, property_name, property_value)
	else:
		await rpcawaiter.send_rpc(1, set_property.bind(node_id, property_name, property_value))
		return
	return


@rpc("call_local", "any_peer", "reliable")
func set_property_on_resource(resource_id: int, property_name: String, property_value: Variant) -> void:
	var _my_id: int = app_network_m.registry.get_peer_id(app_scene_m.active_session)
	var _caller_id: int = multiplayer.get_remote_sender_id()

	if _my_id == 1:
		set_property_on_resource_internal.rpc(resource_id, property_name, property_value)
		if property_value is Resource:
			registry.add_relation(resource_id, property_name, int(property_value.get_name()))
	else:
		await rpcawaiter.send_rpc(1, set_property_on_resource.bind(resource_id, property_name, property_value))
		return
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

		# FIXME: When a node gets deleted, there is no cleanup for the database.
		registry.add_relation(node_id, property_name, resource_id)
	else:
		await rpcawaiter.send_rpc(1, set_resource.bind(node_id, property_name, resource_id))
		return
	return


@rpc("call_local", "authority", "reliable")
func set_resource_on_spawnable(node_id: int, property_name: String, resource_id: int) -> void:
	var _resource: Resource = get_resource_by_id(resource_id)

	set_property_on_spawnable(node_id, property_name, _resource)
	return


@rpc("any_peer", "reliable")
func set_authority(node_id: int, peer_id: int) -> void:
	# TODO: Only allow the host to call this function.
	var _my_id: int = app_network_m.registry.get_peer_id(app_scene_m.active_session)
	var _caller_id: int = multiplayer.get_remote_sender_id()

	if _my_id == 1:
		set_authority_on_spawnable.rpc(node_id, peer_id)
	else:
		await rpcawaiter.send_rpc(1, set_authority.bind(node_id, peer_id))
	return


@rpc("call_local", "any_peer", "reliable")
func create_asset(asset_type: String, properties: Array) -> Variant:
	var my_id: int = app_network_m.registry.get_peer_id(app_scene_m.active_session)
	var caller_id: int = multiplayer.get_remote_sender_id()
	GlobalLogger.log("[%s] Creating Asset '%s'." % [my_id, asset_type])

	if my_id == 1:
		# This was a host calling this function.
		var _target_id: String = str(registry.get_active_id())

		# Actually spawn in the asset for us, and all clients.
		var _asset = spawn_asset(asset_type, properties, _target_id)
		spawn_asset.rpc(asset_type, properties, _target_id)

		var _asset_db_entry: Resource = registry.get_asset(_asset)

		if caller_id != 0 && caller_id != my_id:
			# This call originated from a client, we need to return a reference to the spawned asset, and not the asset itself.
			return int(_asset_db_entry.get_name())

		return _asset_db_entry
	else:
		# Call on the host to create (and sync) the resource.
		var _asset: int = await rpcawaiter.send_rpc(1, create_asset.bind(asset_type, properties))

		# We have the asset name (id), we need to find it in the asset_database.

		var _asset_db_entry: Resource = registry.get_asset(_asset)
		# Return the resource directly.
		return _asset_db_entry


@rpc("call_local", "authority", "reliable")
func set_metadata_on_spawnable(node_id: int, metadata_name: String, metadata_value: Variant) -> void:
	var _entity_db: Node = get_by_id(node_id)

	# TODO: Error check.
	if _entity_db == null:
		return

	GlobalLogger.log("Adjusting metadata '%s' on node '%s'." % [metadata_name, node_id])
	_entity_db.set_meta(metadata_name, metadata_value)
	session_signalbus.node_metadata_change.emit(_entity_db)

	return


@rpc("call_local", "authority", "reliable")
func set_property_on_spawnable(node_id: int, property_name: String, property_value: Variant):
	var _entity_db: Node = get_by_id(node_id)

	if _entity_db == null:
		return

	_entity_db.set_indexed(property_name, property_value)
	return


@rpc("call_local", "authority", "reliable")
func set_property_on_resource_internal(resource_id: int, property_name: String, property_value: Variant):
	var _entity_db: Resource = get_resource_by_id(resource_id)

	if _entity_db == null:
		return

	_entity_db.set_indexed(property_name, property_value)
	return


@rpc("call_local", "authority", "reliable")
func set_authority_on_spawnable(node_id: int, peer_id: int) -> void:
	# TODO: Only allow the host to call this function.
	var _entity_db = get_by_id(node_id)

	# TODO: Error Check

	_entity_db.node.set_multiplayer_authority(peer_id)

	GlobalLogger.log("Giving peer '%s' authority for node '%s'." % [peer_id, node_id])
	return


func receive_database(state: Dictionary) -> void:
	var _my_id: int = app_network_m.registry.get_peer_id(app_scene_m.active_session)

	GlobalLogger.log("[%s] Receiving spawnable database with %d entries" % [_my_id, -1])

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

		spawn_asset(_resource.metadata.class, _formatted_array, str(_resource.id))

	for _relation in state.relations:
		var _resource: Resource = get_resource_by_id(_relation.value)
		set_property_on_spawnable(_relation.node, _relation.property, _resource)

		# HACK: Shaders get a different code path. This should be improved to a more robust solution.
		if _relation.property == "shader":
			set_property_on_resource_internal(_relation.node, _relation.property, _resource)

	GlobalLogger.log("[%s] Database sync complete." % _my_id)

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


@rpc("authority", "reliable")
func spawn_asset(asset_type, properties, id: String = "") -> int:
	GlobalLogger.log("Spawning '%s'." % asset_type)

	# Create the resource on our end, and include it in the database.
	var _resource: Resource = _spawn_resource(asset_type, properties, id)

	# Return the _asset_database id of the resource.
	return int(_resource.get_name())


func _spawn_resource(resource_class: String, properties: Array, asset_id: String = str(registry.get_active_id())) -> Resource:
	var _resource: Resource = null

	# Create the resource
	_resource = ClassDB.instantiate(resource_class)

	# Set the resource properties
	for _prop in properties:
		if _prop.name == "resource_path":
			_resource.take_over_path(_prop.value)
			continue

		_resource.set_indexed(_prop.name, _prop.value)

	# Add the resource to the database
	registry.add_asset(_resource, int(asset_id))

	# Save the resource class as a metadata field to keep track of what it is.
	_resource.set_meta("class", resource_class)

	# Return the resource
	return _resource
