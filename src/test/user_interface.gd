extends GdUnitTestSuite

var _runner: GdUnitSceneRunner
var _dashboard: Node
var _dashboard_content_root: String = "MarginContainer/VBoxContainer/Content/Container"


func before_test() -> void:
	_runner = scene_runner("res://scenes/master.tscn")
	_dashboard = _runner.find_child("Dashboard")


func test_open_dashboard() -> void:
	_runner.simulate_key_pressed(KEY_ESCAPE)

	assert_bool(_dashboard.visible).is_true()
	return


func test_open_instance_page() -> void:
	Events.emit_signal("dash_switch_tab", "Instance")
	assert_bool(_dashboard.get_node(_dashboard_content_root + "/Instance").visible).is_true()
	return


func after_test() -> void:
	_runner = null
