extends Control

var ui = preload("res:///userinterface/ui_helper.gd").new()

func _ready():
	await ui.init(self )
	ui.add_event_listeners_to_nav_buttons()
	ui.display_account_on_home()
	return
