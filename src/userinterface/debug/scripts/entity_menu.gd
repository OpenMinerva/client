# --- License
# File: /client/src/userinterface/debug/scripts/entity_menu.gd
# Project: OpenMinerva
# Created Date: 21 May 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Control

@onready var button_container = $"HBoxContainer/MarginContainer/PanelContainer/MarginContainer/VBoxContainer"
@onready var scene_m = get_tree().current_scene.get_node("SceneManager")


func _ready() -> void:
	Events.debug_entity_set_state.connect(_toggle_state)
	button_container.get_node("Cube").pressed.connect(_spawn_cube)
	button_container.get_node("Capsule").pressed.connect(_spawn_capsule)
	return


func _toggle_state() -> void:
	visible = !visible
	return


func _spawn_cube() -> void:
	GlobalLogger.log("Spawning Cube!")
	# TODO: Create spawning request handler.
	scene_m.get_master_scene(scene_m.active_session).get_node("SpawnableManager").spawn_spawnable(1)
	scene_m.get_master_scene(scene_m.active_session).get_node("SpawnableManager").spawn_spawnable.rpc(1)
	get_viewport().set_input_as_handled()
	return


func _spawn_capsule() -> void:
	GlobalLogger.log("Spawning Capsule!")
	# TODO: Create spawning request handler.
	scene_m.get_master_scene(scene_m.active_session).get_node("SpawnableManager").spawn_spawnable(3)
	scene_m.get_master_scene(scene_m.active_session).get_node("SpawnableManager").spawn_spawnable.rpc(3)
	get_viewport().set_input_as_handled()
	return
