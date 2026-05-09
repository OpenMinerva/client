# --- License
# File: /client/src/userinterface/dashv2/scripts/pages/instance.gd
# Project: OpenMinerva
# Created Date: 08 May 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends "res://userinterface/dashv2/scripts/pages/left_nav_container.gd"
@onready var scene_m = get_tree().current_scene.get_node("SceneManager")
@onready var network_m = get_tree().current_scene.get_node("NetworkManager")

@onready var privacy_settings: Control = get_node("HBox/Right/Hosting/ScrollContainer/VBoxContainer/VBoxContainer/Privacy/PanelContainer/MarginContainer/HBoxContainer/MarginContainer/OptionButton")
@onready var save_hosting_button = get_node("HBox/Right/Hosting/ScrollContainer/VBoxContainer/Save/Button")

var session_settings: Dictionary = {
	"privacy": 0
}

func _ready():
	super._ready()
	save_hosting_button.pressed.connect(_save_hosting_settings)
	return

func _save_hosting_settings() -> void:
	var _privacy_enum: Enum.PrivacyLevel = Enum.PrivacyLevel.INVITE

	session_settings.set("privacy", privacy_settings.selected)
	
	_post_update()
	return

func _post_update() -> void:
	var _sessions = network_m.get_connected_sessions()
	# var _current_session = scene_m.active_session

	_sessions[0].set("privacy", session_settings.privacy)

	network_m.update_server(_sessions[0].id, _sessions[0])

	return
