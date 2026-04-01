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

func _ready():
	return

func insert_world_into_session_listing(world_data: Dictionary) -> void:
	var _world = _template_world_listing.duplicate()

	var world_title = _world.get_node("PanelContainer/VBoxContainer/MarginContainer/Label")
	var world_thumbnail = _world.get_node("PanelContainer/VBoxContainer/MarginContainer2/AspectRatioContainer/TextureRect")

	world_title.text = world_data.get("session_name", "Unknown session name.")
	world_thumbnail.set_texture(load(world_data.get("session_thumbnail", "res://resources/icons/dummy16-9.webp")))

	_world_listing_grid.add_child(_world)
	GlobalLogger.logs("Added a session to the session list.")
	return
