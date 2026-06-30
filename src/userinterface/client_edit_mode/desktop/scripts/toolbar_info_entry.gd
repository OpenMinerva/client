# --- License
# File: /client/src/userinterface/client_edit_mode/desktop/scripts/toolbar_info_entry.gd
# Project: OpenMinerva
# Created Date: 30 June 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Node

@export var icon: Texture2D
@export var label: String = "0"

@onready var icon_node = get_node("MarginContainer/HBoxContainer/AspectRatioContainer/TextureRect")
@onready var label_node = get_node("MarginContainer/HBoxContainer/Label")

func _ready() -> void:
	if icon:
		icon_node.texture = icon

	label_node.text = label
