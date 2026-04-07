# --- License
# File: /client/src/userinterface/dash/instance.gd
# Project: OpenMinerva
# Created Date: 27 March 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Control

enum PrivacyLevel {
	INVITE = 0,
	PUBLIC = 1,
	CONTACTS_PLUS = 2,
	CONTACTS = 3,
	FRIENDS_PLUS = 4,
	FRIENDS = 5
}

@onready var network_manager = get_tree().current_scene.get_node("NetworkManager")

@onready var instance_privacy_container = get_node("VBoxContainer/HBoxContainer/VBoxContainer/InstancePrivacy/MarginContainer/Instance Name")
@onready var instance_privacy_public_btn = instance_privacy_container.get_node("Public")
@onready var instance_privacy_contacts_btn = instance_privacy_container.get_node("Contacts")
@onready var instance_privacy_friends_btn = instance_privacy_container.get_node("Friends")
@onready var instance_privacy_invite_btn = instance_privacy_container.get_node("InviteOnly")

@onready var save_changes_btn = get_node("VBoxContainer/HBoxContainer2/SaveChanges")

func _ready():
	instance_privacy_public_btn.pressed.connect(_update_instance_privacy.bind(PrivacyLevel.PUBLIC))
	instance_privacy_contacts_btn.pressed.connect(_update_instance_privacy.bind(PrivacyLevel.CONTACTS))
	instance_privacy_friends_btn.pressed.connect(_update_instance_privacy.bind(PrivacyLevel.FRIENDS))
	instance_privacy_invite_btn.pressed.connect(_update_instance_privacy.bind(PrivacyLevel.INVITE))

	# save_changes_btn.pressed.connect()

	Events.connect("instance_updated", update_instance)

	_update_instance_privacy(PrivacyLevel.INVITE)
	return

func _update_instance_privacy(level):
	if !is_multiplayer_authority():
		return

	GlobalLogger.logs("Updating instance privacy.")

	for node in instance_privacy_container.get_children():
		if node is Button:
			_privacy_button_disable(node)
	match level:
		PrivacyLevel.INVITE:
			_privacy_button_enable(instance_privacy_invite_btn)
		PrivacyLevel.PUBLIC:
			_privacy_button_enable(instance_privacy_public_btn)
		PrivacyLevel.CONTACTS:
			_privacy_button_enable(instance_privacy_contacts_btn)
		PrivacyLevel.FRIENDS:
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

func update_instance(instance: Dictionary) -> void:
	# TODO Session Permissions: Admins can change instance settings. 
	if !is_multiplayer_authority():
		return

	GlobalLogger.logs("Updating session.")
	# Publish changes to the session server.
	# Update running server 
	return
