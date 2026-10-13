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

@onready var app_scene_m = get_tree().root.find_child("AppSceneManager", true, false)


func _ready():
	get_viewport().files_dropped.connect(on_drop)
	return


func on_drop(files) -> void:
	# TODO: Fix model importing. https://github.com/OpenMinerva/client/issues/230
	GlobalLogger.log("'%s' file(s) dropped onto the window." % len(files))
	GlobalLogger.log("Invalid call '%s'. This function is broken and will be fixed eventually." % get_stack()[0]["function"], Enum.LogLevel.WARNING)
	return
