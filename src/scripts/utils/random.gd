# --- License
# File: /client/src/scripts/utils/random.gd
# Project: OpenMinerva
# Created Date: 13 January 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

class_name Random

static var char_bytes := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".to_ascii_buffer()
static var rng = RandomNumberGenerator.new()

static func string(length: int = 6) -> String:
	# New array.
	var bytes := PackedByteArray()

	# Reside the array, avoids performance of increasing the size of the array.
	bytes.resize(length)

	for i in length:
		# Get a random character from the char_bytes array.
		bytes[i] = char_bytes[randi() % char_bytes.size()]

	# Returns the PackedByteArray as a string.
	return bytes.get_string_from_ascii()

static func int(min: int = 0, max: int = 10) -> int:
	return rng.randi_range(min, max)

static func float(min: int = 0, max: int = 10) -> int:
	return rng.randf_range(min, max)
