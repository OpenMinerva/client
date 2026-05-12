# --- License
# File: /client/src/userinterface/dash/instance.gd
# Project: OpenMinerva
# Created Date: 27 March 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Control

var session_privacy: Enum.PrivacyLevel

@onready var network_m = get_tree().current_scene.get_node("NetworkManager")
@onready var instance_settings_root = get_node("VBoxContainer/HBoxContainer")
@onready var instance_name = instance_settings_root.get_node("VBoxContainer2/PanelContainer/MarginContainer/InstanceName/InstanceNameField")
@onready var instance_description = instance_settings_root.get_node("VBoxContainer2/PanelContainer2/MarginContainer/InstanceDescriptionContainer/InstanceDescription")
@onready var instance_max_users = instance_settings_root.get_node("VBoxContainer/InstanceSettings/MarginContainer/HBoxContainer/MaxConnectedUsers")
@onready var instance_privacy_container = instance_settings_root.get_node("VBoxContainer/InstancePrivacy/MarginContainer/InstancePrivacyContainer")
@onready var instance_privacy_public_btn = instance_privacy_container.get_node("Public")
@onready var instance_privacy_contacts_btn = instance_privacy_container.get_node("Contacts")
@onready var instance_privacy_friends_btn = instance_privacy_container.get_node("Friends")
@onready var instance_privacy_invite_btn = instance_privacy_container.get_node("InviteOnly")
@onready var save_changes_btn = get_node("VBoxContainer/HBoxContainer2/SaveChanges")


func _ready():
	instance_privacy_public_btn.pressed.connect(_update_instance_privacy_visual.bind(Enum.PrivacyLevel.PUBLIC))
	instance_privacy_contacts_btn.pressed.connect(_update_instance_privacy_visual.bind(Enum.PrivacyLevel.CONTACTS))
	instance_privacy_friends_btn.pressed.connect(_update_instance_privacy_visual.bind(Enum.PrivacyLevel.FRIENDS))
	instance_privacy_invite_btn.pressed.connect(_update_instance_privacy_visual.bind(Enum.PrivacyLevel.INVITE))

	save_changes_btn.pressed.connect(_handle_save_session_info)

	Events.connect("instance_updated", update_instance)

	_update_instance_privacy_visual(Enum.PrivacyLevel.INVITE)
	return


func update_instance(_instance: Dictionary) -> void:
	GlobalLogger.log("'%s' is not implemented." % get_stack()[0]["function"], Enum.LogLevel.WARNING)
	# TODO Session Permissions: Admins can change instance settings.
	# Publish changes to the session server.
	# Update running server
	return


func _update_instance_privacy_visual(level):
	if !is_multiplayer_authority():
		return

	GlobalLogger.log("Updating instance privacy.")

	session_privacy = level

	for node in instance_privacy_container.get_children():
		if node is Button:
			_privacy_button_disable(node)
	match level:
		Enum.PrivacyLevel.INVITE:
			_privacy_button_enable(instance_privacy_invite_btn)
		Enum.PrivacyLevel.PUBLIC:
			_privacy_button_enable(instance_privacy_public_btn)
		Enum.PrivacyLevel.CONTACTS:
			_privacy_button_enable(instance_privacy_contacts_btn)
		Enum.PrivacyLevel.FRIENDS:
			_privacy_button_enable(instance_privacy_friends_btn)

	return


func _privacy_button_disable(node) -> void:
	node.button_pressed = false
	node.custom_minimum_size = Vector2(0, 40)
	return


func _privacy_button_enable(node) -> void:
	node.button_pressed = true
	node.custom_minimum_size = Vector2(0, 50)
	return


func _handle_save_session_info() -> void:
	# TODO: Have this page know what instance it currently occupies.
	var _sessions = network_m.get_connected_sessions()

	# Get current session info settings from the dashboard.
	# TODO: Get the current session we are connected to.
	# Update the database to the new settings.
	var _current_session_settings = _get_server_settings()

	_sessions[0].set("name", _current_session_settings.name)
	_sessions[0].set("description", _current_session_settings.description)
	_sessions[0].set("max_connected_users", _current_session_settings.max_connected_users)
	_sessions[0].set("privacy", _current_session_settings.privacy)

	network_m.update_server(_sessions[0].id, _sessions[0])
	return


func _get_server_settings() -> Dictionary:
	return {
		"name": instance_name.text,
		"description": instance_description.text,
		"max_connected_users": int(instance_max_users.value),
		"privacy": session_privacy,
	}
