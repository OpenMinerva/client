# --- License
# File: /client/src/userinterface/dash/scripts/new_world_dialog.gd
# Project: OpenMinerva
# Created Date: 06 August 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends "res://userinterface/client_edit_mode/desktop/scripts/movable_window.gd"

@export var target_scene_path: String = ""
@export var base: Enum.BaseLevel = Enum.BaseLevel.GRID

@onready var network_m = get_tree().current_scene.get_node("NetworkManager")
@onready var scene_m = get_tree().current_scene.get_node("SceneManager")
@onready var dashboard = get_tree().current_scene.get_node("Dashboard")
@onready var _create_world_button: Control = get_node("%Create")
@onready var _base_val_ui: Control = get_node("%BaseVal")
@onready var _world_load_dir_ui: Control = get_node("%WorldLoadDir")
@onready var _world_load_dir_val_ui: Control = get_node("%WorldLoadDirVal")


func _ready() -> void:
	super._ready()
	closed.connect(func(): close_window(false))
	_create_world_button.clicked.connect(start_world)
	_base_val_ui.item_selected.connect(func(_index): update_ui())
	update_ui()
	return


func show_window() -> void:
	update_ui()
	super._open()
	visible = true
	return


func close_window(call_super: bool = true) -> void:
	if call_super == true:
		super._close()

	_base_val_ui.selected = Enum.BaseLevel.GRID
	base = Enum.BaseLevel.GRID
	return


func update_ui() -> void:
	base = _base_val_ui.selected

	_world_load_dir_val_ui.visible = base == Enum.BaseLevel.CUSTOM
	_world_load_dir_ui.visible = base == Enum.BaseLevel.CUSTOM
	return


func start_world() -> void:
	var _world_name: String = dashboard.get_node("%WorldNameVal").text
	var _world_base: Enum.BaseLevel = dashboard.get_node("%BaseVal").selected
	var _world_privacy: Enum.PrivacyLevel = dashboard.get_node("%PrivacyVal").selected
	var _world_load_dir: String = dashboard.get_node("%WorldLoadDirVal").text

	network_m.start_server(0, _world_base, _world_load_dir)

	# HACK: For some reason, the active session does not get updated when I expect it to. This will force the active session to switch to the newly created session.
	var _sessions: Array = network_m.get_connected_sessions()
	scene_m.set_active_session(_sessions.back().name)

	close_window()
	return
