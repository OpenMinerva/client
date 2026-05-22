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
	CUBE = 1,
	CONE = 2,
	CAPSULE = 3,
	MODEL = 10,
}

const SPAWNABLE_TEMPLATE: Dictionary = {
	"type": 0,
	"spawner": "1",
	"has_physics": true,
	"physics_owner": "1",
	"node": "",
	"id": 1,
	"pretty_name": "ERROR",
}

var _dev_num_network_batches: int = 4
var _id = 10
var _database := []

@onready var network_m = get_node("../NetworkManager")


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
func spawn_spawnable(p_type: int = 0, p_name: String = "") -> void:
	var _spawnable_id = p_name if p_name != "" else str(_id)
	var _spawned_entity

	match p_type:
		SpawnableType.CAPSULE:
			_spawned_entity = _spawn_capsule(_spawnable_id)
		SpawnableType.CUBE:
			_spawned_entity = _spawn_cube(_spawnable_id)
		_:
			return

	# Add to scene
	get_parent().get_node("root").add_child(_spawned_entity)

	# Update debug id
	if p_name == "":
		_id = _id + 1

	return


# TODO: require actioning user
@rpc("authority", "reliable")
func delete_spawnable() -> void:
	GlobalLogger.log("'%s' is not implemented." % get_stack()[0]["function"], Enum.LogLevel.WARNING)
	# TODO: Delete from database
	# TODO: Delete from scene
	return


@rpc("authority", "reliable")
func receive_database(database: Array, id: int) -> void:
	_id = id
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


func _spawn_cube(p_name: String = "") -> RigidBody3D:
	# Create the physics body
	var rigid_body = RigidBody3D.new()

	# Create a MeshInstance
	var mesh_instance = MeshInstance3D.new()
	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3(0.5, 0.5, 0.5)
	mesh_instance.mesh = cube_mesh
	rigid_body.add_child(mesh_instance)

	# Create collision shape
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(0.5, 0.5, 0.5)
	collision_shape.shape = box_shape
	rigid_body.add_child(collision_shape)

	# If we are a client, we are not simulating the physics
	if !is_multiplayer_authority():
		rigid_body.freeze = true

	# Add to database
	var _entry = SPAWNABLE_TEMPLATE.duplicate()
	_entry.physics_owner = 1 # TODO: Always the host, is this correct?
	_entry.spawner = 1 # TODO: The host is currently the only one that can spawn in anyways, but this will need to be changed.
	_entry.node = rigid_body
	_entry.id = int(p_name)
	_entry.type = SpawnableType.CUBE
	_database.append(_entry)

	# Set scene data
	rigid_body.name = str(p_name)
	rigid_body.physics_interpolation_mode = true
	rigid_body.position = Vector3(0, 5, -10)
	return rigid_body


func _spawn_capsule(p_name: String = "") -> RigidBody3D:
	# Create the physics body
	var rigid_body = RigidBody3D.new()

	# Create a MeshInstance
	var mesh_instance = MeshInstance3D.new()
	var mesh = CapsuleMesh.new()
	mesh.radius = 0.5
	mesh.height = 2
	mesh_instance.mesh = mesh
	rigid_body.add_child(mesh_instance)

	# Create collision shape
	var collision_shape = CollisionShape3D.new()
	var box_shape = CapsuleShape3D.new()
	mesh.radius = 0.5
	mesh.height = 2
	collision_shape.shape = box_shape
	rigid_body.add_child(collision_shape)

	# If we are a client, we are not simulating the physics
	if !is_multiplayer_authority():
		rigid_body.freeze = true

	# Add to database
	var _entry = SPAWNABLE_TEMPLATE.duplicate()
	_entry.physics_owner = 1 # TODO: Always the host, is this correct?
	_entry.spawner = 1 # TODO: The host is currently the only one that can spawn in anyways, but this will need to be changed.
	_entry.node = rigid_body
	_entry.id = int(p_name)
	_entry.type = SpawnableType.CAPSULE
	_database.append(_entry)

	# Set scene data
	rigid_body.name = str(p_name)
	rigid_body.physics_interpolation_mode = true
	rigid_body.position = Vector3(0, 5, -10)
	return rigid_body
