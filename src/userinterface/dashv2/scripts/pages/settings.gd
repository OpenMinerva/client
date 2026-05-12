# --- License
# File: /client/src/userinterface/dashv2/scripts/pages/settings.gd
# Project: OpenMinerva
# Created Date: 07 May 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends "res://userinterface/dashv2/scripts/pages/left_nav_container.gd"

@onready var _session_server_list_container = get_node("HBox/Right/Config/InputDropdown/VBoxContainer/MarginContainer2/PanelContainer/VBoxContainer/VBoxContainer")
@onready var _templates_session_server_listing = preload("res://userinterface/dashv2/partials/removable_string_listing.tscn")
@onready var _add_session_server_button = get_node("HBox/Right/Config/InputDropdown/VBoxContainer/MarginContainer2/PanelContainer/VBoxContainer/InputString/PanelContainer/MarginContainer/HBoxContainer/AspectRatioContainer/MarginContainer/Button")


func _ready():
	super._ready()

	Events.dash_switch_tab.connect(_handle_page_opened)
	Events.dash_settings_updated.connect(_load_session_servers)
	_add_session_server_button.pressed.connect(_add_session_server)

	return


func _handle_page_opened(page_name) -> void:
	if page_name != "Settings":
		return
	_load_session_servers()
	return


func _load_session_servers() -> void:
	GlobalLogger.log("Loading session servers.")
	const _LABEL_PATH = "MarginContainer/HBoxContainer/Label"
	const _REMOVE_BUTTON_PATH = "MarginContainer/HBoxContainer/AspectRatioContainer/Button"

	var _servers = SettingsManager.get_session_servers()
	for _existing_listing in _session_server_list_container.get_children():
		_existing_listing.queue_free()

	for server in _servers:
		var _template = _templates_session_server_listing.instantiate()
		_template.get_node(_LABEL_PATH).text = server.url
		_template.get_node(_REMOVE_BUTTON_PATH).pressed.connect(_remove_session_server.bind(server.url))
		_session_server_list_container.add_child(_template)
	return


func _add_session_server() -> void:
	var _session_server_input_field = get_node("HBox/Right/Config/InputDropdown/VBoxContainer/MarginContainer2/PanelContainer/VBoxContainer/InputString/PanelContainer/MarginContainer/HBoxContainer/MarginContainer/LineEdit")
	SettingsManager.add_session_server(_session_server_input_field.text)
	_session_server_input_field.text = ""
	return


func _remove_session_server(server_url: String) -> void:
	SettingsManager.remove_session_server(server_url)
	return
