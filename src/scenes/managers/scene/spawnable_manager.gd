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
	"node": "",
	"id": -1,
	"pretty_name": "ERROR",
}

var _spawnable_network_batches: int = 4
var _database_id = 10
var _database := []

@onready var app_scene_m: Node = get_tree().current_scene.get_node("SceneManager")
@onready var app_network_m: Node = get_tree().current_scene.get_node("NetworkManager")
@onready var network_m = get_node("../NetworkManager")
@onready var instance_root = get_parent().get_node("root")
@onready var rpcawaiter = get_parent().get_node("RpcAwaiter")
@onready var session_signalbus: Node = get_node("../SignalBus")


# TODO: Handle physics for our items, and
func _physics_process(_delta):
	# NOTE: Networking is done in batches of 4. Meaning 25% of the scene is networked at any given frame.
	# There was no reason in me doing this, but I think I was trying to make it so that you do not have to network so many things in a given instant.
	# As far as I know there was not an existing problem I was trying to solve and I have no idea what I was thinking.
	# However, it's not breaking anything in the current instant so I will leave it in until it proves to be a problem or if I think of a better way of doing this.
	var current_batch = Engine.get_physics_frames() % _spawnable_network_batches

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


# FIXME: This is a test of syncing all positions of all spawnables. This probably is not going to be robust enough.
func sync_all() -> void:
	if !is_multiplayer_authority():
		return
	for spawnable in _database:
		set_transform.rpc(spawnable.id, spawnable.node.transform)
	return


@rpc("any_peer", "reliable")
func create(node_type: String, node_parent: int = 0, model_path: String = "") -> Variant:
	var my_id: int = app_network_m._database.sessions_api[app_scene_m.active_session].get_unique_id()
	var caller_id: int = multiplayer.get_remote_sender_id()

	if my_id == 1:
		var entity = spawn_spawnable(node_type, "", model_path, node_parent)
		spawn_spawnable.rpc(node_type, "", model_path, node_parent)

		var database_index: int = _database.find_custom(func(entry): return entry.id == entity)
		if caller_id != 0 && caller_id != my_id:
			# This is a client request to spawn
			return int(_database[database_index].node.name)

		return _database[database_index].node
	else:
		# TODO: Graceful error for when RPC target is not found?
		var entity = await rpcawaiter.send_rpc(1, create.bind(node_type, node_parent, model_path))
		var database_index: int = _database.find_custom(func(entry): return entry.id == entity)
		return _database[database_index].node

@rpc("any_peer", "reliable")
func destroy(node_id: int) -> Variant:
	var my_id: int = app_network_m._database.sessions_api[app_scene_m.active_session].get_unique_id()
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
func set_transform(node_id: int, transform: Transform3D) -> void:
	var _my_id: int = app_network_m._database.sessions_api[app_scene_m.active_session].get_unique_id()
	var _caller_id: int = multiplayer.get_remote_sender_id()

	if _my_id == 1:
		# TODO: Compress for network?
		transform_spawnable.rpc(node_id, transform)
	else:
		await rpcawaiter.send_rpc(1, set_transform.bind(node_id, transform))
		return
	return

@rpc("any_peer", "reliable")
func set_property(node_id: int, property_name: String, property_value: Variant) -> void:
	var _my_id: int = app_network_m._database.sessions_api[app_scene_m.active_session].get_unique_id()
	var _caller_id: int = multiplayer.get_remote_sender_id()

	if _my_id == 1:
		set_property_on_spawnable.rpc(node_id, property_name, property_value)
	else:
		await rpcawaiter.send_rpc(1, set_property.bind(node_id, property_name, property_value))
		return
	return

# TODO: How would large assets work?
@rpc("authority", "reliable")
func spawn_spawnable(p_type: String, p_name: String = "", p_path: String = "", parent_id: int = 0) -> int:
	var _spawnable_id = p_name if p_name != "" else str(_database_id)
	var _spawned_entity
	var parent_node = get_parent().get_node("root")

	# FIXME: This is silly! instance_root variable is in an invalid state here on clients?
	if parent_id > 1:
		var database_index = _database.find_custom(func(entry): return entry.id == parent_id)
		parent_node = _database[database_index].node

	_spawned_entity = _spawn_node(p_type, 1, parent_node, p_path)
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
	_entity_db.node.transform = transform
	return

@rpc("call_local", "authority", "reliable")
func set_property_on_spawnable(node_id: int, property_name: String, property_value: Variant):
	var _entity_db = get_by_id(node_id)

	_entity_db.node.set_indexed(property_name, property_value)
	return

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


@rpc("authority", "reliable")
func receive_database(database: Array, id: int) -> void:
	for spawnable in database:
		spawn_spawnable(spawnable.type, str(spawnable.id))
	network_m.rpc_id(1, "dev_request_sync")
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


func _spawn_node(node_type: String, node_owner: int, parent: Node = instance_root, model_path = "") -> Node:
	var _node: Node
	var _node_name = node_type
	var _node_schema = NSB.get_entry(_node_name)
	var _pretty_name: String

	# FIXME: Hack for importing skeletons?
	if _node_name == "Model" && model_path == "":
		_node = NSB.build("Node3D")
	else:
		_node = NSB.build(_node_name, model_path)

	# Add to database
	var _db_id = _add_to_database(_node, node_type, node_owner)

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
	_node.position = Vector3(0, 0, 0)

	# Add to scene tree
	parent.add_child(_node)
	return _node


func _add_to_database(node: Node, type: String, node_owner: int) -> int:
	var _db_entry = SPAWNABLE_TEMPLATE.duplicate()
	_db_entry.id = int(_database_id)
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
