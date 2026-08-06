# --- License
# File: /client/src/scripts/enum.gd
# Project: OpenMinerva
# Created Date: 13 April 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
class_name Enum

enum AccountLoginType {
	NULL = 0,
	OAUTH = 1,
	OAUTH_DEVICE = 2,
	PASSWORD = 10,
}
enum BaseLevel {
	DEBUG = 0,
	HOME = 1,
	EMPTY = 2,
	GRID = 3,
}
enum PrivacyLevel {
	INVITE = 0,
	FRIENDS = 1,
	FRIENDS_PLUS = 2,
	CONTACTS = 3,
	CONTACTS_PLUS = 4,
	PUBLIC = 5,
}
enum LogLevel {
	DEBUG = 0,
	INFO = 1,
	WARNING = 2,
	ERROR = 3,
}
enum SpawnableType {
	ITEM = 0,
	WORLD = 1,
}

const Settings = {
	Graphics = {
		DisplayMode = {
			FULLSCREEN = 0,
			WINDOWED = 1,
			BORDERLESS = 2,
		},
	},
}
