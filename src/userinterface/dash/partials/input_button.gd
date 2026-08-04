# --- License
# File: /client/src/userinterface/dash/partials/input_button.gd
# Project: OpenMinerva
# Created Date: 3 August 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Control

signal clicked

@export var display_text: String = "Default Text"
@export var button_label: String = "Button"
@export var button_icon: Texture2D

@onready var button = get_node("PanelContainer/MarginContainer/HBoxContainer/MarginContainer/GenericButton")
@onready var label_node = $PanelContainer/MarginContainer/HBoxContainer/Label


func _ready():
	label_node.text = display_text
	button.set_label(button_label)
	button.set_icon(button_icon)
	button.clicked.connect(func(): clicked.emit())
