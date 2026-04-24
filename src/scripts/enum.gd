# --- License
# File: /client/src/scripts/enum.gd
# Project: OpenMinerva
# Created Date: 13 April 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Node

enum BaseLevel {
	DEBUG = 0,
	EMPTY = 1,
	GRID = 2,
}

enum PrivacyLevel {
	INVITE = 0,
	PUBLIC = 1,
	CONTACTS_PLUS = 2,
	CONTACTS = 3,
	FRIENDS_PLUS = 4,
	FRIENDS = 5
}

const Settings = {
	Graphics = {
		DisplayMode = {
			FULLSCREEN = 0,
			WINDOWED = 1,
			BORDERLESS = 2
		}
	}
}

enum LogLevel {
	DEBUG = 0,
	INFO = 1,
	WARNING = 2,
	ERROR = 3,
}
