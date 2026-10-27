# --- License
# File: /client/src/scripts/managers/settings.gd
# Project: OpenMinerva
# Created Date: 16 April 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Node

const _templates = {
	# The full settings file that is saved and stored.
	"settings_file": {
		"graphics": {
			"display_mode": Enum.Settings.Graphics.DisplayMode.FULLSCREEN,
		},
		"config": {
			"session_servers": [],
		},
	},

	# Small templates that are duplicated and used to
	"session_server": {
		"name": "",
		"url": "",
		"date_added": int(0),
	},
}

var _settings = { }


func _ready():
	_load_settings()


# Settings versioning
# Settings file upgrade
# Get setting
func get_session_servers() -> Array:
	var return_arr = []

	return_arr = _settings.get("config", { }).get("session_servers", [])

	return return_arr


func add_session_server(server_url: String) -> bool:
	var _date_added = Time.get_unix_time_from_system()

	_settings.config.session_servers.append({ "url": server_url, "date_added": _date_added })
	_save_settings()
	Events.emit_signal("dash_settings_updated")
	return true


func remove_session_server(url: String) -> bool:
	var _index = -1
	for i in range(_settings.config.session_servers.size()):
		if _settings.config.session_servers[i]["url"] == url:
			_index = i
			break

	if _index != -1:
		_settings.config.session_servers.remove_at(_index)

	_save_settings()
	Events.emit_signal("dash_settings_updated")
	return false


func _save_settings():
	var _file = FileManager.open("user://settings/current.json", FileAccess.WRITE)
	var _settings_string: String = JSON.stringify(_settings)
	_file.store_string(_settings_string)
	_file.close()
	GlobalLogger.log("Saved settings file.", Enum.LogLevel.INFO)
	return


func _load_settings() -> void:
	var _settings_exist: bool = FileManager.file_exists("user://settings/current.json")
	if _settings_exist == true:
		var _file = FileManager.open("user://settings/current.json")
		var _content = _file.get_as_text()
		var _parsed = JSON.parse_string(_content)
		_settings = _parsed
		GlobalLogger.log("Settings have been loaded.", Enum.LogLevel.INFO)
		return

	# TODO: Check if backup settings exist.
	GlobalLogger.log("Settings file does not exist, creating new settings file.", Enum.LogLevel.INFO)
	FileManager.create_file("user://settings/current.json")
	_settings = _templates.settings_file
	_save_settings()
	GlobalLogger.log("Blank settings have been loaded.", Enum.LogLevel.INFO)
	return
