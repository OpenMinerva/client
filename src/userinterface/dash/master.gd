# --- License
# File: /client/src/userinterface/dash/master.gd
# Project: OpenMinerva
# Created Date: 27 March 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Control

var dashboard_tabs = []
var dashboard_tab_names = []

@onready var dash_tab_master_container = get_node("MarginContainer/VBoxContainer/Master")
@onready var dash_nav_master_container = get_node("MarginContainer/VBoxContainer/NavBar/HBoxContainer")

func _ready():
	_build_page_list()

	Events.connect("dash_set_state", _handle_set_dash_state)
	Events.connect("dash_switch_tab", _handle_switch_tab)

	Events.emit_signal("dash_switch_tab", "Home")

func _build_page_list():
	for child in get_node("MarginContainer/VBoxContainer/Master").get_children():
		child.add_to_group("_dashboard_pages")
		dashboard_tab_names.append(child.name)

	for button in get_node("MarginContainer/VBoxContainer/NavBar/HBoxContainer").get_children():
		button.pressed.connect(_handle_switch_tab.bind(button.name))

func _handle_set_dash_state(is_open: bool) -> void:
	GlobalLogger.logs("Changing dashboard state: '%s'" % is_open)
	visible = is_open

func _handle_switch_tab(target_name: String) -> void:
	GlobalLogger.logs("Switching dashboard to page '%s'" % target_name)

	for dash_tab in dash_tab_master_container.get_children():
		dash_tab.visible = false

	for dash_nav_button in dash_nav_master_container.get_children():
		dash_nav_button.button_pressed = false

	if target_name not in dashboard_tab_names:
		GlobalLogger.logs("Tried to switch to an invalid dashboard page: '%s'" % target_name, 2)
		return

	dash_tab_master_container.get_node(target_name).visible = true

	if dash_nav_master_container.get_node(target_name):
		dash_nav_master_container.get_node(target_name).button_pressed = true

	return
