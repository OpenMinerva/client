# --- License
# File: /client/src/scenes/managers/scene/spawnable_manager.gd
# Project: OpenMinerva
# Created Date: 18 May 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Node

# TODO: Network:
# Node renaming.
# Node reparenting.
# Node position updating.
# TODO: Database:
# Sane _database_id. Don't hardcode 10.
const SPAWNABLE_TEMPLATE: Dictionary = {
	"type": -1,
	"spawner": -1,
	"physics_owner": 1,
	"node": null,
	"parent": -1,
	"id": -1,
	"pretty_name": "ERROR",
}

var _spawnable_network_batches: int = 4
var _database_id: int = 10
var _database: Array[Dictionary] = []
var _asset_database: Array[Dictionary] = []
var _asset_node_relation_database: Array[Dictionary] = []

@onready var app_scene_m: Node = get_tree().current_scene.get_node("SceneManager")
@onready var app_network_m: Node = get_tree().current_scene.get_node("NetworkManager")
@onready var network_m: Node = get_node("../NetworkManager")
@onready var instance_root: Node = get_parent().get_node("root")
@onready var rpcawaiter: Node = get_parent().get_node("RpcAwaiter")
@onready var session_signalbus: Node = get_node("../SignalBus")
@onready var player_m: Node = get_node("../PlayerManager")


# TODO: Handle physics for our items, and
func _physics_process(_delta):
	# NOTE: Networking is done in batches of 4. Meaning 25% of the scene is networked at any given frame.
	# There was no reason in me doing this, but I think I was trying to make it so that you do not have to network so many things in a given instant.
	# As far as I know there was not an existing problem I was trying to solve and I have no idea what I was thinking.
	# However, it's not breaking anything in the current instant so I will leave it in until it proves to be a problem or if I think of a better way of doing this.
	var current_batch: int = Engine.get_physics_frames() % _spawnable_network_batches

	if !is_multiplayer_authority():
		return
	for spawnable in _database:
		if spawnable.type != "RigidBody3D":
			continue
		if spawnable.node.sleeping == true:
			continue
		if spawnable.id % _spawnable_network_batches == current_batch:
			continue

		transform_spawnable.rpc(spawnable.id, spawnable.node.transform)
	return


@rpc("any_peer", "reliable")
func sync_all() -> void:
	if !is_multiplayer_authority():
		return

	for spawnable in _database:
		if spawnable.node == null:
			GlobalLogger.log("Node does not exist.", Enum.LogLevel.WARNING)
			return

		if spawnable.node.has_method("transform") == false:
			# We can't transform something without a transform field!
			return

		set_transform.rpc(spawnable.id, spawnable.node.transform)
	return


@rpc("any_peer", "reliable")
func create(node_type: String, node_parent: int = 0, model_path: String = "") -> Variant:
	var my_id: int = app_network_m._session_db[app_scene_m.active_session].api.get_unique_id()
	var caller_id: int = multiplayer.get_remote_sender_id()
	GlobalLogger.log("[%s] Spawning '%s'." % [my_id, node_type])

	if my_id == 1:
		var _target_id: String = str(_database_id)

		var entity: int = spawn_spawnable(node_type, _target_id, model_path, node_parent)
		spawn_spawnable.rpc(node_type, _target_id, model_path, node_parent)

		# HACK: Reparent the node again so that it gets saved in the database.
		set_parent(entity, node_parent)

		var database_index: int = _database.find_custom(func(entry): return entry.id == entity)
		if caller_id != 0 && caller_id != my_id:
			# This is a client request to spawn.
			# We return the synced node name here so we can get the client-side node later.
			return int(_database[database_index].node.name)

		return _database[database_index].node
	else:
		var entity: int = await rpcawaiter.send_rpc(1, create.bind(node_type, node_parent, model_path))

		# Since we are given the node name, we will need to find the node in our database.
		var database_index: int = _database.find_custom(func(entry): return entry.id == entity)

		# Database index was found, get the node at that index.
		return _database[database_index].node


@rpc("call_local", "any_peer", "reliable")
func destroy(node_id: int) -> Variant:
	if app_network_m._session_db.has(app_scene_m.active_session) == false:
		GlobalLogger.log("Failed to destroy node '%s'." % node_id, Enum.LogLevel.ERROR)
		return

	var my_id: int = app_network_m._session_db[app_scene_m.active_session].api.get_unique_id()
	var caller_id: int = multiplayer.get_remote_sender_id()

	if my_id == 1:
		var _queue = _get_deletion_queue(str(node_id))
		for node in _queue:
			delete_spawnable(node.name)
			delete_spawnable.rpc(node.name)

		if caller_id != 0 && caller_id != my_id:
			# This is a client request to delete
			return

		return
	else:
		await rpcawaiter.send_rpc(1, destroy.bind(node_id))
		return


@rpc("any_peer", "reliable")
func set_transform(node_id: int, p_transform: Transform3D) -> void:
	var _my_id: int = app_network_m._session_db[app_scene_m.active_session].api.get_unique_id()
	var _caller_id: int = multiplayer.get_remote_sender_id()

	if _my_id == 1:
		# TODO: Compress for network?
		transform_spawnable.rpc(node_id, p_transform)
	else:
		await rpcawaiter.send_rpc(1, set_transform.bind(node_id, p_transform))
		return
	return


@rpc("any_peer", "reliable")
func set_property(node_id: int, property_name: String, property_value: Variant) -> void:
	var _my_id: int = app_network_m._session_db[app_scene_m.active_session].api.get_unique_id()
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
	var _my_id: int = app_network_m._session_db[app_scene_m.active_session].api.get_unique_id()
	var _caller_id: int = multiplayer.get_remote_sender_id()

	if _my_id == 1:
		var _resource: Dictionary = get_resource_by_id(resource_id)

		if _resource.has("resource") == false:
			GlobalLogger.log("Resource '%s' is in invalid state.", Enum.LogLevel.ERROR)
			return

		set_property_on_spawnable.rpc(node_id, property_name, _resource.resource)

		# FIXME: When a node gets deleted, there is no cleanup for the database.
		_asset_node_relation_database.append({ "node_id": node_id, "node_property": property_name, "resource_id": resource_id })
	else:
		await rpcawaiter.send_rpc(1, set_resource.bind(node_id, property_name, resource_id))
		return
	return


@rpc("any_peer", "reliable")
func set_authority(node_id: int, peer_id: int) -> void:
	# TODO: Only allow the host to call this function.
	var _my_id: int = app_network_m._session_db[app_scene_m.active_session].api.get_unique_id()
	var _caller_id: int = multiplayer.get_remote_sender_id()

	if _my_id == 1:
		set_authority_on_spawnable.rpc(node_id, peer_id)
	else:
		await rpcawaiter.send_rpc(1, set_authority.bind(node_id, peer_id))
	return


@rpc("call_local", "any_peer", "reliable")
func create_asset(asset_type: String, properties: Array) -> Variant:
	var my_id: int = app_network_m._session_db[app_scene_m.active_session].api.get_unique_id()
	var caller_id: int = multiplayer.get_remote_sender_id()
	GlobalLogger.log("[%s] Creating Asset '%s'." % [my_id, asset_type])

	if my_id == 1:
		# This was a host calling this function.
		var _target_id: String = str(_database_id)

		# Actually spawn in the asset for us, and all clients.
		var _asset = spawn_asset(asset_type, properties)
		spawn_asset.rpc(asset_type, properties)

		var _asset_db_index: int = _asset_database.find_custom(func(entry): return entry.id == _asset)

		if caller_id != 0 && caller_id != my_id:
			# This call originated from a client, we need to return a reference to the spawned asset, and not the asset itself.
			return int(_asset_database[_asset_db_index].resource.name)

		return _asset_database[_asset_db_index].resource
	else:
		# Call on the host to create (and sync) the resource.
		var _asset: int = await rpcawaiter.send_rpc(1, create_asset.bind(asset_type, properties))

		# We have the asset name (id), we need to find it in the asset_database.
		var _asset_db_index: int = _asset_database.find_custom(func(entry): return entry.id == _asset)

		# Return the resource directly.
		return _asset_database[_asset_db_index].resource


@rpc("call_local", "any_peer", "reliable")
func set_parent(node_id: int, parent_node_id: int) -> void:
	var my_id: int = app_network_m._session_db[app_scene_m.active_session].api.get_unique_id()

	GlobalLogger.log("[%s] Setting parent of '%s' to '%s'." % [my_id, node_id, parent_node_id])

	if my_id == 1:
		# Get the node references.
		var _node = get_by_id(node_id)
		var _parent_node = get_by_id(parent_node_id)

		if parent_node_id <= 0:
			# Invalid state, reparent to root.
			_parent_node = { "node": app_scene_m.get_master_root(app_scene_m.active_session) }

		# Send the reparent signal to all clients.
		_set_node_parent.rpc(_node.node, _parent_node.node)

		# Update the database.
		var _db_index: int = _database.find_custom(func(entry): return entry.id == node_id)
		_database[_db_index].parent = parent_node_id
		return
	else:
		# Call on the host to create (and sync) the resource.
		var _asset: int = await rpcawaiter.send_rpc(1, set_parent.bind(node_id, parent_node_id))
		return

	return


# TODO: How would large assets work?
@rpc("authority", "reliable")
func spawn_spawnable(p_type: String, p_name: String = "", p_path: String = "", parent_id: int = 0) -> int:
	var _spawned_entity
	var parent_node = get_parent().get_node("root")

	if parent_id > 1:
		var database_index = _database.find_custom(func(entry): return entry.id == parent_id)
		parent_node = _database[database_index].node

	# HACK: When connecting to the server, the entity of the joining user is attempted to spawn twice. This null check will see if the node already exists on the server by name.
	_spawned_entity = _spawn_node(p_type, 1, parent_node, p_path, p_name)

	if _spawned_entity == null:
		GlobalLogger.log("Tried to spawn in something that already exists? Returning the reference to the existing node.", Enum.LogLevel.WARNING)
		return int(p_name)

	_spawned_entity.owner = parent_node

	session_signalbus.node_created.emit(_spawned_entity)
	return int(_spawned_entity.name)


# TODO: require actioning user
@rpc("authority", "reliable")
func delete_spawnable(node_name: String) -> void:
	GlobalLogger.log("Deleting node '%s'." % node_name)
	var _entry_index = _database.find_custom(func(item): return item.id == int(node_name))
	if _entry_index == -1:
		# This should never happen! The node can never be removed from the scene tree then.
		GlobalLogger.log("'%s' could not be located in the scene tree." % node_name, Enum.LogLevel.ERROR)
		return

	var _entry = _database[_entry_index]

	session_signalbus.node_destroyed.emit(_entry)
	_entry.node.queue_free()
	_database.remove_at(_entry_index)
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
	var _my_id: int = app_network_m._session_db[app_scene_m.active_session].api.get_unique_id()

	GlobalLogger.log("[%s] Receiving spawnable database with %d entries" % [_my_id, database.size()])

	# Spawn in all of the nodes
	for spawnable in database:
		GlobalLogger.log("Spawning '%s' as '%s'." % [spawnable.id, spawnable.type])
		spawn_spawnable(spawnable.type, str(spawnable.id), "", int(spawnable.parent))

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
	var target_entry = _database.find_custom(func(entry): return entry.id == spawnable_id)

	if target_entry == -1:
		return { }

	return _database[target_entry]


func get_resource_by_id(resource_id: int) -> Dictionary:
	var target_entry = _asset_database.find_custom(func(entry): return entry.id == resource_id)

	if target_entry == -1:
		return { }

	return _asset_database[target_entry]


@rpc("authority", "reliable")
func spawn_asset(asset_type, properties, id: String = str(_database_id)) -> int:
	GlobalLogger.log("Spawning '%s'." % asset_type)

	# Create the resource on our end, and include it in the database.
	var _resource: Resource = _spawn_resource(asset_type, properties, id)

	# Return the _asset_database id of the resource.
	return int(_resource.get_name())


@rpc("call_local", "any_peer", "reliable")
func _set_node_parent(node: Node, parent_node: Node) -> void:
	# Change node parent.
	node.reparent(parent_node)
	return


func _spawn_resource(resource_class: String, properties, asset_id: String = str(_database_id)) -> Resource:
	var _resource: Resource = null

	# Create the resource
	_resource = ClassDB.instantiate(resource_class)

	# Set the resource properties
	for _prop in properties:
		_resource.set_indexed(_prop.name, _prop.value)

	# Add the resource to the database
	var _db_id: int = _add_asset_to_database(resource_class, _resource, properties, int(asset_id))

	# Set the resource name
	_resource.set_name(str(_db_id))

	# Return the resource
	return _resource


func _add_asset_to_database(asset_class: String, resource: Resource, props: Array, asset_id: int = 0) -> int:
	# If we are a client, we ignore the database completely, we are supplied the id by the server.
	var _db_entry = {
		"id": 0,
		"asset_class": "",
		"properties": { },
	}

	if asset_id == 0:
		GlobalLogger.log("No asset_id supplied.", Enum.LogLevel.ERROR)
		return 0
	else:
		_db_entry.id = asset_id

	_db_entry.resource = resource
	_db_entry.props = props
	_db_entry.asset_class = asset_class

	_asset_database.append(_db_entry)
	_database_id = _database_id + 1
	return _db_entry.id


func _get_deletion_queue(node_name: String) -> Array:
	var _entry_index = _database.find_custom(func(item): return item.id == int(node_name))
	var _node = _database[_entry_index].node

	var _queue = _add_to_deletion_queue(_node)
	_queue.reverse()
	return _queue


func _add_to_deletion_queue(node: Node, list: Array[Node] = []) -> Array[Node]:
	list.append(node)

	if node.get_meta("deep_delete", true) == false:
		return list

	for child in node.get_children():
		_add_to_deletion_queue(child, list)

	return list


func _spawn_node(node_type: String, node_owner: int, parent: Node = instance_root, model_path = "", node_name: String = str(_database_id)) -> Node:
	var _node: Node
	var _node_name = node_type
	var _node_schema = NSB.get_entry(_node_name)
	var _pretty_name: String

	# FIXME: Not sure if this check is safe
	var _database_index: int = _database.find_custom(func(entry): return entry.id == int(node_name))
	if _database_index > -1:
		GlobalLogger.log("Tried to spawn in a node that already exists.", Enum.LogLevel.ERROR)
		return

	if node_type == "":
		GlobalLogger.log("Tried to spawn in a invalid node.", Enum.LogLevel.ERROR)
		return

	# HACK: Fixes importing skeletons?
	if _node_name == "Model" && model_path == "":
		_node = NSB.build("Node3D")
	else:
		_node = NSB.build(_node_name, model_path)

	# Add to database
	var _db_id = _add_to_database(_node, node_type, node_owner, int(node_name))

	if model_path != "":
		_pretty_name = model_path.get_file()
	else:
		_pretty_name = str(_node_schema.pretty_name)

	# Editor changes
	set_node_visible_to_inspector(_node)
	_node.name = str(_db_id)
	_node.set_meta("pretty_name", _pretty_name)
	_node.set_meta("spawnable_type", node_type)
	_node.set_meta("icon", _node_schema.icon)
	if _node.get("position") != null:
		_node.position = Vector3(0, 0, 0)

	# Add to scene tree
	parent.add_child(_node)
	return _node


func _add_to_database(node: Node, type: String, node_owner: int, node_id: int = 0) -> int:
	# If we are a client, we ignore _database_id entirely.
	var _db_entry = SPAWNABLE_TEMPLATE.duplicate()

	if node_id == 0:
		GlobalLogger.log("No node_id supplied.", Enum.LogLevel.ERROR)
		return 0
	else:
		_db_entry.id = node_id

	_db_entry.node = node
	_db_entry.type = type
	_db_entry.spawner = node_owner
	_database.append(_db_entry)

	_database_id = _database_id + 1

	return _db_entry.id


func _add_collisions_recursive(node: Node):
	var meshes = _find_all_mesh_instances(node)
	var colliders = []

	for mesh in meshes:
		var collision_shape = CollisionShape3D.new()
		var convex_shape = ConvexPolygonShape3D.new()
		convex_shape.set_points(mesh.mesh.get_faces())

		collision_shape.shape = convex_shape
		colliders.append(collision_shape)

	return colliders


func _find_all_mesh_instances(node: Node) -> Array:
	var found = []

	if node is MeshInstance3D:
		found.append(node)

	for child in node.get_children():
		found.append_array(_find_all_mesh_instances(child))

	return found
