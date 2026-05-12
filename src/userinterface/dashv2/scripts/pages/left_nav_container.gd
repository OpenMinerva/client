# --- License
# File: /client/src/userinterface/dashv2/scripts/pages/left_nav_container.gd
# Project: OpenMinerva
# Created Date: 07 May 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Control

@onready var navigation_nodes: Array[Node] = get_node("HBox/Left").get_children()
@onready var pages: Array[Node] = get_node("HBox/Right").get_children()


func _ready():
	var _first_navigation_node_name: String = navigation_nodes[0].name

	_setup_navigation()
	_handle_switch_tab(_first_navigation_node_name)
	return


func _setup_navigation():
	GlobalLogger.log("Setting up navigation for '%s'" % name)
	for index in len(navigation_nodes):
		var _target_node = navigation_nodes[index]
		var _target_node_button = _target_node.get_node("Button")

		_target_node_button.pressed.connect(_handle_switch_tab.bind(_target_node.name))

	return


func _handle_switch_tab(tab_name):
	GlobalLogger.log("Changing to page '%s' in '%s'" % [tab_name, name])

	for _index in len(navigation_nodes):
		var _target_node = navigation_nodes[_index]
		var _target_node_button = _target_node.get_node("Button")

		if _target_node.name != tab_name:
			_target_node_button.button_pressed = false
			continue

		_target_node_button.button_pressed = true

	for _index in len(pages):
		var _target_node = pages[_index]

		if _target_node.name != tab_name:
			_target_node.visible = false
			continue

		_target_node.visible = true
	return
