# --- License
# File: /client/src/scenes/manager/scene/spawnable_manager_resources.gd
# Project: OpenMinerva
# Created Date: 10 October 2026
# Copyright (c) 2026 OpenMinerva Contributors
# License: MIT License
# --- License
extends Node

@onready var _registry = get_node("../Registry")
@onready var _sess_signalbus_m: Node = get_node("../../SignalBus")


# Create
@rpc("any_peer", "call_remote", "reliable")
func session_create_resource(resource_type: String, properties: Array, forced_resource_id: int = -1) -> int:
	# TODO: Permission check and handling.
	# TODO: Logging (https://github.com/OpenMinerva/client/issues/191)

	var _resource_id: int = _registry.get_active_id()

	if forced_resource_id != -1:
		_resource_id = forced_resource_id

	var _resource: Resource = await create(resource_type, properties, _resource_id)
	create.rpc(resource_type, properties, _resource_id)

	_sess_signalbus_m.resource_created.emit(_resource)

	if is_instance_valid(_resource) == false:
		return -1

	return int(_resource.get_name())


@rpc("authority", "reliable")
func create(resource_type: String, properties: Array, resource_id: int) -> Resource:
	var _resource: Resource = null

	_resource = ClassDB.instantiate(resource_type)

	# Set the resource properties
	for _prop in properties:
		if _prop.name == "resource_path":
			_resource.take_over_path(_prop.value)
			continue

		_resource.set_indexed(_prop.name, _prop.value)

	# Add the resource to the registry
	_registry.add_asset(_resource, int(resource_id))

	# Save the resource class as a metadata field to keep track of what it is.
	_resource.set_meta("class", resource_type)

	# Return the resource
	return _resource


# Destroy
# Change
# Property
@rpc("any_peer", "call_remote", "reliable")
func session_set_property(resource_id: int, property_name: String, property_value: Variant) -> void:
	# TODO: Permissions
	# TODO: Logging (https://github.com/OpenMinerva/client/issues/191)

	set_property.rpc(resource_id, property_name, property_value)

	if property_value is Resource:
		_registry.add_relation(resource_id, property_name, int(property_value.get_name()))

	return


@rpc("call_local", "authority", "reliable")
func set_property(resource_id: int, property_name: String, property_value: Variant) -> void:
	var _db_entry: Resource = _registry.get_asset(resource_id)

	if _db_entry == null:
		GlobalLogger.log("Could not locate resource id '%s'" % resource_id, Enum.LogLevel.WARNING)
		return

	_db_entry.set_indexed(property_name, property_value)
	_sess_signalbus_m.resource_metadata_change.emit(_db_entry)
	return
