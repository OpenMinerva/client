# --- License
# File: /client/src/test/user_interface.gd
# Project: OpenMinerva
# Created Date: 16 September 2026
# Copyright (c) 2026 OpenMinerva Contributors
# License: MIT License
# --- License
extends GdUnitTestSuite

var _runner: GdUnitSceneRunner
var _dashboard: Node
var _dashboard_content_root: String = "MarginContainer/VBoxContainer/Content/Container"
var _dashboard_pages: Array[Node]


func before_test() -> void:
	_runner = scene_runner("res://scenes/master.tscn")
	_dashboard = _runner.find_child("Dashboard")
	_dashboard_pages = _dashboard.get_node(_dashboard_content_root).get_children()


func test_open_dashboard() -> void:
	_runner.simulate_key_pressed(KEY_ESCAPE)

	assert_bool(_dashboard.visible).is_true()
	return


func test_page_navigation() -> void:
	for _page in _dashboard_pages:
		Events.emit_signal("dash_switch_tab", _page.name)
		var _open_pages: Array[String] = _get_open_pages()

		assert(_open_pages.size() == 1)
		assert(_open_pages[0] == _page.name)
	return


func after_test() -> void:
	_runner = null


func _get_open_pages() -> Array[String]:
	var _pages: Array[String] = []

	for _child in _dashboard_pages:
		if _child.visible == true:
			_pages.append(_child.name)

	return _pages
