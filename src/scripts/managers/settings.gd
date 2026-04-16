# --- License
# File: /client/src/scripts/managers/settings.gd
# Project: OpenMinerva
# Created Date: 16 April 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Node

var _settings = {}

func _ready():
	_load_settings()

# Settings versioning
# Settings file upgrade

# Get setting
func get_session_servers() -> Array:
	var return_arr = []

	return_arr = _settings.get("config", {}).get("session_servers", [])

	return return_arr

func add_session_server(session_server: Dictionary) -> bool:
	var _name = session_server.get("name", "")
	var _url = session_server.get("url", "")
	var _date_added = Time.get_unix_time_from_system()

	_settings.config.session_servers.append({"name": _name, "url": _url, "date_added": _date_added})
	_save_settings()
	return true

func _save_settings():
	var _file = FileAccess.open("user://settings/current.json", FileAccess.WRITE)
	var _settings_string: String = JSON.stringify(_settings)
	_file.store_string(_settings_string)
	_file.close()
	GlobalLogger.logs("Saved settings file.", 1)
	return

func _load_settings() -> void:
	var _settings_exist: bool = FileAccess.file_exists("user://settings/current.json")
	if _settings_exist:
		var _file = FileAccess.open("user://settings/current.json", FileAccess.READ)
		var _content = _file.get_as_text()
		var _parsed = JSON.parse_string(_content)
		_settings = _parsed
		GlobalLogger.logs("Settings have been loaded.", 1)
		return

	# TODO: Check if backup settings exist.
	GlobalLogger.logs("Settings file does not exist, creating new settings file.", 1)
	FileManager.create_file("user://settings/", "current.json")
	_settings = _templates.settings_file
	_save_settings()
	GlobalLogger.logs("Blank settings have been loaded.", 1)
	return

const _templates = {
	# The full settings file that is saved and stored.
	"settings_file": {
		"graphics": {
			"display_mode": Enum.Settings.Graphics.DisplayMode.FULLSCREEN
		},
		"config": {
			"session_servers": []
		}
	},

	# Small templates that are duplicated and used to
	"session_server": {
		"name": "",
		"url": "",
		"date_added": int(0)
	}
}
