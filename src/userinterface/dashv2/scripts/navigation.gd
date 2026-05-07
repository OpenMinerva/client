# --- License
# File: /client/src/userinterface/dashv2/scripts/navigation.gd
# Project: OpenMinerva
# Created Date: 07 May 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Control

@onready var navigation_nodes: Array[Node] = get_node("MarginContainer/HBoxContainer").get_children()

func _ready():
	Events.connect("dash_switch_tab", _handle_switch_tab)

	_setup_dashboard_navigation_bar()
	return

func _setup_dashboard_navigation_bar():
	for _index in len(navigation_nodes):
		var _target_node = navigation_nodes[_index]
		var _target_node_button = _target_node.get_node("Button")

		_target_node_button.pressed.connect(Events.emit_signal.bind("dash_switch_tab", _target_node.name))

	return

func _handle_switch_tab(tab_name):
	for _index in len(navigation_nodes):
		var _target_node = navigation_nodes[_index]
		var _target_node_button = _target_node.get_node("Button")

		if _target_node.name != tab_name:
			_target_node_button.button_pressed = false
			continue
		
		_target_node_button.button_pressed = true
		
	return
