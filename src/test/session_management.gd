# --- License
# File: /client/src/test/session_management.gd
# Project: OpenMinerva
# Created Date: 09 October 2026
# Copyright (c) 2026 OpenMinerva Contributors
# License: MIT License
# --- License
extends GdUnitTestSuite

var _runner: GdUnitSceneRunner


func before_test() -> void:
	_runner = scene_runner("res://scenes/base.tscn")
	# TODO: Can I run multiple "instances" using multiple scene_runners?


func after_test() -> void:
	_runner = null


func test_start_session(_do_skip: bool = true) -> void:
	return


func test_stop_sesison(_do_skip: bool = true) -> void:
	return


func test_join_session(_do_skip: bool = true) -> void:
	return


func test_kick_from_session(_do_skip: bool = true) -> void:
	return


func test_ban_from_session(_do_skip: bool = true) -> void:
	return
