# --- License
# File: /client/src/scenes/managers/scene/spawnable_manager.gd
# Project: OpenMinerva
# Created Date: 18 May 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Node

enum SpawnableType {
	EMPTY = 0,
	BOX = 1,
	RIGIDBODY = 2,
	CAPSULE = 3,
	MODEL = 10,
}

const SPAWNABLE_TEMPLATE: Dictionary = {
	"type": 0,
	"spawner": 1,
	"has_physics": false,
	"physics_owner": 1,
	"node": "",
	"id": -1,
	"pretty_name": "ERROR",
}

var SpawnablePrettyName = {
	SpawnableType.EMPTY: "Node3D",
	SpawnableType.BOX: "BoxMesh",
	SpawnableType.RIGIDBODY: "RigidBody3D",
	SpawnableType.CAPSULE: "Capsule",
	SpawnableType.MODEL: "Model",
}
var SpawnableMesh = {
	SpawnableType.EMPTY: Node3D,
	SpawnableType.BOX: BoxMesh,
	SpawnableType.RIGIDBODY: RigidBody3D,
	SpawnableType.CAPSULE: CapsuleMesh,
	SpawnableType.MODEL: ArrayMesh,
}
var _dev_num_network_batches: int = 4
var _database_id = 10
var _database := []

@onready var network_m = get_node("../NetworkManager")
@onready var instance_root = get_parent().get_node("root")


# TODO: Handle physics for our items, and
func _physics_process(_delta):
	# NOTE: Networking is done in batches of 4. Meaning 25% of the scene is networked at any given frame.
	# There was no reason in me doing this, but I think I was trying to make it so that you do not have to network so many things in a given instant.
	# As far as I know there was not an existing problem I was trying to solve and I have no idea what I was thinking.
	# However, it's not breaking anything in the current instant so I will leave it in until it proves to be a problem or if I think of a better way of doing this.
	var current_batch = Engine.get_physics_frames() % _dev_num_network_batches

	if !is_multiplayer_authority():
		return
	for spawnable in _database:
		if spawnable.has_physics == false:
			continue
		if spawnable.node.sleeping == true:
			continue
		if spawnable.id % _dev_num_network_batches == current_batch:
			continue

		position_spawnable.rpc(spawnable.id, spawnable.node.position, spawnable.node.rotation)
	return


# FIXME: This is a test of syncing all positions of all spawnables. This probably is not going to be robust enough.
func sync_all() -> void:
	if !is_multiplayer_authority():
		return
	for spawnable in _database:
		if spawnable.has_physics == false:
			continue

		position_spawnable.rpc(spawnable.id, spawnable.node.position, spawnable.node.rotation)
	return


# TODO: Require actioning user
# TODO: Status response for spawn?
# TODO: How would large assets work?
@rpc("authority", "reliable")
func spawn_spawnable(p_type: SpawnableType, p_name: String = "", p_path = "", parent_node: Node = instance_root) -> Node:
	var _spawnable_id = p_name if p_name != "" else str(_database_id)
	var _spawned_entity

	match p_type:
		SpawnableType.CAPSULE:
			_spawned_entity = _spawn_node(SpawnableType.CAPSULE, 1, parent_node)
		SpawnableType.BOX:
			_spawned_entity = _spawn_node(SpawnableType.BOX, 1, parent_node)
		SpawnableType.RIGIDBODY:
			_spawned_entity = _spawn_node(SpawnableType.RIGIDBODY, 1, parent_node)
		SpawnableType.MODEL:
			_spawned_entity = _spawn_model(_spawnable_id, p_path)
		_:
			_spawned_entity = _spawn_node(SpawnableType.EMPTY, 1, parent_node)

	return _spawned_entity


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
	_database_id = id
	for spawnable in database:
		print("Client syncing '%s'" % spawnable.id)
		spawn_spawnable(spawnable.type, str(spawnable.id))
	network_m.rpc_id(1, "dev_request_sync")
	return


# TODO: Research "unreliable" connections. I think this is an applicable use case since a missed packet would probably be corrected in the next instant?
@rpc("authority", "unreliable")
func position_spawnable(id: int, p_position: Vector3, p_rotation: Vector3) -> void:
	# FIXME: Flimsy!
	var node = get_parent().get_node_or_null("root/%s" % id)

	if node:
		node.position = p_position
		node.rotation = p_rotation
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


# FIXME: Unused function
func _spawn_cube(p_name: String = "") -> RigidBody3D:
	# Create the physics body
	var rigid_body = RigidBody3D.new()

	# Create collision shape
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(0.5, 0.5, 0.5)
	collision_shape.shape = box_shape
	rigid_body.add_child(collision_shape)

	return rigid_body


func _spawn_model(p_name: String = "", p_path = "") -> RigidBody3D:
	# Create the physics body
	var rigid_body = RigidBody3D.new()

	# Create a MeshInstance
	var doc = GLTFDocument.new()
	var state = GLTFState.new()

	# TODO: Dynamic file path on machine?
	doc.append_from_file(p_path, state)
	var glb_scene: Node3D = doc.generate_scene(state)

	rigid_body.add_child(glb_scene)
	var colliders_to_add = _add_collisions_recursive(rigid_body)

	for collider in colliders_to_add:
		rigid_body.add_child(collider)
	# If we are a client, we are not simulating the physics
	if !is_multiplayer_authority():
		rigid_body.freeze = true

	# Add to database
	var _entry = SPAWNABLE_TEMPLATE.duplicate()
	_entry.physics_owner = 1
	_entry.spawner = 1 # TODO: The host is currently the only one that can spawn in anyways, but this will need to be changed.
	_entry.node = rigid_body
	_entry.id = int(p_name)
	_entry.type = SpawnableType.MODEL
	_database.append(_entry)

	# Set scene data
	rigid_body.name = str(p_name)
	rigid_body.physics_interpolation_mode = true
	rigid_body.position = Vector3(0, 2, -10)
	return rigid_body


func _spawn_node(node_type: SpawnableType, node_owner: int, parent: Node = instance_root) -> Node:
	var _node: Node

	# Build node
	match node_type:
		SpawnableType.EMPTY:
			_node = Node3D.new()
		SpawnableType.RIGIDBODY:
			_node = RigidBody3D.new()
		_:
			_node = MeshInstance3D.new()

	if "mesh" in _node:
		_node.mesh = SpawnableMesh[node_type].new()

	# Add to database
	var _db_id = _add_to_database(_node, node_type, node_owner)

	# RigidBody specific adjustments
	if node_type == Enum.SpawnableType.RIGIDBODY:
		_node.freeze = true
		# TODO: Tell database it has physics

	# Editor changes
	set_node_visible_to_inspector(_node)
	_node.name = str(_db_id)
	_node.set_meta("pretty_name", str(SpawnablePrettyName[node_type]))
	_node.position = Vector3(0, 0, 0)

	# Add to scene tree
	parent.add_child(_node)
	return _node


func _add_to_database(node: Node, type: SpawnableType, node_owner: int) -> int:
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
