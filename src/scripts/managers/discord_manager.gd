# --- License
# File: /client/src/scripts/managers/discord_manager.gd
# Project: OpenMinerva
# Created Date: 13 June 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
class_name Discord

static var _current_players: int = 0
static var _max_players: int = 0
static var _first_run: bool = true

static func _init() -> void:
	DiscordRPC.app_id = 1526274978486554684
	DiscordRPC.large_image_text = "OpenMinerva"
	DiscordRPC.large_image = "om-logo"

	set_playercount(-1, -1)
	set_world("Private")

	DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system())

	DiscordRPC.refresh()
	return

static func set_playercount(current: int = -1, _max_count: int = -1) -> void:
	_current_players = current
	_max_players = _max_count
	DiscordRPC.state = "%s / %s" % [_current_players, _max_players]
	DiscordRPC.refresh()
	return

static func set_world(privacy: String = "Private", session_name: String = "Unnamed") -> void:
	if privacy == "Public":
		DiscordRPC.small_image_text = "Public world"
		DiscordRPC.small_image = "public-1"
		DiscordRPC.details = "In '%s'" % session_name
	elif privacy == "Private":
		DiscordRPC.small_image_text = "Private world"
		DiscordRPC.small_image = "private-1"
		DiscordRPC.details = "In a private world"

	DiscordRPC.refresh()
	return

static func set_enabled(enabled: bool = true) -> void:
	if enabled == true:
		GlobalLogger.log("Enabling Discord rich presence.")

		if _first_run == false:
			# We never cleared it to begin with.
			DiscordRPC.unclear()

		_first_run = false
		_init()
	else:
		GlobalLogger.log("Disabling Discord rich presence.")
		DiscordRPC.clear()
	return
