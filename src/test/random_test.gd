# --- License
# File: /client/src/test/random_test.gd
# Project: OpenMinerva
# Created Date: 10 October 2026
# Copyright (c) 2026 OpenMinerva Contributors
# License: MIT License
# --- License
extends GdUnitTestSuite


func test_random_string_length() -> void:
	assert(Random.string(1).length() == 1)
	assert(Random.string(10).length() == 10)
	assert(Random.string(0).length() == 0)
	assert(Random.string(251532).length() == 251532)


func test_random_string_content() -> void:
	var _string_length: int = 200
	var _random_string: String = Random.string(_string_length)

	assert(_random_string.length() == _string_length)

	# TODO: Should I have a way to get the default dictionary used by Random?
	var valid_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

	for i in range(_random_string.length()):
		assert(valid_chars.contains(_random_string[i]))


func test_random_int_range() -> void:
	var _min_length: int = 10
	var _max_length: int = 2000

	# Does the int function work?
	assert(Random.int(5, 5) == 5)

	# Make sure that we are generating values that are inside of the range we specify.
	for i in range(1000):
		var val = Random.int(_min_length, _max_length)
		assert(val >= _min_length and val <= _max_length)


func test_random_float_range() -> void:
	var _min_length: float = 0.5
	var _max_length: float = 1.5

	# Does the int function work?
	assert(Random.float(5.5, 5.5) == 5.5)

	# Make sure that we are generating values that are inside of the range we specify.
	for i in range(1000):
		var val = Random.float(_min_length, _max_length)
		assert(val >= _min_length and val <= _max_length)
