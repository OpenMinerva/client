# --- License
# File: /client/src/userinterface/dash/scripts/pages/instance.gd
# Project: OpenMinerva
# Created Date: 08 May 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends "res://userinterface/dash/scripts/pages/left_nav_container.gd"

var session_settings: Dictionary = {
	"privacy": 0,
}

@onready var scene_m = get_tree().current_scene.get_node("SceneManager")
@onready var network_m = get_tree().current_scene.get_node("NetworkManager")
@onready var privacy_settings: Control = get_node("HBox/Right/Hosting/ScrollContainer/VBoxContainer/VBoxContainer/Privacy/PanelContainer/MarginContainer/HBoxContainer/MarginContainer/OptionButton")
@onready var save_hosting_button = get_node("HBox/Right/Hosting/ScrollContainer/VBoxContainer/Save/Button")


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
	var _current_session_id = scene_m.active_session

	var _current_session_db_index = _sessions.find_custom(func(sess): return sess.name == _current_session_id)
	var _current_session = _sessions[_current_session_db_index]

	_current_session.set("privacy", session_settings.privacy)

	network_m.update_server(_current_session_id, _current_session)

	return
