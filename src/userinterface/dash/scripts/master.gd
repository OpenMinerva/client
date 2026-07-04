# --- License
# File: /client/src/userinterface/dash/scripts/master.gd
# Project: OpenMinerva
# Created Date: 07 May 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Control

@onready var pages: Array[Node] = get_node("MarginContainer/VBoxContainer/Content/Container").get_children()


func _ready():
	Events.connect("dash_switch_tab", _handle_switch_tab)
	Events.connect("dash_set_state", _handle_dash_state)

	Events.emit_signal("dash_switch_tab", "Home")
	return


func _handle_switch_tab(tab_name):
	GlobalLogger.log("Changing dashboard tab to: '%s'" % tab_name)
	for _index in len(pages):
		var _target_node = pages[_index]

		if _target_node.name != tab_name:
			_target_node.visible = false
			continue

		_target_node.visible = true
	return


func _handle_dash_state(is_open: bool) -> void:
	GlobalLogger.log("Changing dashboard state: '%s'" % is_open)
	visible = is_open

	Events.emit_signal("app_mouse_captured", !is_open)

	if is_open == true:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event.is_action_pressed("escape"):
		if visible == false:
			Events.emit_signal("dash_set_state", true)
		else:
			Events.emit_signal("dash_set_state", false)
		get_viewport().set_input_as_handled()
