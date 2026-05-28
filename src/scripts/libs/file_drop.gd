# --- License
# File: /client/src/scrips/libs/file_drop.gd
# Project: OpenMinerva
# Created Date: 26 May 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
class_name FileDropHandler
extends Node

@onready var scene_m = get_tree().current_scene.get_node("SceneManager")


func _ready():
	get_viewport().files_dropped.connect(on_drop)
	return


func on_drop(files) -> void:
	GlobalLogger.log("'%s' file(s) dropped onto the window." % len(files))

	for file in files:
		# TODO: check if file exists
		match file.get_extension():
			"glb":
				var model_path: String = ModelHandling.get_glb_assets(file)
				scene_m.get_master_scene(scene_m.active_session).get_node("SpawnableManager").spawn_spawnable(10, "", model_path)
				scene_m.get_master_scene(scene_m.active_session).get_node("SpawnableManager").spawn_spawnable.rpc(10, "", model_path)
			"gltf":
				scene_m.get_master_scene(scene_m.active_session).get_node("SpawnableManager").spawn_spawnable(10, "", file)
				scene_m.get_master_scene(scene_m.active_session).get_node("SpawnableManager").spawn_spawnable.rpc(10, "", file)
			"jpg", "png", "webp":
				return
			_:
				return

	return
