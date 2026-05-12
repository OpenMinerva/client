# --- License
# File: /client/src/userinterface/dashv2/scripts/pages/sessions.gd
# Project: OpenMinerva
# Created Date: 08 May 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Control

@onready var template_world_listing: PackedScene = preload("res://userinterface/dashv2/partials/session_listing.tscn")
@onready var world_listing_grid: GridContainer = get_node("HBox/Right/VBoxContainer/ScrollContainer/GridContainer")
@onready var tag_nodes: Array[Node] = get_node("HBox/Left").get_children()
@onready var network_m = get_tree().current_scene.get_node("NetworkManager")


func _ready():
	Events.connect("dash_switch_tab", _handle_switch_tab)

	_setup_navigation()
	return


func _handle_switch_tab(tab_name) -> void:
	if tab_name != "Sessions":
		return

	GlobalLogger.log("Triggered in Sessions!")
	# TODO: Make a more robust active_account detection mechanism.
	if GlobalAccount.active_account == { }:
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
		_insert_world_into_session_listing(session)
	return


func _remove_all_listings() -> void:
	for _session_listing in world_listing_grid.get_children():
		_session_listing.queue_free()

	GlobalLogger.log("Removed all listings from the session list.")
	return


func _insert_world_into_session_listing(session: Dictionary) -> void:
	var _world = template_world_listing.instantiate()
	var _world_title = _world.get_node("Button/MarginContainer/VBoxContainer/Label")
	var _world_thumbnail = _world.get_node("Button/MarginContainer/VBoxContainer/AspectRatioContainer/TextureRect")
	var _button = _world.get_node("Button")

	_world_title.text = session.get("sessionName", "Unknown session name.")
	_world_thumbnail.set_texture(load(session.get("sessionThumbnail", "res://resources/icons/1280x720.webp")))

	_button.pressed.connect(network_m.join_server.bind(session.url, session.port))

	world_listing_grid.add_child(_world)
	return


func _setup_navigation():
	GlobalLogger.log("Setting up navigation for '%s'" % name)
	for index in len(tag_nodes):
		var _target_node = tag_nodes[index]
		var _target_node_button = _target_node.get_node("Button")

		_target_node_button.pressed.connect(_handle_filter_selection.bind(_target_node.name))

	return


func _handle_filter_selection(tab_name):
	for _index in len(tag_nodes):
		var _target_node = tag_nodes[_index]
		var _target_node_button = _target_node.get_node("Button")

		if _target_node.name != tab_name:
			_target_node_button.button_pressed = false
			continue

		# NOTE: By the time we have the filter button clicked, it is registered as not pressed.
		# At this point, if our target node is registered as disabled, it is actually enabled.
		# The desired result is to disable the selected filter button.
		if _target_node_button.button_pressed == false:
			GlobalLogger.log("Disable filtering results '%s' in '%s'" % [tab_name, name])
			_target_node_button.button_pressed = false
			continue

		GlobalLogger.log("Filtering results to '%s' in '%s'" % [tab_name, name])
		_target_node_button.button_pressed = true
		continue

	return
