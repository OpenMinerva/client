# --- License
# File: /client/src/scenes/managers/scene/spawnable_manager.gd
# Project: OpenMinerva
# Created Date: 18 May 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Node

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
		if spawnable.type != NSB.get_node_index("RigidBody3D"):
			continue
		if spawnable.node.sleeping == true:
			continue
		if spawnable.id % _spawnable_network_batches == current_batch:
			continue

		position_spawnable.rpc(spawnable.id, spawnable.node.position, spawnable.node.rotation)
	return


# FIXME: This is a test of syncing all positions of all spawnables. This probably is not going to be robust enough.
func sync_all() -> void:
	if !is_multiplayer_authority():
		return
	for spawnable in _database:
		position_spawnable.rpc(spawnable.id, spawnable.node.position, spawnable.node.rotation)
	return


@rpc("any_peer", "reliable")
func create(node_type: int, node_parent: int, model_path: String = "") -> Variant:
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
		var entity = await rpcawaiter.send_rpc(1, create.bind(node_type, node_parent, model_path))
		var database_index: int = _database.find_custom(func(entry): return entry.id == entity)
		return _database[database_index].node


# TODO: Require actioning user
# TODO: Status response for spawn?
# TODO: How would large assets work?
@rpc("authority", "reliable")
func spawn_spawnable(p_type: int, p_name: String = "", p_path: String = "", parent_id: int = 0) -> int:
	var _spawnable_id = p_name if p_name != "" else str(_database_id)
	var _spawned_entity
	var parent_node = get_parent().get_node("root")

	# FIXME: This is silly! instance_root variable is in an invalid state here on clients?
	if parent_id > 1:
		var database_index = _database.find_custom(func(entry): return entry.id == parent_id)
		parent_node = _database[database_index].node

	_spawned_entity = _spawn_node(p_type, 1, parent_node, p_path)

	return int(_spawned_entity.name)


# TODO: require actioning user
@rpc("authority", "reliable")
func delete_spawnable(node_name: String) -> void:
	GlobalLogger.log("Deleting node '%s'." % node_name)
	var _entry_index = _database.find_custom(func(item): return item.id == int(node_name))
	if _entry_index == -1:
		# This should never happen! The node can never be removed from the scene tree then.
		GlobalLogger.log("'%s' could not be located in the scene tree.", Enum.LogLevel.ERROR)

	var _entry = _database[_entry_index]
	# TODO: Remove all Gizmos relating to the node first

	_entry.node.queue_free()
	_database.remove_at(_entry_index)
	return


@rpc("authority", "reliable")
func receive_database(database: Array, id: int) -> void:
	for spawnable in database:
		spawn_spawnable(spawnable.type, str(spawnable.id))
	network_m.rpc_id(1, "dev_request_sync")
	return


# TODO: RESEARCH "unreliable" connections. I think this is an applicable use case since a missed packet would probably be corrected in the next instant?
# TODO: SECURITY Make this so that the client can move the item on their end, but the host must move it for everyone else.
@rpc("any_peer", "unreliable")
func position_spawnable(id: int, p_position: Vector3, p_rotation: Vector3, p_scale: Vector3) -> void:
	var database_entry = _database.find_custom(func(entry): return entry.id == id)
	var node = _database[database_entry].node
	if node:
		node.position = p_position
		node.rotation = p_rotation
		node.scale = p_scale
	return


func set_node_visible_to_inspector(node: Node) -> void:
	var nodes = get_all_node_children(node)
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


func _spawn_node(node_type: int, node_owner: int, parent: Node = instance_root, model_path = "") -> Node:
	var _node: Node
	var _node_name = NSB.get_valid()[node_type]
	var _schema_index = NSB.get_node_index(_node_name)
	var _node_schema = NSB.get_formatted(_schema_index)
	_node = NSB._build_node(_node_name, model_path)

	# Add to database
	var _db_id = _add_to_database(_node, node_type, node_owner)

	# Editor changes
	set_node_visible_to_inspector(_node)
	_node.name = str(_db_id)
	_node.set_meta("pretty_name", str(_node_schema.pretty_name))
	_node.position = Vector3(0, 0, 0)

	# Add to scene tree
	parent.add_child(_node)
	return _node


func _add_to_database(node: Node, type: int, node_owner: int) -> int:
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
