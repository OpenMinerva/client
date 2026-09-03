# --- License
# File: /client/src/scenes/managers/scene/spawnable_manager.gd
# Project: OpenMinerva
# Created Date: 18 May 2026
# Copyright (c) 2026 OpenMinerva Contributors
# License: MIT License
# --- License
extends Node
## This file handles the spawnable management for a session. All synchronization and physics are handled through this file.

@onready var app_scene_m: Node = get_tree().current_scene.get_node("SceneManager")
@onready var app_network_m: Node = get_tree().current_scene.get_node("NetworkManager")
@onready var network_m: Node = get_node("../NetworkManager")
@onready var instance_root: Node = get_parent().get_node("root")
@onready var rpcawaiter: Node = get_parent().get_node("RpcAwaiter")
@onready var session_signalbus: Node = get_node("../SignalBus")
@onready var player_m: Node = get_node("../PlayerManager")
@onready var _registry: Node = get_node("Registry")
@onready var _spawnables: Node = get_node("Spawnables")


func _physics_process(_delta):
	if !is_multiplayer_authority():
		return

	for spawnable in _registry.get_all_spawnable():
		if spawnable.type != "RigidBody3D":
			continue
		if spawnable.node.sleeping == true:
			continue

		transform_spawnable.rpc(spawnable.id, spawnable.node.transform)
	return


@rpc("any_peer", "reliable")
func sync_all() -> void:
	if !is_multiplayer_authority():
		return

	var _database: Array[Dictionary] = _registry.get_all_spawnable()
	var caller_id: int = multiplayer.get_remote_sender_id()
	GlobalLogger.log("Received a request to sync all nodes from '%s'" % caller_id, Enum.LogLevel.INFO)
	GlobalLogger.log("Database size: '%s'" % _database.size())

	for spawnable in _database:
		if spawnable.node == null:
			GlobalLogger.log("Node does not exist.", Enum.LogLevel.WARNING)
			continue

		if ("transform" in spawnable.node) == false:
			# We can't transform something without a transform field!
			GlobalLogger.log("'%s' does not have a transform. Not sending a transform." % spawnable.id)
			continue

		GlobalLogger.log("Sending transform for '%s'" % spawnable.id)
		transform_spawnable.rpc(spawnable.id, spawnable.node.transform)
	return


## Create a spawnable in the session. This is an abstraction that will automatically handle the networking between the host and the client. If the host attempts to call this function in a session, they will call `_server_create_spawnable` directly. If a client calls this function, the client will automatically `rpc` the `_server_create_spawnable` to the host.
## [param node_type] is a string name of the type of node to spawn.
## [param node_parent] is the node id of the parent node to spawn. When the node is spawned, the node is automatically parented.
func create_spawnable(node_type: String, node_parent: int = -1) -> Node:
	if multiplayer.is_server():
		GlobalLogger.log("Spawning node '%s'" % node_type)
		var _spawnable_id: int = _spawnables.server_create_spawnable(node_type, node_parent)
		var _spawnable_db_entry: Dictionary = _registry.get_spawnable(_spawnable_id)
		if _spawnable_db_entry.has("node") == false:
			return null
		return _spawnable_db_entry.node
	else:
		GlobalLogger.log("Requesting a spawn of node '%s'" % node_type)
		var _spawnable_id: int = await rpcawaiter.send_rpc(1, _spawnables.server_create_spawnable.bind(node_type, node_parent))
		var _spawnable_db_entry: Dictionary = _registry.get_spawnable(_spawnable_id)
		if _spawnable_db_entry.has("node") == false:
			return null
		return _spawnable_db_entry.node


## Destroy a spawnable in the session. This is an abstraction that will automatically handle the networking between the host and teh client. If the host attempts to call this function in a session, they will call `_server_destroy_spawnable` directly. If a client calls this function, the client will automatically `rpc` the `_server_destroy_spawnable` to the host.
## [param node_id] is the id of the node to destroy.
func destroy_spawnable(node_id: int) -> void:
	if multiplayer.is_server():
		GlobalLogger.log("Destroying node '%s'" % node_id)
		_spawnables.server_destroy_spawnable(node_id)
		return
	else:
		GlobalLogger.log("Requesting a destroy of node '%s'" % node_id)
		var _spawnable_id: int = await rpcawaiter.send_rpc(1, _spawnables._server_destroy_spawnable.bind(node_id))
		return


@rpc("call_local", "any_peer", "reliable")
func select(node_id: int, gizmo_id: int) -> void:
	var _node: Node = _registry.get_spawnable(node_id).node
	var _gizmo: Node = _registry.get_spawnable(gizmo_id).node

	if _node.is_class("Node3D"):
		_gizmo.select(_node)
		_gizmo._set_visibility(get_parent().visible)
		_gizmo.transform_changed.connect(func(_mode, _value): set_transform(node_id, _node.transform))
	return


@rpc("call_local", "any_peer", "reliable")
func deselect(gizmo_id: int) -> void:
	var _gizmo: Node = _registry.get_spawnable(gizmo_id).node
	_gizmo.clear_selection()
	return


@rpc("any_peer", "reliable")
func set_transform(node_id: int, p_transform: Transform3D, ignore_sender: bool = true) -> void:
	var _my_id: int = app_network_m.registry.get_peer_id(app_scene_m.active_session)
	var _caller_id: int = multiplayer.get_remote_sender_id()

	if _my_id == 1:
		var _target_peers: PackedInt32Array = []

		if ignore_sender == false:
			transform_spawnable.rpc(node_id, p_transform)
			return

		transform_spawnable(node_id, p_transform)

		for _peer_id in multiplayer.get_peers():
			if _peer_id != _caller_id:
				_target_peers.append(_peer_id)

		for _target in _target_peers:
			transform_spawnable.rpc_id(_target, node_id, p_transform)
	else:
		await rpcawaiter.send_rpc(1, set_transform.bind(node_id, p_transform, ignore_sender))
		return
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
	var _my_id: int = app_network_m.registry.get_peer_id(app_scene_m.active_session)
	var _caller_id: int = multiplayer.get_remote_sender_id()

	if _my_id == 1:
		set_property_on_spawnable.rpc(node_id, property_name, property_value)
	else:
		await rpcawaiter.send_rpc(1, set_property.bind(node_id, property_name, property_value))
		return
	return


@rpc("any_peer", "reliable")
func set_resource(node_id: int, property_name: String, resource_id: int) -> void:
	# NOTE: This resource settter is very basic and only works as a way for initializing a joining peer on the server.
	# There is not a complex nor complete lifecycle management for these assets.
	var _my_id: int = app_network_m.registry.get_peer_id(app_scene_m.active_session)
	var _caller_id: int = multiplayer.get_remote_sender_id()

	if _my_id == 1:
		var _resource: Dictionary = get_resource_by_id(resource_id)

		if _resource.has("resource") == false:
			GlobalLogger.log("Resource '%s' is in invalid state." % resource_id, Enum.LogLevel.ERROR)
			return

		set_resource_on_spawnable.rpc(node_id, property_name, resource_id)

		# FIXME: When a node gets deleted, there is no cleanup for the database.
		_registry.add_relation(node_id, property_name, resource_id)
	else:
		await rpcawaiter.send_rpc(1, set_resource.bind(node_id, property_name, resource_id))
		return
	return


@rpc("call_local", "authority", "reliable")
func set_resource_on_spawnable(node_id: int, property_name: String, resource_id: int) -> void:
	var _resource: Dictionary = get_resource_by_id(resource_id)

	set_property_on_spawnable(node_id, property_name, _resource.resource)
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
		var _target_id: String = str(_registry.get_active_id())

		# Actually spawn in the asset for us, and all clients.
		var _asset = spawn_asset(asset_type, properties, _target_id)
		spawn_asset.rpc(asset_type, properties, _target_id)

		var _asset_db_entry: Dictionary = _registry.get_asset(_asset)

		if caller_id != 0 && caller_id != my_id:
			# This call originated from a client, we need to return a reference to the spawned asset, and not the asset itself.
			return int(_asset_db_entry.resource.get_name())

		return _asset_db_entry.resource
	else:
		# Call on the host to create (and sync) the resource.
		var _asset: int = await rpcawaiter.send_rpc(1, create_asset.bind(asset_type, properties))

		# We have the asset name (id), we need to find it in the asset_database.

		var _asset_db_entry: Dictionary = _registry.get_asset(_asset)
		# Return the resource directly.
		return _asset_db_entry.resource


@rpc("call_local", "any_peer", "reliable")
func set_parent(node_id: int, parent_node_id: int) -> void:
	var my_id: int = app_network_m.registry.get_peer_id(app_scene_m.active_session)

	GlobalLogger.log("[%s] Setting parent of '%s' to '%s'." % [my_id, node_id, parent_node_id])

	if my_id == 1:
		# Get the node references.
		var _node = get_by_id(node_id)

		if _node == { }:
			GlobalLogger.log("Failed to find the node: '%s'" % node_id, Enum.LogLevel.WARNING)
			return

		# Send the reparent signal to all clients.
		_set_node_parent.rpc(int(_node.node.name), parent_node_id)

		# Update the database.
		var _db_entry = _registry.get_spawnable(node_id)
		_db_entry.parent = parent_node_id
	else:
		# Call on the host to create (and sync) the resource.
		await rpcawaiter.send_rpc(1, set_parent.bind(node_id, parent_node_id))

	return


@rpc("call_local", "authority", "reliable")
func transform_spawnable(node_id: int, transform: Transform3D) -> void:
	var _entity_db = get_by_id(node_id)

	if _entity_db == { }:
		GlobalLogger.log("Could not locate node id '%s'" % node_id, Enum.LogLevel.WARNING)
		return

	if _entity_db.node == null:
		GlobalLogger.log("Could not locate node '%s'" % node_id, Enum.LogLevel.WARNING)
		return

	_entity_db.node.transform = transform
	return


@rpc("call_local", "authority", "reliable")
func set_metadata_on_spawnable(node_id: int, metadata_name: String, metadata_value: Variant) -> void:
	var _entity_db = get_by_id(node_id)

	# TODO: Error check.
	if _entity_db == { }:
		return

	GlobalLogger.log("Adjusting metadata '%s' on node '%s'." % [metadata_name, node_id])
	_entity_db.node.set_meta(metadata_name, metadata_value)
	session_signalbus.node_metadata_change.emit(_entity_db.node)

	return


@rpc("call_local", "authority", "reliable")
func set_property_on_spawnable(node_id: int, property_name: String, property_value: Variant):
	var _entity_db = get_by_id(node_id)

	if _entity_db == { }:
		return

	_entity_db.node.set_indexed(property_name, property_value)
	return


@rpc("call_local", "authority", "reliable")
func set_authority_on_spawnable(node_id: int, peer_id: int) -> void:
	# TODO: Only allow the host to call this function.
	var _entity_db = get_by_id(node_id)

	# TODO: Error Check

	_entity_db.node.set_multiplayer_authority(peer_id)

	GlobalLogger.log("Giving peer '%s' authority for node '%s'." % [peer_id, node_id])
	return


func receive_database(database: Array, players: Dictionary, assets: Array, asset_relations: Array) -> void:
	var _my_id: int = app_network_m.registry.get_peer_id(app_scene_m.active_session)

	GlobalLogger.log("[%s] Receiving spawnable database with %d entries" % [_my_id, database.size()])

	# Spawn in all of the nodes
	for spawnable in database:
		GlobalLogger.log("Spawning '%s' as '%s'." % [spawnable.id, spawnable.type])
		_spawnables._server_create_spawnable(spawnable.type, int(spawnable.parent), int(spawnable.id))

	# Spawn in all of the assets
	for asset in assets:
		GlobalLogger.log("Spawning asset '%s'." % [asset.id])
		spawn_asset(asset.asset_class, asset.props, str(asset.id))

	# Set the relations of the assets to the nodes.
	for relation in asset_relations:
		var _asset = get_resource_by_id(relation.resource_id)

		set_property_on_spawnable(relation.node_id, relation.node_property, _asset.resource)
		continue

	GlobalLogger.log("[%s] Database sync complete." % _my_id)

	# Update the player database.
	player_m.set_player_database(players)

	return


func set_node_visible_to_inspector(node: Node) -> void:
	var nodes = get_all_node_children(node)

	# Check if we had already declared this node to be hidden.
	if node.get_meta("scene_node", true) == false:
		return

	for target in nodes:
		target.set_meta("scene_node", true)

	return


func get_all_node_children(node: Node) -> Array:
	var nodes = []

	if node:
		nodes.append(node)
	for child in node.get_children():
		nodes.append_array(get_all_node_children(child))

	return nodes


func get_by_id(spawnable_id: int) -> Dictionary:
	var _db_entry: Dictionary = _registry.get_spawnable(spawnable_id)

	if _db_entry == { }:
		return { }

	return _db_entry


func get_resource_by_id(resource_id: int) -> Dictionary:
	var _asset_db_entry: Dictionary = _registry.get_asset(resource_id)

	if _asset_db_entry == { }:
		return { }

	return _asset_db_entry


@rpc("authority", "reliable")
func spawn_asset(asset_type, properties, id: String = "") -> int:
	GlobalLogger.log("Spawning '%s'." % asset_type)

	# Create the resource on our end, and include it in the database.
	var _resource: Resource = _spawn_resource(asset_type, properties, id)

	# Return the _asset_database id of the resource.
	return int(_resource.get_name())


# FIXME: I made some changes to this function I am not proud of, but it is working. Try to improve the flow for using fallback-to-root.
@rpc("call_local", "any_peer", "reliable")
func _set_node_parent(node_id: int, parent_node_id: int) -> void:
	var _node: Dictionary = get_by_id(node_id)
	var _parent: Dictionary = get_by_id(parent_node_id)

	if _parent == { }:
		_parent = { "node": app_scene_m.get_master_root(app_scene_m.active_session) }

	if _node.has("node") && _parent.has("node"):
		# Change node parent.
		_node.node.reparent(_parent.node)
		return

	return


func _spawn_resource(resource_class: String, properties: Array, asset_id: String = str(_registry.get_active_id())) -> Resource:
	var _resource: Resource = null

	# Create the resource
	_resource = ClassDB.instantiate(resource_class)

	# Set the resource properties
	for _prop in properties:
		if _prop.name == "resource_path":
			# Don't set the resource path property, this causes an error, and is not required anyways.
			continue
		_resource.set_indexed(_prop.name, _prop.value)

	# Add the resource to the database
	var _db_id: int = _add_asset_to_database(resource_class, _resource, properties, int(asset_id))

	# Set the resource name
	_resource.set_name(str(_db_id))

	# Return the resource
	return _resource


func _add_asset_to_database(asset_class: String, resource: Resource, props: Array, asset_id: int = 0) -> int:
	GlobalLogger.log("Deprecated call '%s'" % get_stack()[0]["function"], Enum.LogLevel.WARNING)
	return _registry.add_asset(asset_class, resource, props, asset_id)
