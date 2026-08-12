# --- License
# File: /client/src/scripts/utils/state_manager.gd
# Project: OpenMinerva
# Created Date: 10 July 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Node

# Client Editor Mode
var _cem: bool = false
var _cem_camera: bool = false
var _cem_camera_rotating: bool = false
# Dashboard
var _dashboard: bool = false
# Other
var _escaped: bool = false


func _ready() -> void:
	Events.cem_set_state.connect(func(state): _cem = state)
	Events.dash_set_state.connect(func(state): _dashboard = state)
	Events.cem_camera_state.connect(func(state): _cem_camera = state)
	Events.cem_camera_rotating.connect(func(state): _cem_camera_rotating = state)
	Events.escape_mouse.connect(func(state): _escaped = state)
	return


# Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
func update_mouse_state() -> void:
	if _escaped == true:
		# User wants the mouse.
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return

	if _dashboard == true:
		# Dashboard always needs input.
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return

	if _cem_camera_rotating == true:
		# Rotating the CEM camera requires the mouse.
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		return

	if _cem_camera == true && _cem == true:
		# CEM_Camera requires a free mouse as well.
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return

	if _cem_camera == true && _cem == false:
		# CEM_Camera but no inspector is just a free cam.
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		return

	if _cem == true:
		# Inspector requires a mouse.
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	return


func is_mouse_captured() -> bool:
	return Input.get_mouse_mode()
