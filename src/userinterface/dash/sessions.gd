# --- License
# File: /client/src/userinterface/dash/sessions.gd
# Project: OpenMinerva
# Created Date: 27 March 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Control

@onready var _template_world_listing = get_node("Templates/WorldListing")
@onready var _world_listing_grid = get_node("HBoxContainer/VBoxContainer2/ScrollContainer/GridContainer")
@onready var network_m = get_tree().current_scene.get_node("NetworkManager")

# TODO: Keep track of what is different from the current live settings
# When something changes, show icon or indicator of a change.

func _ready():
	Events.dash_switch_tab.connect(_handle_page_opened)
	return

func _handle_page_opened(page_name: String) -> void:
	if page_name != "Sessions":
		return

	# TODO: Make a more robust active_account detection mechanism.
	if GlobalAccount.active_account == {}:
		return

	# TODO: Check if we need to authenticate, if so
	for _session_server in SettingsManager.get_session_servers():
		await SessionQuery.authenticate(_session_server.url)

	# Get a list of all sessions from our saved sessions_list
	var session_list = await SessionQuery.get_sessions()

	# Remove all entries in the list
	_remove_all_listings()

	# In our flat array, add all sessions to the view
	for session in session_list:
		insert_world_into_session_listing(session)
	return

func insert_world_into_session_listing(world_data: Dictionary) -> void:
	var _world = _template_world_listing.duplicate()

	var world_title = _world.get_node("PanelContainer/VBoxContainer/MarginContainer/Label")
	var world_thumbnail = _world.get_node("PanelContainer/VBoxContainer/MarginContainer2/AspectRatioContainer/TextureRect")

	world_title.text = world_data.get("sessionName", "Unknown session name.")
	world_thumbnail.set_texture(load(world_data.get("sessionThumbnail", "res://resources/icons/dummy16-9.webp")))

	_world_listing_grid.add_child(_world)

	# Buttons
	var _button = _world.get_node("Button")

	_button.pressed.connect(network_m.join_server.bind(world_data.url, world_data.port))

	GlobalLogger.logs("Added a session to the session list.")
	return

func _remove_all_listings() -> void:
	GlobalLogger.logs("Removed all listings from the session list.", Enum.LogLevel.INFO)

	for session_listing in _world_listing_grid.get_children():
		session_listing.queue_free()
	return
